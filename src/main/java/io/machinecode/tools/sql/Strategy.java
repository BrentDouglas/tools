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
package io.machinecode.tools.sql;

import org.jooq.codegen.DefaultGeneratorStrategy;
import org.jooq.meta.Definition;

/**
 * @author <a href="mailto:brent.n.douglas@gmail.com">Brent Douglas</a>
 * @since 1.0
 */
public class Strategy extends DefaultGeneratorStrategy {

  @Override
  public String getJavaMemberName(final Definition definition, final Mode mode) {
    return toCamelCase("", definition.getOutputName(), false);
  }

  @Override
  public String getJavaSetterName(final Definition definition, final Mode mode) {
    return toCamelCase("set", definition.getOutputName(), true);
  }

  @Override
  public String getJavaGetterName(final Definition definition, final Mode mode) {
    return toCamelCase("get", definition.getOutputName(), true);
  }

  private static String toCamelCase(final String prefix, final String out, boolean upper) {
    final StringBuilder ret = new StringBuilder(prefix);
    for (int i = 0, len = out.length(); i < len; ++i) {
      final char c = out.charAt(i);
      switch (c) {
        case ' ':
        case '_':
        case '-':
          upper = true;
          break;
        default:
          ret.append(upper ? Character.toUpperCase(c) : c);
          upper = false;
      }
    }
    return ret.toString();
  }
}
