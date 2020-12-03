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
import java.io.FileOutputStream;
import java.nio.charset.Charset;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

/** @author <a href="mailto:brent.n.douglas@gmail.com">Brent Douglas</a> */
public class HashTool {

  public static final int _16KB = 16 * 1024;
  public static final Charset UTF_8 = Charset.forName("UTF-8");

  public static void main(final String... args) throws Exception {
    final Getopt opt =
        new Getopt(
            "hash-tool",
            args,
            "i:r:o:",
            new LongOpt[] {
              new LongOpt("in", LongOpt.OPTIONAL_ARGUMENT, null, 'i'),
              new LongOpt("raw", LongOpt.OPTIONAL_ARGUMENT, null, 'r'),
              new LongOpt("out", LongOpt.OPTIONAL_ARGUMENT, null, 'o')
            });

    List<String> in = new ArrayList<>();
    List<String> raw = new ArrayList<>();
    String out = null;

    int c;
    while ((c = opt.getopt()) != -1) {
      switch (c) {
        case 'i':
          in.add(opt.getOptarg());
          break;
        case 'r':
          raw.add(opt.getOptarg());
          break;
        case 'o':
          out = opt.getOptarg();
          break;
        default:
          _usage();
          return;
      }
    }
    if (in.isEmpty() && raw.isEmpty()) {
      throw new RuntimeException("-i or -r must be provided");
    }
    if (out == null) {
      throw new RuntimeException("-o must be provided");
    }

    final MessageDigest md = MessageDigest.getInstance("SHA-1");
    final byte[] buf = new byte[_16KB];
    for (final String file : in) {
      try (final FileInputStream f = new FileInputStream(file)) {
        int n;
        while ((n = f.read(buf)) > 0) {
          md.update(buf, 0, n);
        }
      }
    }
    for (final String str : raw) {
      md.update(str.getBytes(UTF_8));
    }
    try (final FileOutputStream f = new FileOutputStream(out)) {
      f.write(Base64.getEncoder().encode(md.digest()));
    }
  }

  private static void _usage() {
    out.println(
        "Usage: hash-tool [-o|--out <filename>] [-r|--raw <string>]... [-i|--in <filename>]...");
  }
}
