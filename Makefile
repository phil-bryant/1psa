NAME ?= 1psa
SOURCE ?= .
BIN_DIR ?= bin
ARTIFACT ?= $(BIN_DIR)/$(NAME)
INSTALL_DIR ?= /usr/local/bin
INSTALL_PATH ?= $(INSTALL_DIR)/$(NAME)
ARTIFACT_MODE ?= 755
TRASH_ROOT ?= $(HOME)/.Trash

all: build

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

compile: build

install: build
	@echo "Installing $(NAME) to $(INSTALL_PATH) as symlink"
	@if [ "$$(id -u)" -ne 0 ]; then echo "Install requires sudo/root. Run: sudo make install"; exit 1; fi
	@if [ -e "$(INSTALL_PATH)" ] || [ -L "$(INSTALL_PATH)" ]; then \
		ts=$$(date +%Y-%m-%d-%H.%M.%S); trash_dir="$(TRASH_ROOT)/$(NAME)_install_$$ts"; \
		mkdir -p "$$trash_dir"; mv "$(INSTALL_PATH)" "$$trash_dir/$(NAME)"; \
		echo "Preserved previous install at $$trash_dir/$(NAME)"; \
	fi
	@ln -sf "$(CURDIR)/$(ARTIFACT)" "$(INSTALL_PATH)"
	@echo "Installed $(INSTALL_PATH) -> $(CURDIR)/$(ARTIFACT)"

uninstall:
	@echo "Uninstalling $(INSTALL_PATH)"
	@if [ "$$(id -u)" -ne 0 ]; then echo "Uninstall requires sudo/root. Run: sudo make uninstall"; exit 1; fi
	@if [ -L "$(INSTALL_PATH)" ] || [ -e "$(INSTALL_PATH)" ]; then \
		unlink "$(INSTALL_PATH)" && echo "Unlinked $(INSTALL_PATH)"; \
	else echo "Nothing to uninstall"; fi

.PHONY: all clean build compile install uninstall
