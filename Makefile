# run busted-style tests via plenary's test harness
#   https://lunarmodules.github.io/busted/
#   https://github.com/nvim-lua/plenary.nvim?tab=readme-ov-file#plenarytest_harness
test:
	echo "===> Testing"
	nvim --headless --noplugin -u scripts/tests/minimal.vim \
        -c "PlenaryBustedDirectory lua/vimstory/tests/ {minimal_init = 'scripts/tests/minimal.vim'}"
