/*
 * Copyright (C) 2025 Brent Douglas and other contributors
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
package io.machinecode.tools.bench;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;
import org.openjdk.jmh.annotations.Mode;
import org.openjdk.jmh.profile.AsyncProfiler;
import org.openjdk.jmh.profile.JavaFlightRecorderProfiler;
import org.openjdk.jmh.runner.Runner;
import org.openjdk.jmh.runner.options.ChainedOptionsBuilder;
import org.openjdk.jmh.runner.options.Options;
import org.openjdk.jmh.runner.options.OptionsBuilder;
import org.openjdk.jmh.runner.options.TimeValue;

/**
 * @author <a href="mailto:brent.n.douglas@gmail.com">Brent Douglas</a>
 */
public class BaseBench {
  private static final String BENCH_DIR = ".bench";

  public static void run(Class<?> bench) {
    builder(bench).addDefaultAsyncProfilerOptions().run();
  }

  private static void run(Config config) {
    try {
      final Path benchDir = Path.of(BENCH_DIR);
      linkWorkTrees(benchDir);
      final Path outputPath =
          Paths.get(
                  BENCH_DIR,
                  config.bench.getSimpleName(),
                  DateTimeFormatter.ISO_LOCAL_DATE_TIME
                      .format(LocalDateTime.now().withNano(0))
                      .replace(":", "-"))
              .toAbsolutePath();
      deleteDir(outputPath);
      Files.createDirectories(outputPath);
      final String outputDir = outputPath.toString();
      final String version = getGitInfo();
      Files.writeString(outputPath.resolve("version.txt"), version);
      final ChainedOptionsBuilder builder =
          new OptionsBuilder()
              .include(config.bench.getName())
              .mode(Mode.AverageTime)
              .timeUnit(TimeUnit.MICROSECONDS)
              .warmupTime(TimeValue.seconds(10))
              .warmupIterations(5)
              .measurementTime(TimeValue.seconds(10))
              .measurementIterations(10)
              .timeout(TimeValue.seconds(10))
              .addProfiler(JavaFlightRecorderProfiler.class, "dir=" + outputDir)
              .forks(1)
              .jvmArgsAppend("-da", "-dsa");
      final String profilerPath = extractEmbeddedLib(benchDir.toAbsolutePath());
      final boolean hasAsyncProfiler = profilerPath != null;
      if (hasAsyncProfiler) {
        config.asyncProfilerOptions.add("dir=" + outputDir);
        config.asyncProfilerOptions.add("libPath=" + profilerPath);
        builder.addProfiler(AsyncProfiler.class, String.join(";", config.asyncProfilerOptions));
      }
      final Options options = builder.build();
      if (hasAsyncProfiler) {
        Runtime.getRuntime()
            .addShutdownHook(
                new Thread(
                    () -> {
                      System.out.println("\nCreating flamegraphs:");
                      findFilesNamed(
                          outputPath,
                          Path.of("jfr-cpu.jfr"),
                          jfr -> {
                            try {
                              final Path profileDir = jfr.getParent().toAbsolutePath();
                              final Path flameGraph = profileDir.resolve("flamegraph.html");
                              Class.forName("jfr2flame")
                                  .getDeclaredMethod("main", String[].class)
                                  .invoke(
                                      null,
                                      (Object)
                                          new String[] {
                                            "--threads", jfr.toString(), flameGraph.toString()
                                          });
                              System.out.println("\tfile://" + flameGraph);
                            } catch (final Exception e) {
                              e.printStackTrace(System.err);
                            }
                          });
                    }));
      }
      new Runner(options).run();
      System.exit(0);
    } catch (Exception e) {
      e.printStackTrace(System.err);
      System.exit(1);
    }
  }

  private static String extractEmbeddedLib(final Path benchDir) {
    final String resourceName = "/" + getPlatformTag() + "/libasyncProfiler.so";
    final InputStream in = one.profiler.AsyncProfiler.class.getResourceAsStream(resourceName);
    if (in == null) {
      return null;
    }
    try {
      final Path outputFile = benchDir.resolve("libasyncProfiler.so");
      try (final OutputStream out = Files.newOutputStream(outputFile)) {
        final byte[] buf = new byte[32000];
        for (int bytes; (bytes = in.read(buf)) >= 0; ) {
          out.write(buf, 0, bytes);
        }
      }
      return outputFile.toString();
    } catch (IOException e) {
      throw new IllegalStateException(e);
    } finally {
      try {
        in.close();
      } catch (IOException e) {
        // ignore
      }
    }
  }

  private static String getPlatformTag() {
    String os = System.getProperty("os.name").toLowerCase();
    String arch = System.getProperty("os.arch").toLowerCase();
    if (os.contains("linux")) {
      if (arch.equals("amd64") || arch.equals("x86_64") || arch.contains("x64")) {
        return "linux-x64";
      } else if (arch.equals("aarch64") || arch.contains("arm64")) {
        return "linux-arm64";
      } else if (arch.equals("aarch32") || arch.contains("arm")) {
        return "linux-arm32";
      } else if (arch.contains("86")) {
        return "linux-x86";
      } else if (arch.contains("ppc64")) {
        return "linux-ppc64le";
      }
    } else if (os.contains("mac")) {
      return "macos";
    }
    throw new UnsupportedOperationException("Unsupported platform: " + os + "-" + arch);
  }

  private static void deleteDir(Path dir) {
    try {
      if (!Files.exists(dir)) {
        return;
      }
      Files.walkFileTree(
          dir,
          new SimpleFileVisitor<Path>() {
            @Override
            public FileVisitResult postVisitDirectory(final Path dir, final IOException exc)
                throws IOException {
              Files.delete(dir);
              return FileVisitResult.CONTINUE;
            }

            @Override
            public FileVisitResult visitFile(final Path file, final BasicFileAttributes attrs)
                throws IOException {
              Files.delete(file);
              return FileVisitResult.CONTINUE;
            }
          });
    } catch (IOException e) {
      throw new AssertionError(e);
    }
  }

  private static void findFilesNamed(
      final Path dir, final Path name, final Consumer<Path> operation) {
    try {
      if (!Files.exists(dir)) {
        return;
      }
      final List<String> ret = new ArrayList<>();
      Files.walkFileTree(
          dir,
          new SimpleFileVisitor<Path>() {
            @Override
            public FileVisitResult postVisitDirectory(final Path dir, final IOException exc) {
              return FileVisitResult.CONTINUE;
            }

            @Override
            public FileVisitResult visitFile(final Path file, final BasicFileAttributes attrs) {
              if (file.getFileName().equals(name)) {
                operation.accept(file);
              }
              return FileVisitResult.CONTINUE;
            }
          });
    } catch (IOException e) {
      throw new AssertionError(e);
    }
  }

  private static String getGitInfo() throws Exception {
    final Process commitProc = new ProcessBuilder("git", "rev-parse", "HEAD").start();
    final Process branchProc = new ProcessBuilder("git", "branch", "--show-current").start();
    commitProc.waitFor();
    branchProc.waitFor();
    final String commit =
        new String(commitProc.getInputStream().readAllBytes(), StandardCharsets.UTF_8).trim();
    final String branch =
        new String(branchProc.getInputStream().readAllBytes(), StandardCharsets.UTF_8).trim();
    return "branch: " + branch + "\ncommit: " + commit;
  }

  private static void linkWorkTrees(final Path benchDir) throws IOException {
    if (Files.isSymbolicLink(benchDir)) {
      final Path realBenchDir = Files.readSymbolicLink(benchDir);
      if (!Files.isDirectory(realBenchDir)) {
        throw new IllegalStateException(benchDir + " must link to a directory");
      }
      return;
    }
    final Path git = Path.of(".git");
    if (Files.isRegularFile(git)) {
      final String content = Files.readString(git).trim();
      if (!content.startsWith("gitdir:")) {
        throw new IllegalStateException(
            "If .git is a file it should point to the primary git work dir");
      }
      final String primaryRepo =
          content.replaceAll("gitdir: ", "").replaceAll("/\\.git/worktrees.*", "");
      final Path primaryBenchDir = Path.of(primaryRepo, benchDir.toString());
      if (!Files.exists(primaryBenchDir)) {
        Files.createDirectories(primaryBenchDir);
        Files.createSymbolicLink(benchDir, primaryBenchDir);
      } else if (Files.isDirectory(primaryBenchDir)) {
        Files.createSymbolicLink(benchDir, primaryBenchDir);
      } else {
        throw new IllegalStateException("Unsupported directory structure");
      }
    } else {
      if (!Files.exists(benchDir)) {
        Files.createDirectories(benchDir);
      } else if (!Files.isDirectory(benchDir)) {
        throw new IllegalStateException("Unsupported directory structure");
      }
    }
  }

  public static Config builder(Class<?> bench) {
    return new Config(bench);
  }

  public static class Config {
    private final Class<?> bench;
    private final List<String> asyncProfilerOptions = new ArrayList<>();
    private Consumer<ChainedOptionsBuilder> configure = it -> {};

    public Config(final Class<?> bench) {
      this.bench = bench;
    }

    public Config addDefaultAsyncProfilerOptions() {

      return addAsyncProfilerOption("interval=5000000")
          .addAsyncProfilerOption("output=jfr")
          .addAsyncProfilerOption("threads=true")
          .addAsyncProfilerOption("event=cpu")
          .addAsyncProfilerOption("alloc")
          .addAsyncProfilerOption("lock");
    }

    public Config addAsyncProfilerOption(final String option) {
      this.asyncProfilerOptions.add(option);
      return this;
    }

    public void run() {
      BaseBench.run(this);
    }
  }
}
