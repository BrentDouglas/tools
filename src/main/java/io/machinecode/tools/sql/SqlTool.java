/*
 * Copyright (C) 2017 Brent Douglas and other contributors
 * as indicated by the @author tags. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package io.machinecode.tools.sql;

import static java.lang.System.out;

import gnu.getopt.Getopt;
import gnu.getopt.LongOpt;
import java.io.FileReader;
import java.sql.Connection;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

/**
 * @author <a href="mailto:brent.n.douglas@gmail.com">Brent Douglas</a>
 */
public class SqlTool {
  static final int _16KB = 16 * 1024;
  static final int _128MB = 128 * 1024 * 1024;

  public static void main(final String... args) throws Exception {
    final Getopt opt =
        new Getopt(
            "sql-tool",
            args,
            "u:U:P:f:c:r:siaodv",
            new LongOpt[] {
              new LongOpt("url", LongOpt.REQUIRED_ARGUMENT, null, 'u'),
              new LongOpt("username", LongOpt.REQUIRED_ARGUMENT, null, 'U'),
              new LongOpt("password", LongOpt.REQUIRED_ARGUMENT, null, 'P'),
              new LongOpt("split", LongOpt.OPTIONAL_ARGUMENT, null, 's'),
              new LongOpt("ignore-errors", LongOpt.OPTIONAL_ARGUMENT, null, 'i'),
              new LongOpt("auto-commit", LongOpt.OPTIONAL_ARGUMENT, null, 'a'),
              new LongOpt("output", LongOpt.OPTIONAL_ARGUMENT, null, 'o'),
              new LongOpt("debug", LongOpt.OPTIONAL_ARGUMENT, null, 'd'),
              new LongOpt("verbose", LongOpt.OPTIONAL_ARGUMENT, null, 'v'),
              new LongOpt("file", LongOpt.OPTIONAL_ARGUMENT, null, 'f'),
              new LongOpt("cmd", LongOpt.OPTIONAL_ARGUMENT, null, 'c'),
              new LongOpt("repeat", LongOpt.OPTIONAL_ARGUMENT, null, 'r')
            });

    String url = null;
    String username = null;
    String password = null;

    List<String> commands = new ArrayList<>();
    List<String> repeat = new ArrayList<>();
    List<String> files = new ArrayList<>();
    boolean split = false;
    boolean ignore = false;
    boolean autoCommit = false;
    boolean output = false;
    boolean debug = false;
    boolean verbose = false;

    int c;
    while ((c = opt.getopt()) != -1) {
      switch (c) {
        case 'u':
          url = opt.getOptarg();
          break;
        case 'U':
          username = opt.getOptarg();
          break;
        case 'P':
          password = opt.getOptarg();
          break;
        case 'c':
          commands.add(opt.getOptarg());
          break;
        case 'r':
          repeat.add(opt.getOptarg());
          break;
        case 'f':
          files.add(opt.getOptarg());
          break;
        case 's':
          split = true;
          break;
        case 'i':
          ignore = true;
          break;
        case 'a':
          autoCommit = true;
          break;
        case 'o':
          output = true;
          break;
        case 'd':
          debug = true;
          break;
        case 'v':
          verbose = true;
          break;
        default:
          _usage();
          return;
      }
    }
    if (files.isEmpty() && commands.isEmpty() && repeat.isEmpty()) {
      throw new RuntimeException("One of -c, -r or -f must be provided");
    }

    try (final Connection connection = getConnection(url, username, password)) {
      connection.setAutoCommit(autoCommit);
      if (!files.isEmpty()) {
        final char[] buf = new char[_16KB];
        for (final String file : files) {
          final StringBuilder sql = new StringBuilder();
          try (final FileReader reader = new FileReader(file)) {
            int n;
            while ((n = reader.read(buf)) > 0) {
              if (!split) {
                sql.append(buf, 0, n);
              } else {
                int s = 0, i = 0;
                for (; i < n; ++i) {
                  /*
                  This doesn't deal with quoting AT ALL. It should deal
                  with regular quotes, comments & dollar quoted strings
                  however we don't need any of that at the moment.
                  */
                  if (buf[i] == ';') {
                    sql.append(buf, s, i - s);
                    execute(connection, file, sql, ignore, debug, verbose);
                    sql.setLength(0);
                    s = i + 1;
                  }
                }
                sql.append(buf, s, i - s);
              }
            }
          }
          execute(connection, file, sql, ignore, debug, verbose);
          log(verbose, "Executed file: " + file);
        }
      }
      for (final String sql : commands) {
        executeCommand(verbose, ignore, output, verbose, connection, sql);
      }
      for (final String sql : repeat) {
        do {
          try {
            executeCommand(false, false, output, verbose, connection, sql);
          } catch (final Exception e) {
            continue;
          }
        } while (false);
      }
      if (!autoCommit) {
        connection.commit();
      }
    }
  }

  private static void executeCommand(
      final boolean log,
      final boolean ignore,
      final boolean output,
      final boolean verbose,
      final Connection connection,
      final String sql)
      throws SQLException {
    try (final Statement stmt = connection.createStatement()) {
      if (output) {
        try (final ResultSet ret = stmt.executeQuery(sql)) {
          while (ret.next()) {
            out.println(ret.getString(1));
          }
        }
      } else {
        stmt.execute(sql);
      }
    } catch (final Exception e) {
      logErr(log, "Failed executing from command :\n" + sql + "\n");
      if (!ignore) {
        throw e;
      } else {
        e.printStackTrace(System.err);
      }
    }
    log(verbose, "Executed command: " + sql);
  }

  private static void log(final boolean verbose, final String msg) {
    if (!verbose) {
      return;
    }
    System.out.println(msg);
  }

  private static void logErr(final boolean verbose, final String msg) {
    if (!verbose) {
      return;
    }
    System.err.println(msg);
  }

  private static void execute(
      final Connection connection,
      final String file,
      final StringBuilder b,
      final boolean ignore,
      final boolean debug,
      final boolean verbose)
      throws SQLException {
    final String sql = b.toString().trim();
    if (sql.length() == 0) {
      return;
    }
    try (final Statement stmt = connection.createStatement()) {
      stmt.execute(sql, Statement.NO_GENERATED_KEYS);
      if (debug) {
        log(verbose, "Executed from " + file + ":\n" + sql);
      }
    } catch (final Exception e) {
      logErr(!ignore, "Failed executing from file " + file + ":\n" + sql + "\n");
      if (!ignore) {
        throw e;
      } else {
        e.printStackTrace(System.err);
      }
    }
  }

  private static void _usage() {
    out.println("Usage: sql-util");
    out.println(
        "       [-h|--host <host>] [-p|--port <port>] [-d|--database <database>] [-U|--username]"
            + " [-P|--password]");
    out.println("       [-s|--split] [-i|--ignore-errors] [-a|--auto-commit]");
    out.println("       [-c|--cmd <sql>] [-f|--file <sql filename>]...");
  }

  /**
   * @param url JDBC connection URL
   * @param username Username or null
   * @param password Password or null
   * @return A connection, only using the provided username and password if both are provided.
   * @throws SQLException
   */
  private static Connection getConnection(
      final String url, final String username, final String password) throws SQLException {
    try {
      Driver driver;
      try {
        driver = DriverManager.getDriver(url);
      } catch (final SQLException e) {
        if (url.startsWith("jdbc:postgresql")) {
          driver = Driver.class.cast(Class.forName("org.postgresql.Driver").newInstance());
          DriverManager.registerDriver(driver);
        } else if (url.startsWith("jdbc:oracle")) {
          driver = Driver.class.cast(Class.forName("oracle.jdbc.OracleDriver").newInstance());
          DriverManager.registerDriver(driver);
        } else {
          throw e;
        }
      }

      final Properties properties = new Properties();
      if (username != null) {
        properties.setProperty("user", username);
      }
      if (password != null) {
        properties.setProperty("password", password);
      }
      properties.setProperty("sendBufferSize", Integer.toString(_128MB));
      properties.setProperty("receiveBufferSize", Integer.toString(_128MB));
      return driver.connect(url, properties);
    } catch (final ClassNotFoundException | InstantiationException | IllegalAccessException e) {
      throw new SQLException(e);
    }
  }
}
