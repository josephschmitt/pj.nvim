.PHONY: test test-file deps clean help

# Test dependency directory
TEST_DEPS_DIR := test-deps

# mini.nvim repository
MINI_NVIM_REPO := https://github.com/echasnovski/mini.nvim.git

# Default target
help:
	@echo "pj.nvim test commands:"
	@echo "  make deps       - Install test dependencies (mini.nvim)"
	@echo "  make test       - Run all tests"
	@echo "  make test-file FILE=<path>  - Run tests in a specific file"
	@echo "  make clean      - Remove test dependencies"

# Install test dependencies
deps:
	@echo "Installing test dependencies..."
	@mkdir -p $(TEST_DEPS_DIR)
	@if [ ! -d "$(TEST_DEPS_DIR)/mini.nvim" ]; then \
		echo "Cloning mini.nvim..."; \
		git clone --depth 1 $(MINI_NVIM_REPO) $(TEST_DEPS_DIR)/mini.nvim; \
	else \
		echo "mini.nvim already installed"; \
	fi
	@echo "Done!"

# Run all tests
test: deps
	@echo "Running tests..."
	@nvim --headless -u tests/minimal_init.lua -c "luafile tests/init.lua" 2>&1

# Run a specific test file
test-file: deps
ifndef FILE
	$(error FILE is required. Usage: make test-file FILE=tests/unit/depth_spec.lua)
endif
	@echo "Running tests in $(FILE)..."
	@nvim --headless -u tests/minimal_init.lua -c "lua \
		local MiniTest = require('mini.test'); \
		MiniTest.setup(); \
		MiniTest.run({ \
			collect = { \
				emulate_busted = false, \
				find_files = function() return { '$(FILE)' } end, \
			}, \
			execute = { \
				reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }), \
			}, \
		}); \
		vim.cmd('qall!')" 2>&1

# Clean test dependencies
clean:
	@echo "Removing test dependencies..."
	@rm -rf $(TEST_DEPS_DIR)
	@echo "Done!"
