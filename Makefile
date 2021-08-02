.PHONY: all

CONFIG		:=	$(HOME)/.config/
VIM 		:=	$(CONFIG)nvim/init.vim
ZSH		:=	$(wildcard zsh/*.sh)

all: $(addprefix ${CONFIG}, ${ZSH}) $(VIM)

$(CONFIG)%:
	@echo "Directory $@ was not found, creating..."
	@mkdir -p $@

.SECONDEXPANSION:
$(VIM): $(PWD)/vim/init.vim $$(@D)
	@cp $< $@ 
	@echo "Neo VIM Configuration created"

.SECONDEXPANSION:
$(addprefix ${CONFIG}, ${ZSH}): zsh/$$(@F) | $$(@D)
	@echo "Including ${^} configuration to ${@}"
	@cp "${^}" "${@}"
	@file="source '${CONFIG}${^}'"  && ( grep -qF "${file}" ~/.zshrc || echo "${file}" >> ~/.zshrc )
