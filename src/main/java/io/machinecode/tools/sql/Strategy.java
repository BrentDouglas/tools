/*
 * Machine Code Limited ("COMPANY") CONFIDENTIAL
 * Unpublished Copyright (C) 2016 Machine Code Limited, All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of COMPANY. The intellectual and technical concepts contained
 * herein are proprietary to COMPANY and may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is strictly forbidden unless prior written permission is obtained
 * from COMPANY. Access to the source code contained herein is hereby forbidden to anyone except current COMPANY employees, managers or contractors who have executed
 * Confidentiality and Non-disclosure agreements explicitly covering such access.
 *
 * The copyright notice above does not evidence any actual or intended publication or disclosure of this source code, which includes
 * information that is confidential and/or proprietary, and is a trade secret, of COMPANY. ANY REPRODUCTION, MODIFICATION, DISTRIBUTION, PUBLIC PERFORMANCE,
 * OR PUBLIC DISPLAY OF OR THROUGH USE OF THIS SOURCE CODE WITHOUT THE EXPRESS WRITTEN CONSENT OF COMPANY IS STRICTLY PROHIBITED, AND IN VIOLATION OF APPLICABLE
 * LAWS AND INTERNATIONAL TREATIES. THE RECEIPT OR POSSESSION OF THIS SOURCE CODE AND/OR RELATED INFORMATION DOES NOT CONVEY OR IMPLY ANY RIGHTS
 * TO REPRODUCE, DISCLOSE OR DISTRIBUTE ITS CONTENTS, OR TO MANUFACTURE, USE, OR SELL ANYTHING THAT IT MAY DESCRIBE, IN WHOLE OR IN PART.
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
