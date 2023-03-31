# Commands
open := $(shell if [ "$$(uname)" == "Darwin" ]; then echo "open"; else echo "xdg-open"; fi)

# Argument to pass to the build system
a := $(shell echo "$${a:-}")
ifndef args
args := $(a)
endif

.PHONY: help
help:
	@echo ""
	@echo "-- Available make targets:"
	@echo ""
	@echo "   all                        - Build everything"
	@echo "   build                      - Build the tools"
	@echo "   check                      - Run linters"
	@echo "   test                       - Run the tests"
	@echo "   coverage                   - Get the test coverage"
	@echo "   format                     - Format the sources"
	@echo ""


.PHONY: all
all: build check

.PHONY: build
build:
	@bazel build //... \
		$(args)

.PHONY: format
format:
	@bazel build @com_github_bazelbuild_buildtools//buildifier \
				@google_java_format//jar
	@find . -type f \( -name BUILD -or -name BUILD.bazel \) \
		| bazel run //:buildifier
	@java -jar \
		--add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED \
		--add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED \
		--add-exports jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED \
		--add-exports jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED \
		--add-exports jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED \
		$$(bazel info | grep output_base | awk '{print $$2}')/external/google_java_format/jar/downloaded.jar -i \
		$$(find src/ -type f -name '*.java')

.PHONY: check
check:
	@bazel test //...:all \
		--build_tag_filters=check \
		--test_tag_filters=check \
		$(args)

.PHONY: test
test:
	@bazel test //...:all \
		--build_tag_filters=-check \
		--test_tag_filters=-check \
		$(args)

.PHONY: build-coverage
build-coverage:
	@if [ -e bazel-out ]; then find bazel-out -name coverage.dat -exec rm {} +; fi
	@bazel coverage \
		//src/main/java/io/machinecode/tools/...:all \
		//src/test/java/io/machinecode/tools/...:all \
		--test_tag_filters=-check \
		$(args)
	@bazel build //:coverage \
		$(args)

.PHONY: coverage
coverage: build-coverage
	@mkdir -p .srv/cov
	@rm -rf .srv/cov && mkdir -p .srv/cov
	@bash -c "(cd .srv/cov && tar xf $$(bazel info bazel-bin)/coverage.tar)"
	@$(open) .srv/cov/index.html