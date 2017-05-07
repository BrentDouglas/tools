
# Paths

BAZEL_BIN := $(shell bazel info bazel-bin)
BAZEL_EXEC_ROOT := $(shell bazel info execution_root)

# Commands

WATCH := python3 $(BAZEL_EXEC_ROOT)/external/io_machinecode_tools/tools/watch.py
DEV_SRV = DEFAULT_JVM_DEBUG_SUSPEND=n bash $(BAZEL_BIN)/external/io_machinecode_tools/src/main/java/io/machinecode/tools/devsrv/devsrv
open := $(shell if [ "$$(uname)" == "Darwin" ]; then echo "open"; else echo "xdg-open"; fi)

# Arguments

# Argument to pass to the build system
a := $(shell echo "$${a:-}")
ifndef args
args := $(a)
endif

# Bind host for serving things
h := $(shell echo "$${h:-localhost}")
ifndef args
host := $(h)
endif

# Transport when serving things
t := $(shell echo "$${t:-http}")
ifndef args
transport := $(t)
endif
keystore := $(shell if [ "$(transport)" == "https" ]; then echo "--keystore $(host)"; fi)
