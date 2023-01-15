CONFIG		:=	$(HOME)/.config/

VIM 		:=	$(addprefix ${CONFIG}, $(wildcard nvim/* nvim/**/*))
ZSH		:=	$(addprefix ${CONFIG}, $(wildcard zsh/*))
ZSH_CONFIG	:=	${HOME}/.zshrc
GIT		:=	${HOME}/.gitconfig
BREW		:=	$(HOME)/Brewfile
BREW_ENV	:=	$(HOME)/.brewenv
MAC		:=	$(CONFIG)mac/install.sh
NODE		:=	$(CONFIG)node/globals

CREATE_TARGET_DIR=	if [ ! -d "$(@D)" ]; then echo "Directory $(@D) was not found, creating..." && mkdir -p "$(@D)";fi;

.PHONY: all mac brew git vim

all:| mac brew zsh git node vim;

.SECONDEXPANSION:
$(VIM): $$(subst ${CONFIG},, $$@)
	@$(call CREATE_TARGET_DIR)
	@if [ ! -d $< ]; then 					 \
		echo "Including ${^} configuration to ${@}" 	;\
 		cp $< $@					;\
	fi							 

.SECONDEXPANSION:
$(ZSH): $$(subst ${CONFIG},, $$@)
	@$(call CREATE_TARGET_DIR)
	@echo "Including ${^} configuration to ${@}"
	@cp "${^}" "${@}"
	@if [ "${@F}" = "_setup.sh" ] ; then 	 \
		${@} "${HOME}" "${CONFIG}" 	;\
	else 					 \
		file="source '${CONFIG}${^}';" &&\
		(                                \
			grep "$${file}" ${ZSH_CONFIG} -q || echo "$${file}" >> ${ZSH_CONFIG} \
		) ;                              \
	fi

$(MAC): mac/install.sh
	@$(call CREATE_TARGET_DIR)
	@cp ${^} ${@}
	@${@}

$(GIT): $(wildcard git/*) 
	@(./git/install.sh ./git/.gitconfig) || :

$(BREW): $(wildcard brew/*)
	@./brew/install.sh
	@cp ./brew/Brewfile ${HOME}/Brewfile
	@source ${BREW_ENV} 								&&\
	($${HOMEBREW_PREFIX}/bin/brew bundle --file ${HOME}/Brewfile --force) || :	&&\
	(./brew/_setup.sh) || :

$(NODE): node/globals
	@xargs -I {} -n 4 npm install {} --global < "${^}"
	@mkdir -p "${@}"
	@cp "${^}" "${@}"

vim:  $(VIM)
git:  $(GIT)
brew: $(BREW)
mac:  $(MAC)
node: $(NODE)
zsh:  $(ZSH)

node/globals: ;
mac/install: ;
