# Run all test files
test: build
	nvim --headless --noplugin -u ./scripts/nvim/init.lua -c "lua MiniTest.run()"
.PHONY: test

# Run test from file at `$FILE` environment variable
test_file: build
	nvim --headless --noplugin -u ./scripts/nvim/init.lua -c "lua MiniTest.run_file('$(FILE)')"
.PHONY: test_file

# Set up test environment
build: deps/mini.nvim
.PHONY: build

# Download 'mini.nvim' to use its 'mini.test' testing module
deps/mini.nvim:
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/nvim-mini/mini.nvim $@
