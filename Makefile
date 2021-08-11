CONFIG		:=	$(HOME)/.config/

VIM 		:=	$(addprefix ${CONFIG}, $(wildcard nvim/**/*))
ZSH		:=	$(addprefix ${CONFIG}, $(wildcard zsh/*))
GIT		:=	${HOME}/.gitconfig
BREW		:=	$(HOME)/Brewfile
MAC		:=	$(CONFIG)configure.sh

.PHONY: all mac brew git vim

all: mac brew zsh git vim;

$(CONFIG)%:
	@echo "Directory $@ was not found, creating..."
	@mkdir -p $@

.SECONDEXPANSION:
$(VIM): $$(subst ${CONFIG},, $$@) | $$(@D)
	echo $(VIM)	
	@if [ ! -d $< ]; then cp $< $@ ; fi
	@echo "Including ${^} configuration to ${@}"

.SECONDEXPANSION:
$(ZSH): $$(subst ${CONFIG},, $$@) | $$(@D)
	@echo "Including ${^} configuration to ${@}"
	@cp "${^}" "${@}"
	file="source '${CONFIG}${^}'" &&  (grep "$${file}" ${HOME}/.zshrc -q || echo "$${file}" >> ${HOME}/.zshrc)

$(GIT): $(wildcard git/*) 
	@./git/install.sh ./git/.gitconfig

$(BREW): $(wildcard brew/*)
	@./brew/install.sh
	@cp ./brew/Brewfile ${HOME}/Brewfile
	@/opt/homebrew/bin/brew bundle --file ${HOME}/Brewfile 

$(MAC): mac/configure.sh
	@cp ${^} ${@}
	@chmod +x "${@}"
	@${@}

mac/configure.sh: ;
vim: $(VIM)
git: $(GIT)
brew: $(BREW)
mac: $(MAC)
zsh: $(ZSH)
