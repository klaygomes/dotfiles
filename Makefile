CONFIG_PATH	?=	${HOME}/.config/

VIM 		:=	$(addprefix ${CONFIG_PATH}, $(shell find nvim -type f -print))
ZSH			:=	$(addprefix ${CONFIG_PATH}, $(shell find zsh -type f -print))
MAC			:=	$(CONFIG_PATH)mac/setup.sh

GIT			:=	${HOME}/.gitconfig
BREW		:=	$(HOME)/Brewfile
NODE		:=	$(CONFIG_PATH)/node/globals


# helper function to create target directory
CREATE_TARGET_DIR=	if [ ! -d "$(@D)" ]; then mkdir -p "$(@D)" && echo "'$(@D)' created.";fi;

.PHONY: vim zsh mac brew git node help
.DEFAULT_GOAL := help

define PRINT_HELP_PROLOGUE
+-----------------------------------------------------------------------------+
|              This Makefile should work in most shell environments.          | 
|             But it was only tested on Mac running with Apple sillicon.      |
+--------------------+--------------------------------------------------------+
| commands:          | description:                                           |    
+--------------------+--------------------------------------------------------+
endef
export PRINT_HELP_PROLOGUE

## The following lines
vim:  $(VIM) ;@ ##     Install neovim configuration
.SECONDEXPANSION:
$(VIM): $$(subst ${CONFIG_PATH},, $$@)
	@$(call CREATE_TARGET_DIR)
	@if [ ! -d $< ]; then												 \
		echo "Including '${^}' configuration to '${@}'"					;\
		cp $< $@														;\
	fi
## The following lines
zsh: $(ZSH) ;@ ## Configure zsh default alias, functions and etc.
.SECONDEXPANSION:
$(ZSH): $$(subst ${CONFIG_PATH},, $$@)
	@$(call CREATE_TARGET_DIR)
	@printf "Moving '${^F}' to '${@}'"
	@cp "${^}" "${@}"
	@. zsh/functions.sh && inject '${CONFIG_PATH}${^}'						\
		&& echo " - injected"												\
		|| echo " - already injected"

## The following lines
mac: $(MAC) ;@ ## Configure mac settings
$(MAC): $$(subst ${CONFIG_PATH},, $$@)
	@$(call CREATE_TARGET_DIR)
	@cp -f ${^} ${@}
	@${@} || : 

## The following lines
brew: $(BREW);@ ## Install brew packages
$(BREW): brew/Brewfile
	@cp -f $(^) $(@)
	@./brew/install.sh
	@source ./brew/shellenv.sh && brew bundle --file=$(@) --force && ./setup.sh

## The following lines
git: $(GIT); ## Install git configuration
$(GIT): $(wildcard git/*) 
	@source ./git/setup.sh || :

## The following lines
node: $(NODE);@ ## Install nvm, node lts and global packages
$(NODE): node/globals
	@./node/install.sh
	@mkdir -p "${@}"
	@cp -f "${^}" "${@}"

## Install all configurations
all: | mac zsh brew node git vim

# https://michaelgoerz.net/notes/self-documenting-makefiles.html
help:  ## Show this help
	@echo "$$PRINT_HELP_PROLOGUE"
	@grep -E '^([a-zA-Z_-]+):.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{gsub(/^[ \t]+/, "", $$2);printf "| %-19s| %-55s|\n", $$1, $$2}'
	@printf "+%20s+%-56s+\n" | tr ' ' '-'
