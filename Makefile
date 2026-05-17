-include .env
export

# Run all test files
test: .env
	nvim --headless --noplugin -u scripts/nvim/init.lua -c "lua MiniTest.run()"
.PHONY: test

# Run test from file at `$FILE` environment variable
test_file: .env
	nvim --headless --noplugin -c "lua MiniTest.run_file('$(FILE)')"
.PHONY: test_file

# Run tests interactively
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
