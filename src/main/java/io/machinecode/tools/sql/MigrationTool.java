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
import java.io.FileInputStream;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.configuration.ClassicConfiguration;
import org.flywaydb.core.api.logging.Log;
import org.flywaydb.core.api.logging.LogCreator;
import org.flywaydb.core.api.logging.LogFactory;
import org.flywaydb.core.internal.logging.javautil.JavaUtilLog;

/**
 * @author <a href="mailto:brent.n.douglas@gmail.com">Brent Douglas</a>
 */
public class MigrationTool {

  public static void main(final String... args) throws Exception {
    final Getopt opt =
        new Getopt(
            "migration-tool",
            args,
            "o:c:l:",
            new LongOpt[] {
              new LongOpt("config", LongOpt.OPTIONAL_ARGUMENT, null, 'c'),
              new LongOpt("op", LongOpt.OPTIONAL_ARGUMENT, null, 'o'),
              new LongOpt("log", LongOpt.OPTIONAL_ARGUMENT, null, 'l')
            });

    String config = null;
    String op = null;
    Level level = Level.WARNING;

    int c;
    while ((c = opt.getopt()) != -1) {
      switch (c) {
        case 'c':
          config = opt.getOptarg();
          break;
        case 'o':
          op = opt.getOptarg();
          break;
        case 'l':
          switch (opt.getOptarg().toLowerCase().charAt(0)) {
            case 'd':
              level = Level.FINE;
              break;
            case 'i':
              level = Level.INFO;
              break;
          }
          break;
        default:
          _usage();
          return;
      }
    }
    if (config == null) {
      throw new RuntimeException("-c must be provided");
    }
    if (op == null) {
      throw new RuntimeException("-o must be provided");
    }

    final ClassicConfiguration configuration = new ClassicConfiguration();
    final Properties properties = new Properties();
    properties.load(new FileInputStream(config));
    configuration.configure(properties);
    final Level finalLevel = level;
    LogFactory.setFallbackLogCreator(
        new LogCreator() {
          @Override
          public Log createLogger(final Class<?> clazz) {
            final Logger log = Logger.getLogger(clazz.getName());
            log.setLevel(finalLevel);
            return new JavaUtilLog(log);
          }
        });
    final Flyway flyway = new Flyway(configuration);
    if (op.startsWith("m")) {
      flyway.migrate();
    } else if (op.startsWith("c")) {
      flyway.clean();
    } else {
      throw new UnsupportedOperationException("Unsupported operation: " + op);
    }
  }

  private static void _usage() {
    out.println("Usage: migration-tool -o op -c|--config <filename>");
  }
}
