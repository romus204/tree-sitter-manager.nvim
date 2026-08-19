# Capture extra arguments after `make test`, `make test_xxx` and `make nvim`
ifneq (,$(filter test test_% nvim,$(firstword $(MAKECMDGOALS))))
    ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    $(eval $(ARGS):;@:)
    $(eval .PHONY: $(ARGS))
endif

export XDG_CONFIG_HOME := $(CURDIR)/scripts
export XDG_DATA_HOME   := $(CURDIR)/scripts
export XDG_STATE_HOME  := $(CURDIR)/scripts
export LANGUAGES := $(ARGS)

# `make test` to run tests for all modules for a handful of languages
# `make test python` to run all tests for python
# `make test all` to run all tests for all languages
.PHONY: test
test: deps/mini.nvim
	nvim --headless --noplugin -c "lua MiniTest.run()"

.PHONY: update-parsers
update-parsers: deps/mini.nvim
	nvim --headless --noplugin -c "lua require('parser-updater').update()"

# `make test_xxx` to run tests for module `tests/test_xxx.lua`
# `make test_xxx python` will run it for python
# `make test_xxx all` to run for all languages
TEST_MODULES = $(basename $(notdir $(wildcard tests/test_*.lua)))
.PHONY: $(TEST_MODULES)
$(TEST_MODULES): deps/mini.nvim
	nvim --headless --noplugin -c "lua MiniTest.run_file('tests/$@.lua')"

# Use `make nvim` or `make nvim tests/test_xxx.lua`
.PHONY: nvim
nvim: deps/mini.nvim
	nvim --noplugin -o $(ARGS)

ifeq ($(OS),Windows_NT)
  MKDIR = if not exist "$(1)" mkdir "$(1)"
else
  MKDIR = mkdir -p "$(1)"
endif

# Download 'mini.nvim' to use its 'mini.test' testing module
deps/mini.nvim:
	$(call MKDIR,deps)
	git clone --filter=blob:none https://github.com/nvim-mini/mini.nvim $@

# Update 'mini.nvim'
.PHONY: update
update: deps/mini.nvim
	git -C deps/mini.nvim pull

ifeq ($(OS),Windows_NT)
  RM = rmdir /s /q
else
  RM = rm -rf
endif

# Clean up artifacts
.PHONY: clean
clean:
	$(RM) deps
	$(RM) scripts/nvim/shada
	$(RM) scripts/nvim/site
	$(RM) scripts/nvim/swap
	$(RM) scripts/nvim/tests
	$(RM) $(wildcard scripts/nvim/*.json)
	$(RM) $(wildcard scripts/nvim/*.log)
