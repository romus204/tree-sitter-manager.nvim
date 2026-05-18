-include .env
export

# Use `make test` to run tests for all modules
test: .env
	nvim --headless --noplugin -c "lua MiniTest.run()"
.PHONY: test

# Use `make test_xxx` to run tests for module `tests/test_xxx.lua`
TEST_MODULES = $(basename $(notdir $(wildcard tests/test_*.lua)))
$(TEST_MODULES): .env
	nvim --headless --noplugin -c "lua MiniTest.run_file('tests/$@.lua')"
.PHONY: $(TEST_MODULES)

# Use `make nvim` or `make nvim tests/test_xxx.lua`
ifeq (nvim,$(firstword $(MAKECMDGOALS)))
  # Take the rest of the arguments and assign them to ARGS
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # Turn those extra arguments into do-nothing targets so Make doesn't complain
  $(eval $(ARGS):;@:)
  $(eval .PHONY: $(ARGS))
endif
nvim: .env
	nvim --noplugin $(ARGS)

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
