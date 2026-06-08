-include .env
export

# Capture extra arguments after `make test`, `make test_xxx` and `make nvim`
ifneq (,$(filter test test_% nvim,$(firstword $(MAKECMDGOALS))))
ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(ARGS):;@:)
$(eval .PHONY: $(ARGS))
endif

# `make test` to run tests for all modules for a handful of languages
# `make test python` to run all tests for python
# `make test all` to run all tests for all languages
test: .env
	LANGUAGES="$(ARGS)" nvim --headless --noplugin -c "lua MiniTest.run()"
.PHONY: test

# `make test_xxx` to run tests for module `tests/test_xxx.lua`
# `make test_xxx python` will run it for python
# `make test_xxx all` to run for all languages
TEST_MODULES = $(basename $(notdir $(wildcard tests/test_*.lua)))
$(TEST_MODULES): .env
	LANGUAGES="$(ARGS)" nvim --headless --noplugin -c "lua MiniTest.run_file('tests/$@.lua')"
.PHONY: $(TEST_MODULES)

# Use `make nvim` or `make nvim tests/test_xxx.lua`
nvim: .env
	nvim --noplugin -o $(ARGS)

# Set up test environment
.env: deps/mini.nvim
	@echo "# Generated using make" > .env
	@echo "XDG_CONFIG_HOME=$$(pwd)/scripts" >> .env
	@echo "XDG_DATA_HOME=$$(pwd)/scripts" >> .env
	@echo "XDG_STATE_HOME=$$(pwd)/scripts" >> .env

# Download 'mini.nvim' to use its 'mini.test' testing module
deps/mini.nvim:
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/nvim-mini/mini.nvim $@

# Update 'mini.nvim'
update: deps/mini.nvim
	git -C deps/mini.nvim pull
.PHONY: update
