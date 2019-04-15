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

import com.sun.nio.file.SensitivityWatchEventModifier;
import gnu.getopt.Getopt;
import gnu.getopt.LongOpt;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.file.FileSystem;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.StandardWatchEventKinds;
import java.nio.file.WatchEvent;
import java.nio.file.WatchKey;
import java.nio.file.WatchService;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.IdentityHashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import static java.lang.System.out;

/** @author <a href="mailto:brent.n.douglas@gmail.com">Brent Douglas</a> */
public class Main {

  public static void main(final String[] args) throws Exception {
    final Getopt opt =
        new Getopt(
            "devsrv",
            args,
            "H:P:C:d:p:k:w:c:r:h",
            new LongOpt[] {
              new LongOpt("host", LongOpt.REQUIRED_ARGUMENT, null, 'H'),
              new LongOpt("port", LongOpt.REQUIRED_ARGUMENT, null, 'P'),
              new LongOpt("config", LongOpt.REQUIRED_ARGUMENT, null, 'C'),
              new LongOpt("dir", LongOpt.REQUIRED_ARGUMENT, null, 'd'),
              new LongOpt("proxy", LongOpt.REQUIRED_ARGUMENT, null, 'p'),
              new LongOpt("keystore", LongOpt.REQUIRED_ARGUMENT, null, 'k'),
              new LongOpt("watch", LongOpt.REQUIRED_ARGUMENT, null, 'w'),
              new LongOpt("command", LongOpt.REQUIRED_ARGUMENT, null, 'c'),
              new LongOpt("push-resources", LongOpt.REQUIRED_ARGUMENT, null, 'r'),
              new LongOpt("help", LongOpt.REQUIRED_ARGUMENT, null, 'h'),
            });

    String host = "localhost";
    String port = "8080";
    String config = null;
    String dir = null;
    String keystore = null;
    final Map<String, String> proxies = new LinkedHashMap<>();
    String command = null;
    final List<String> watches = new ArrayList<>();
    final Map<String, List<String>> pushes = new LinkedHashMap<>();

    int c;
    while ((c = opt.getopt()) != -1) {
      switch (c) {
        case 'H':
          host = opt.getOptarg();
          break;
        case 'P':
          port = opt.getOptarg();
          break;
        case 'C':
          config = opt.getOptarg();
          break;
        case 'd':
          dir = opt.getOptarg();
          break;
        case 'k':
          keystore = opt.getOptarg();
          break;
        case 'p':
          {
            final String[] arg = opt.getOptarg().split("=");
            switch (arg.length) {
              case 2:
                proxies.put(arg[0], arg[1]);
                break;
              default:
                throw new IllegalStateException();
            }
            break;
          }
        case 'r':
          {
            final String[] arg = opt.getOptarg().split("=");
            switch (arg.length) {
              case 2:
                for (final String key : arg[0].split(",")) {
                  pushes.put(key, Arrays.asList(arg[1].split(",")));
                }
                break;
              default:
                throw new IllegalStateException();
            }
            break;
          }
        case 'w':
          watches.add(opt.getOptarg());
          break;
        case 'c':
          command = opt.getOptarg();
          break;
        case 'h':
        default:
          _usage();
          return;
      }
    }
    if (config != null) {
      if (config.endsWith(".xml")) {
        System.getProperties().loadFromXML(new FileInputStream(config));
      } else {
        System.getProperties().load(new FileInputStream(config));
      }
    }
    if (dir == null) {
      throw new IllegalStateException("dir must be provided");
    }

    final String wsProtocol = keystore == null ? "ws" : "wss";

    try (final Server server =
        new Server(
            host,
            Integer.decode(port),
            dir,
            keystore,
            proxies,
            pushes,
            "<script type=\"text/javascript\">\n"
                + "  window.buildSocket = new WebSocket('"
                + wsProtocol
                + "://"
                + host
                + ":"
                + port
                + "/build');\n"
                + "  window.buildSocket.onmessage = function(event) {\n"
                + "    window.location.reload();\n"
                + "  };\n"
                + "</script>",
            "Build completed")) {
      Runtime.getRuntime()
          .addShutdownHook(
              new Thread(
                  () -> {
                    try {
                      server.close();
                    } catch (final Exception e) {
                      e.printStackTrace();
                    }
                  }));
      final Map<FileSystem, WatchService> services = new IdentityHashMap<>();
      for (final String watch : watches) {
        final Path root = new File(watch).toPath();
        final WatchService service =
            services.computeIfAbsent(
                root.getFileSystem(),
                fs -> {
                  try {
                    return fs.newWatchService();
                  } catch (IOException e) {
                    throw new RuntimeException(e);
                  }
                });
        Files.walkFileTree(
            root,
            new SimpleFileVisitor<Path>() {
              @Override
              public FileVisitResult preVisitDirectory(
                  final Path dir, final BasicFileAttributes attrs) throws IOException {
                dir.register(
                    service,
                    new WatchEvent.Kind[] {
                      StandardWatchEventKinds.ENTRY_CREATE,
                      StandardWatchEventKinds.ENTRY_DELETE,
                      StandardWatchEventKinds.ENTRY_MODIFY
                    },
                    SensitivityWatchEventModifier.HIGH);
                return FileVisitResult.CONTINUE;
              }
            });
      }
      if (services.isEmpty()) {
        for (; ; ) {
          Thread.sleep(Long.MAX_VALUE);
        }
      } else {
        for (; ; ) {
          boolean found = false;
          for (final Map.Entry<FileSystem, WatchService> e : services.entrySet()) {
            final WatchKey key = e.getValue().poll(3, TimeUnit.SECONDS);
            if (key == null) {
              continue;
            }
            final List<WatchEvent<?>> events = key.pollEvents();
            if (events.isEmpty()) {
              continue;
            }
            events.forEach(
                it -> System.out.println("Handling event " + it.kind() + " for " + it.context()));
            found = true;
          }
          if (found) {
            System.out.println("Running command: " + command);
            if (run(command) == 0) {
              server.sendMessage("build complete");
              System.out.println("Command succeeded");
            } else {
              System.out.println("Command failed");
            }
          }
        }
      }
    }
  }

  private static int run(final String command) throws InterruptedException, IOException {
    final AtomicBoolean running = new AtomicBoolean(true);

    final ProcessBuilder builder = new ProcessBuilder().command(command.split("\\s+")).inheritIO();
    builder.environment().putAll(System.getenv());
    final Process proc = builder.start();

    final Thread hook =
        new Thread(
            () -> {
              running.set(false);
              proc.destroyForcibly();
            });
    Runtime.getRuntime().addShutdownHook(hook);
    final int ret = proc.waitFor();
    Runtime.getRuntime().removeShutdownHook(hook);
    return ret;
  }

  private static void _usage() {
    out.println("Usage: tools [options]");
    out.println();
    out.println(
        "        [-H|--host <host>]             The hostname or IP for the server to bind to.");
    out.println("        [-P|--port <port>]             The port for the server to bind to.");
    out.println(
        "        [-C|--config <path>]           A .xml or .properties file to load system properties from.");
    out.println("        [-d|--dir <dir>]               The directory to serve.");
    out.println(
        "        [-k|--keystore <dir>]          The name of a keystore. If this is set we will listen using HTTPS.");
    out.println(
        "        [-p|--proxy <prefix>=<url>]... A key value mapping of prefix to URL to proxy.");
    out.println();
    out.println("        [-w|--watch <dir>]             A directory to watch for changed.");
    out.println(
        "        [-c|--command <cmd>]           A command to run if any content in the directories change.");
    out.println();
    out.println("        [-h|--help]                    Print this message and exit.");
    out.println();
  }
}
