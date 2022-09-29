/*
 * Machine Code Limited ("COMPANY") Confidential and Proprietary
 * Unpublished Copyright (C) 2017 Machine Code Limited, All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * COMPANY. The intellectual and technical concepts contained herein are
 * proprietary to COMPANY and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from COMPANY.
 * Access to the source code contained herein is hereby forbidden to anyone
 * except current COMPANY employees, managers or contractors who have executed
 * Confidentiality and Non-disclosure agreements explicitly covering such
 * access.
 *
 * The copyright notice above does not evidence any actual or intended
 * publication or disclosure of this source code, which includes information
 * that is confidential and/or proprietary, and is a trade secret, of COMPANY.
 * ANY REPRODUCTION, MODIFICATION, DISTRIBUTION, PUBLIC PERFORMANCE, OR PUBLIC
 * DISPLAY OF OR THROUGH USE OF THIS SOURCE CODE WITHOUT THE EXPRESS WRITTEN
 * CONSENT OF COMPANY IS STRICTLY PROHIBITED, AND IN VIOLATION OF APPLICABLE
 * LAWS AND INTERNATIONAL TREATIES. THE RECEIPT OR POSSESSION OF THIS SOURCE
 * CODE AND/OR RELATED INFORMATION DOES NOT CONVEY OR IMPLY ANY RIGHTS TO
 * REPRODUCE, DISCLOSE OR DISTRIBUTE ITS CONTENTS, OR TO MANUFACTURE, USE, OR
 * SELL ANYTHING THAT IT MAY DESCRIBE, IN WHOLE OR IN PART.
 */
package io.machinecode.tools.devsrv;

import io.undertow.Handlers;
import io.undertow.Undertow;
import io.undertow.UndertowOptions;
import io.undertow.server.ConduitWrapper;
import io.undertow.server.HttpHandler;
import io.undertow.server.HttpServerExchange;
import io.undertow.server.ResponseCommitListener;
import io.undertow.server.ServerConnection;
import io.undertow.server.handlers.PathHandler;
import io.undertow.server.handlers.encoding.EncodingHandler;
import io.undertow.server.handlers.proxy.SimpleProxyClientProvider;
import io.undertow.server.handlers.resource.PathResourceManager;
import io.undertow.util.HeaderMap;
import io.undertow.util.Headers;
import io.undertow.util.Methods;
import io.undertow.websockets.core.WebSocketChannel;
import io.undertow.websockets.core.WebSockets;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
import java.security.KeyStore;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;
import javax.net.ssl.KeyManager;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.servlet.ServletException;
import org.xnio.channels.StreamSourceChannel;
import org.xnio.conduits.AbstractStreamSinkConduit;
import org.xnio.conduits.StreamSinkConduit;

/**
 * @author <a href="mailto:brent.n.douglas@gmail.com">Brent Douglas</a>
 */
public class Server implements AutoCloseable {

  final Undertow undertow;
  Consumer<String> send;
  private volatile boolean closed = false;

  public Server(
      final String host,
      final int port,
      final String path,
      final String keystore,
      final Map<String, String> proxies,
      final Map<String, List<String>> pushes,
      final String injected,
      final String message)
      throws Exception {
    PathHandler pathHandler = Handlers.path(Handlers.redirect("/"));
    HttpHandler proxyRoot = null;
    for (final Map.Entry<String, String> it : proxies.entrySet()) {
      final String prefix = it.getKey();
      final String target = it.getValue();
      final HttpHandler proxyHandler =
          Handlers.proxyHandler(new SimpleProxyClientProvider(URI.create(target)));
      if ("/".equals(prefix)) {
        proxyRoot = proxyHandler;
      } else {
        pathHandler =
            pathHandler.addPrefixPath(
                prefix,
                new HttpHandler() {
                  final ResponseCommitListener listener =
                      exch -> exch.getResponseHeaders().remove(Headers.WWW_AUTHENTICATE);

                  @Override
                  public void handleRequest(final HttpServerExchange exchange) throws Exception {
                    exchange.addResponseCommitListener(listener);
                    proxyHandler.handleRequest(exchange);
                  }
                });
      }
    }
    final HttpHandler rootProxy = proxyRoot;

    pathHandler
        .addPrefixPath("/notify", exchange -> sendMessage(message))
        .addPrefixPath(
            "/build",
            Handlers.websocket(
                (exchange, channel) -> {
                  send =
                      msg -> {
                        for (final WebSocketChannel chan : channel.getPeerConnections()) {
                          WebSockets.sendText(msg, chan, null);
                        }
                      };
                  channel.resumeReceives();
                }))
        .addPrefixPath(
            "/",
            new HttpHandler() {
              final HttpHandler next =
                  Handlers.resource(
                      new PathResourceManager(Paths.get(path), 16 * 1024, true, true, true));
              final ConduitWrapper<StreamSinkConduit> conduit =
                  (factory, ex) -> {
                    ex.getResponseHeaders().remove(Headers.CONTENT_LENGTH);
                    return new InjectingConduit(injected, ex, factory.create());
                  };
              final HttpHandler rootHandler = rootProxy != null ? rootProxy : next;

              @Override
              public void handleRequest(final HttpServerExchange exchange) throws Exception {
                final String rp = exchange.getRequestPath();
                final List<String> push = pushes.get(rp);
                if (push != null) {
                  final ServerConnection conn = exchange.getConnection();
                  final HeaderMap headers = exchange.getRequestHeaders();
                  for (final String path : push) {
                    conn.pushResource(path, Methods.GET, headers);
                  }
                }
                switch (rp) {
                  case "/":
                  case "/index.html":
                    exchange.addResponseWrapper(conduit);
                    next.handleRequest(exchange);
                    return;
                }
                final String type = rp.substring(rp.lastIndexOf(".") + 1);
                switch (type) {
                  case "html":
                  case "css":
                  case "js":
                  case "woff":
                  case "woff2":
                  case "ttf":
                  case "appcache":
                    next.handleRequest(exchange);
                    break;
                  default:
                    rootHandler.handleRequest(exchange);
                    break;
                }
              }
            });

    final HttpHandler gzipHandler =
        new EncodingHandler.Builder().build(Collections.emptyMap()).wrap(pathHandler);

    final HttpHandler stripLengthHandler =
        new HttpHandler() {
          final ResponseCommitListener listener =
              exch -> {
                final HeaderMap headers = exch.getResponseHeaders();
                final String encoding = headers.getFirst(Headers.TRANSFER_ENCODING);
                if (encoding != null && Headers.CHUNKED.equalToString(encoding)) {
                  headers.remove(Headers.CONTENT_LENGTH);
                }
              };

          @Override
          public void handleRequest(final HttpServerExchange exchange) throws Exception {
            exchange.getResponseHeaders().add(Headers.VARY, Headers.ACCEPT_ENCODING_STRING);
            exchange.addResponseCommitListener(listener);
            gzipHandler.handleRequest(exchange);
          }
        };

    final HttpHandler httpHandler = Handlers.gracefulShutdown(stripLengthHandler);
    final Undertow.Builder builder =
        Undertow.builder()
            .setServerOption(UndertowOptions.ENABLE_HTTP2, true)
            .setHandler(httpHandler);
    if (keystore == null) {
      this.undertow = builder.addHttpListener(port, host).build();
    } else {
      final String type = "JKS";
      final char[] password = password(keystore);
      final SSLContext sslContext =
          createSSLContext(
              password,
              loadKeyStore(password, keystore + ".keystore." + type.toLowerCase(), type),
              loadKeyStore(password, keystore + ".truststore", type));
      this.undertow = builder.addHttpsListener(port, host, sslContext).build();
    }
    this.undertow.start();
  }

  public void sendMessage(final String msg) {
    if (this.send != null) {
      this.send.accept(msg);
    }
  }

  @Override
  public void close() throws ServletException {
    if (closed) {
      return;
    }
    closed = true;
    this.undertow.stop();
  }

  private static class InjectingConduit extends AbstractStreamSinkConduit<StreamSinkConduit> {
    final byte[] buf = new byte[1024 * 1024];
    final ByteBuffer bytes = ByteBuffer.wrap(buf);
    final String injected;
    final HttpServerExchange exchange;

    public InjectingConduit(
        final String injected, final HttpServerExchange exchange, final StreamSinkConduit next) {
      super(next);
      this.injected = injected;
      this.exchange = exchange;
    }

    @Override
    public long transferFrom(final FileChannel src, final long position, final long count)
        throws IOException {
      final StringBuilder builder = new StringBuilder();
      int read;
      do {
        read = src.read(bytes);
        bytes.flip();
        builder.append(
            new String(buf, bytes.position(), bytes.remaining(), StandardCharsets.UTF_8));
        bytes.flip();
      } while (read > 0);
      final String content = replace(builder.toString());
      return super.write(ByteBuffer.wrap(content.getBytes(StandardCharsets.UTF_8)));
    }

    @Override
    public long transferFrom(
        final StreamSourceChannel source, final long count, final ByteBuffer throughBuffer)
        throws IOException {
      throw new UnsupportedOperationException();
    }

    @Override
    public long write(final ByteBuffer[] srcs, final int offs, final int len) throws IOException {
      return super.write(replace(srcs, offs, len));
    }

    @Override
    public int writeFinal(final ByteBuffer src) throws IOException {
      return super.writeFinal(replace(src));
    }

    @Override
    public long writeFinal(final ByteBuffer[] srcs, final int offs, final int len)
        throws IOException {
      return super.writeFinal(replace(srcs, offs, len));
    }

    @Override
    public int write(final ByteBuffer src) throws IOException {
      return super.write(replace(src));
    }

    private ByteBuffer replace(final ByteBuffer src) {
      final StringBuilder builder = new StringBuilder();
      int rem = Math.min(src.remaining(), buf.length);
      do {
        src.get(buf, 0, rem);
        builder.append(new String(buf, 0, rem, StandardCharsets.UTF_8));
        src.position(src.limit());
        rem = Math.min(src.remaining(), buf.length);
      } while (rem > 0);
      final String content = replace(builder.toString());
      return ByteBuffer.wrap(content.getBytes(StandardCharsets.UTF_8));
    }

    private ByteBuffer replace(final ByteBuffer[] srcs, final int offs, final int len)
        throws IOException {
      final StringBuilder builder = new StringBuilder();
      for (int i = offs; i < len; ++i) {
        final ByteBuffer src = srcs[i];
        int rem = Math.min(src.remaining(), buf.length);
        do {
          src.get(buf, 0, rem);
          builder.append(new String(buf, 0, rem, StandardCharsets.UTF_8));
          src.position(src.limit());
          rem = Math.min(src.remaining(), buf.length);
        } while (rem > 0);
      }
      final String content = replace(builder.toString());
      return ByteBuffer.wrap(content.getBytes(StandardCharsets.UTF_8));
    }

    private String replace(final String in) {
      return in.replace("</head>", injected + "</head>");
    }
  }

  private static KeyStore loadKeyStore(final char[] password, final String name, final String type)
      throws Exception {
    final InputStream stream = Server.class.getClassLoader().getResourceAsStream(name);
    if (stream == null) {
      throw new RuntimeException("Could not load keystore");
    }
    try (final InputStream is = stream) {
      final KeyStore store = KeyStore.getInstance(type);
      store.load(is, password);
      return store;
    }
  }

  private static SSLContext createSSLContext(
      final char[] password, final KeyStore keyStore, final KeyStore trustStore) throws Exception {
    final KeyManagerFactory keyManagerFactory =
        KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
    keyManagerFactory.init(keyStore, password);
    final KeyManager[] keyManagers = keyManagerFactory.getKeyManagers();

    final TrustManagerFactory trustManagerFactory =
        TrustManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
    trustManagerFactory.init(trustStore);
    final TrustManager[] trustManagers = trustManagerFactory.getTrustManagers();

    final SSLContext sslContext = SSLContext.getInstance("TLS");
    sslContext.init(keyManagers, trustManagers, null);
    return sslContext;
  }

  static char[] password(final String name) {
    return name.toCharArray();
  }
}
