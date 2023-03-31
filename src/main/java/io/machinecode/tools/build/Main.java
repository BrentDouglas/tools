/*
 * Copyright (C) 2018 Brent Douglas and other contributors
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
package io.machinecode.tools.build;

import gnu.getopt.Getopt;
import gnu.getopt.LongOpt;
import java.io.File;
import java.io.IOException;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Locale;
import java.util.Map;
import org.stringtemplate.v4.ST;
import org.stringtemplate.v4.STGroup;
import org.stringtemplate.v4.STGroupFile;
import org.stringtemplate.v4.STWriter;
import org.stringtemplate.v4.misc.ErrorBuffer;
import org.yaml.snakeyaml.Yaml;

/**
 * @author <a href="mailto:brent.n.douglas@gmail.com">Brent Douglas</a>
 */
public class Main {

  public static void main(final String... args) throws Exception {
    final Getopt opt =
        new Getopt(
            "template",
            args,
            "m:t:o:v:",
            new LongOpt[] {
              new LongOpt("model", LongOpt.REQUIRED_ARGUMENT, null, 'm'),
              new LongOpt("template", LongOpt.REQUIRED_ARGUMENT, null, 't'),
              new LongOpt("output", LongOpt.REQUIRED_ARGUMENT, null, 'o'),
              new LongOpt("version", LongOpt.REQUIRED_ARGUMENT, null, 'v'),
            });

    Path model = null;
    Path template = null;
    Path output = null;
    String version = null;

    int c;
    while ((c = opt.getopt()) != -1) {
      switch (c) {
        case 'm':
          model = Paths.get(opt.getOptarg());
          break;
        case 't':
          template = Paths.get(opt.getOptarg());
          break;
        case 'o':
          output = Paths.get(opt.getOptarg());
          break;
        case 'v':
          version = opt.getOptarg();
          break;
        default:
          throw new IllegalArgumentException("Invalid option");
      }
    }
    generate(model, template, output, version);
  }

  private static void generate(
      final Path model, final Path template, final Path output, final String version)
      throws IOException {
    final ErrorBuffer errors = new ErrorBuffer();
    final STGroup group =
        new STGroupFile(template.toAbsolutePath().toString(), StandardCharsets.UTF_8.name());
    group.setListener(errors);
    if (!errors.errors.isEmpty()) {
      throw new IllegalArgumentException(errors.toString());
    }
    final ST st = group.getInstanceOf("test");
    final Yaml yaml = new Yaml();
    try (final Reader reader = Files.newBufferedReader(model)) {
      final Map<String, Object> values = yaml.loadAs(reader, Map.class);
      values.forEach(st::add);
    }
    write(st, output.toFile(), errors);
  }

  private static void write(final ST st, final File out, final ErrorBuffer errors)
      throws IllegalArgumentException {
    try {
      st.write(out, errors, StandardCharsets.UTF_8.name(), Locale.ENGLISH, STWriter.NO_WRAP);
      if (!errors.errors.isEmpty()) {
        throw new IllegalArgumentException(errors.toString());
      }
    } catch (final IOException e) {
      throw new IllegalArgumentException("Could not write file " + out.getAbsolutePath(), e);
    }
  }
}
