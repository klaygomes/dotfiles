.PHONY: all

CONFIG=$(HOME)/.config/

VIM_FILE=$(CONFIG)nvim/init.vim

all: $(VIM_FILE)


$(CONFIG)%:
	@echo "Directory $@ was not found, creating..."
	@mkdir -p $@

.SECONDEXPANSION:
$(VIM_FILE): $(PWD)/vim/vimrc $$(@D)
	@cp $< $@ 
	@echo "NVIM Configuration created"
