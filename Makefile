NAME ?= 1psa
SOURCE ?= ./cmd/1psa
BIN_DIR ?= bin
ARTIFACT ?= $(BIN_DIR)/$(NAME)
LIB_NAME ?= onepsa
LIB_EXT ?= dylib
LIB_ARTIFACT ?= $(BIN_DIR)/lib$(LIB_NAME).$(LIB_EXT)
INSTALL_DIR ?= /usr/local/bin
INSTALL_PATH ?= $(INSTALL_DIR)/$(NAME)
LIB_INSTALL_DIR ?= /usr/local/lib
LIB_INSTALL_PATH ?= $(LIB_INSTALL_DIR)/lib$(LIB_NAME).$(LIB_EXT)
ARTIFACT_MODE ?= 755
TRASH_ROOT ?= $(HOME)/.Trash
COVER_PROFILE ?= coverage.out
GO_TEST_FLAGS ?=

all: build shared

clean:
	@echo "Cleaning artifact (safe move)"
	@if [ -e "$(ARTIFACT)" ] || [ -L "$(ARTIFACT)" ]; then \
		ts=$$(date +%Y-%m-%d-%H.%M.%S); trash_dir="$(TRASH_ROOT)/$(NAME)_clean_$$ts"; \
		mkdir -p "$$trash_dir"; mv "$(ARTIFACT)" "$$trash_dir/$(NAME)"; \
		echo "Moved $(ARTIFACT) to $$trash_dir/$(NAME)"; \
	else echo "Nothing to clean"; fi

build:
	@echo "Building $(ARTIFACT) from $(SOURCE)"
	@if [ -e "$(ARTIFACT)" ] || [ -L "$(ARTIFACT)" ]; then \
		ts=$$(date +%Y-%m-%d-%H.%M.%S); trash_dir="$(TRASH_ROOT)/$(NAME)_build_$$ts"; \
		mkdir -p "$$trash_dir"; mv "$(ARTIFACT)" "$$trash_dir/$(NAME)"; \
		echo "Preserved previous artifact at $$trash_dir/$(NAME)"; \
	fi
	@mkdir -p "$(BIN_DIR)"
	@go build -o "$(ARTIFACT)" "$(SOURCE)"
	@chmod "$(ARTIFACT_MODE)" "$(ARTIFACT)"
	@echo "Built $(ARTIFACT) with mode $(ARTIFACT_MODE)"

shared:
	@echo "Building $(LIB_ARTIFACT) from ./cshared (c-shared)"
	@if [ -e "$(LIB_ARTIFACT)" ] || [ -L "$(LIB_ARTIFACT)" ]; then \
		ts=$$(date +%Y-%m-%d-%H.%M.%S); trash_dir="$(TRASH_ROOT)/$(LIB_NAME)_shared_$$ts"; \
		mkdir -p "$$trash_dir"; mv "$(LIB_ARTIFACT)" "$$trash_dir/lib$(LIB_NAME).$(LIB_EXT)"; \
		echo "Preserved previous shared library at $$trash_dir/lib$(LIB_NAME).$(LIB_EXT)"; \
	fi
	@mkdir -p "$(BIN_DIR)"
	@go build -buildmode=c-shared -o "$(LIB_ARTIFACT)" ./cshared
	@chmod "$(ARTIFACT_MODE)" "$(LIB_ARTIFACT)"
	@echo "Built $(LIB_ARTIFACT) with mode $(ARTIFACT_MODE)"

compile: build

compile-shared: shared

test-go:
	@echo "Running Go tests"
	@go test $(GO_TEST_FLAGS) ./...

test-python: compile-shared
	@echo "Running Python wrapper tests"
	@python -m unittest discover -s python -p "test_*.py" -v

test: build test-go test-python
	@echo "All tests passed"

coverage:
	@$(MAKE) test-go GO_TEST_FLAGS="-coverprofile=$(COVER_PROFILE)"
	@echo "Coverage summary from $(COVER_PROFILE)"
	@go tool cover -func="$(COVER_PROFILE)"

install: build shared
	@echo "Installing $(NAME) to $(INSTALL_PATH)"
	@if [ "$$(id -u)" -ne 0 ]; then echo "Install requires sudo/root. Run: sudo make install"; exit 1; fi
	@if [ -e "$(INSTALL_PATH)" ] || [ -L "$(INSTALL_PATH)" ]; then \
		ts=$$(date +%Y-%m-%d-%H.%M.%S); trash_dir="$(TRASH_ROOT)/$(NAME)_install_$$ts"; \
		mkdir -p "$$trash_dir"; mv "$(INSTALL_PATH)" "$$trash_dir/$(NAME)"; \
		echo "Preserved previous install at $$trash_dir/$(NAME)"; \
	fi
	@mkdir -p "$(INSTALL_DIR)"
	@install -m "$(ARTIFACT_MODE)" "$(ARTIFACT)" "$(INSTALL_PATH)"
	@echo "Installed $(INSTALL_PATH)"
	@echo "Installing lib$(LIB_NAME).$(LIB_EXT) to $(LIB_INSTALL_PATH)"
	@if [ -e "$(LIB_INSTALL_PATH)" ] || [ -L "$(LIB_INSTALL_PATH)" ]; then \
		ts=$$(date +%Y-%m-%d-%H.%M.%S); trash_dir="$(TRASH_ROOT)/$(LIB_NAME)_lib_install_$$ts"; \
		mkdir -p "$$trash_dir"; mv "$(LIB_INSTALL_PATH)" "$$trash_dir/lib$(LIB_NAME).$(LIB_EXT)"; \
		echo "Preserved previous shared library install at $$trash_dir/lib$(LIB_NAME).$(LIB_EXT)"; \
	fi
	@mkdir -p "$(LIB_INSTALL_DIR)"
	@install -m "$(ARTIFACT_MODE)" "$(LIB_ARTIFACT)" "$(LIB_INSTALL_PATH)"
	@echo "Installed $(LIB_INSTALL_PATH)"

uninstall:
	@echo "Uninstalling $(INSTALL_PATH) and $(LIB_INSTALL_PATH)"
	@if [ "$$(id -u)" -ne 0 ]; then echo "Uninstall requires sudo/root. Run: sudo make uninstall"; exit 1; fi
	@if [ -L "$(INSTALL_PATH)" ] || [ -e "$(INSTALL_PATH)" ]; then \
		rm -f "$(INSTALL_PATH)" && echo "Removed $(INSTALL_PATH)"; \
	else echo "Nothing to uninstall"; fi
	@if [ -L "$(LIB_INSTALL_PATH)" ] || [ -e "$(LIB_INSTALL_PATH)" ]; then \
		rm -f "$(LIB_INSTALL_PATH)" && echo "Removed $(LIB_INSTALL_PATH)"; \
	else echo "No shared library install to uninstall"; fi

.PHONY: all clean build shared compile compile-shared test test-go test-python coverage install uninstall
