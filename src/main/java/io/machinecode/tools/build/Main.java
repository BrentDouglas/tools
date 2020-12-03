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

/** @author <a href="mailto:brent.n.douglas@gmail.com">Brent Douglas</a> */
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
