CONFIG_PATH	?=	${HOME}/.config/
BIN_PATH	?=	${HOME}/bin/
CLAUDE_PATH	?=	${HOME}/.claude/
LAUNCH_AGENTS	?=	${HOME}/Library/LaunchAgents/

VIM 		:=	$(addprefix ${CONFIG_PATH}, $(shell find nvim -type f -print))
ZSH			:=	$(addprefix ${CONFIG_PATH}, $(shell find zsh -type f -print))
GHOSTTY		:=	$(addprefix ${CONFIG_PATH}, $(shell find ghostty -type f -print))
TMUX		:=	$(addprefix ${CONFIG_PATH}, $(shell find tmux -type f -print))
RANGER		:=	$(addprefix ${CONFIG_PATH}, $(shell find ranger -type f -print))
BAT			:=	$(addprefix ${CONFIG_PATH}, $(shell find bat -type f -print))
BIN			:=	$(addprefix ${BIN_PATH}, $(shell find bin -type f -print | sed 's|^bin/||'))
MAC			:=	$(CONFIG_PATH)mac/setup.sh

GIT			:=	${HOME}/.gitconfig
BREW		:=	$(HOME)/Brewfile
NODE		:=	$(CONFIG_PATH)/node/globals
TASKWARRIOR	:=	$(CONFIG_PATH)task/taskrc


# helper function to create target directory
CREATE_TARGET_DIR=	if [ ! -d "$(@D)" ]; then mkdir -p "$(@D)" && echo "'$(@D)' created.";fi;

.PHONY: ghostty vim zsh mac brew git node tmux ranger bat bin launchd claude skills taskwarrior help
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
		ln -sf "$(CURDIR)/$<" "$@"									    ;\
	fi
ghostty:  $(GHOSTTY) ;@ ##     Install ghostty configuration
.SECONDEXPANSION:
$(GHOSTTY): $$(subst ${CONFIG_PATH},, $$@)
	@$(call CREATE_TARGET_DIR)
	@if [ ! -d $< ]; then												 \
		echo "Including '${^}' configuration to '${@}'"					;\
		ln -sf "$(CURDIR)/$<" "$@"									    ;\
	fi
## The following lines
zsh: $(ZSH) ;@ ## Configure zsh default alias, functions and etc.
.SECONDEXPANSION:
$(ZSH): $$(subst ${CONFIG_PATH},, $$@)
	@$(call CREATE_TARGET_DIR)
	@printf "Moving '${^F}' to '${@}'"
	@ln -sf "$(CURDIR)/${^}" "${@}"
	@. zsh/functions.sh \
		&& ([ "${^F}" = "plugins.sh" ] \
			&& inject --before '${CONFIG_PATH}${^}' \
			|| inject '${CONFIG_PATH}${^}') \
		&& echo " - injected"												\
		|| echo " - already injected"

## The following lines
bat: $(BAT) ;@ ## Install bat configuration
.SECONDEXPANSION:
$(BAT): $$(subst ${CONFIG_PATH},, $$@)
	@$(call CREATE_TARGET_DIR)
	@if [ ! -d $< ]; then												 \
		echo "Including '${^}' configuration to '${@}'"					;\
		ln -sf "$(CURDIR)/$<" "$@"									    ;\
	fi

## The following lines
ranger: $(RANGER) ;@ ## Install ranger configuration
.SECONDEXPANSION:
$(RANGER): $$(subst ${CONFIG_PATH},, $$@)
	@$(call CREATE_TARGET_DIR)
	@if [ ! -d $< ]; then												 \
		echo "Including '${^}' configuration to '${@}'"					;\
		ln -sf "$(CURDIR)/$<" "$@"									    ;\
	fi

## The following lines
tmux: $(TMUX) ## Install tmux configuration
	@./tmux/install.sh
.SECONDEXPANSION:
$(TMUX): $$(subst ${CONFIG_PATH},, $$@)
	@$(call CREATE_TARGET_DIR)
	@if [ ! -d $< ]; then												 \
		echo "Including '${^}' configuration to '${@}'"					;\
		ln -sf "$(CURDIR)/$<" "$@"									    ;\
	fi

## The following lines
mac: $(MAC) ;@ ## Configure mac settings
$(MAC): $$(subst ${CONFIG_PATH},, $$@)
	@$(call CREATE_TARGET_DIR)
	@ln -sf "$(CURDIR)/${^}" ${@}
	@${@} || : 

## The following lines
brew: $(BREW);@ ## Install brew packages
$(BREW): brew/Brewfile
	@ln -sf "$(CURDIR)/$(^)" $(@)
	@./brew/install.sh
	@source ./brew/shellenv.sh && brew bundle cleanup --force --file=$(@); brew bundle --file=$(@) --force && ./brew/setup.sh

## The following lines
git: $(GIT); ## Install git configuration
$(GIT): $(wildcard git/*) 
	@source ./git/setup.sh || :

## The following lines
node: $(NODE);@ ## Install nvm, node lts and global packages
$(NODE): node/globals
	@./node/install.sh
	@mkdir -p "$(@D)"
	@ln -sf "$(CURDIR)/${^}" "${@}"

## The following lines
bin: $(BIN) ;@ ## Install bin scripts to ~/bin
.SECONDEXPANSION:
$(BIN): $$(addprefix bin/, $$(notdir $$@))
	@$(call CREATE_TARGET_DIR)
	@echo "Including '${^}' to '${@}'"
	@ln -sf "$(CURDIR)/${^}" "${@}"
	@chmod +x "${@}"

## The following lines
launchd: ;@ ## Install and load launchd agents
	@mkdir -p ${LAUNCH_AGENTS}
	@for plist in $(CURDIR)/launchd/*.plist; do \
		name=$$(basename $$plist); \
		ln -sf "$$plist" "${LAUNCH_AGENTS}$$name"; \
		launchctl load -w "${LAUNCH_AGENTS}$$name" 2>/dev/null || true; \
		echo "Loaded $$name"; \
	done

## The following lines
claude: ;@ ## Install Claude Code settings (symlinks into ~/.claude)
	@mkdir -p ${CLAUDE_PATH}
	@ln -sf "$(CURDIR)/claude/settings.local.json" "${CLAUDE_PATH}settings.local.json"
	@ln -sf "$(CURDIR)/claude/statusline-command.sh" "${CLAUDE_PATH}statusline-command.sh"
	@chmod +x "$(CURDIR)/claude/statusline-command.sh"
	@if [ -f "${CLAUDE_PATH}settings.json" ]; then \
		jq -s '.[0] * .[1]' "${CLAUDE_PATH}settings.json" "$(CURDIR)/claude/settings.patch.json" > /tmp/claude-settings-merged.json \
		&& mv /tmp/claude-settings-merged.json "${CLAUDE_PATH}settings.json" \
		&& echo "Claude settings patched"; \
	else \
		cp "$(CURDIR)/claude/settings.patch.json" "${CLAUDE_PATH}settings.json" \
		&& echo "Claude settings created"; \
	fi

## The following lines
taskwarrior: $(TASKWARRIOR) ;@ ## Install taskwarrior configuration
$(TASKWARRIOR): taskwarrior/taskrc
	@$(call CREATE_TARGET_DIR)
	@echo "Including 'taskwarrior/taskrc' to '$(TASKWARRIOR)'"
	@ln -sf "$(CURDIR)/taskwarrior/taskrc" "$(TASKWARRIOR)"

## The following lines
skills: ;@ ## Install Claude Code skills (symlinks into ~/.claude/skills)
	@mkdir -p ${HOME}/.claude/skills
	@ln -sf "$(CURDIR)/skills/klay-meeting-search" "${HOME}/.claude/skills/klay-meeting-search"
	@chmod +x "$(CURDIR)/skills/klay-meeting-search/tools/query.py"
	@if [ ! -f "$(CURDIR)/.env" ]; then \
		cp "$(CURDIR)/.env.example" "$(CURDIR)/.env"; \
	fi
	@echo "Skills installed"

## Run all configurations
all: ;@ ## Run all configurations
	@for target in mac zsh brew node git vim tmux ranger bat bin launchd claude skills taskwarrior; do \
		echo "Running $$target..."; \
		$(MAKE) $$target || echo "Warning: $$target failed, continuing..."; \
	done

# https://michaelgoerz.net/notes/self-documenting-makefiles.html
help:  ## Show this help
	@echo "$$PRINT_HELP_PROLOGUE"
	@grep -E '^([a-zA-Z_-]+):.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{gsub(/^[ \t]+/, "", $$2);printf "| %-19s| %-55s|\n", $$1, $$2}'
	@printf "+%20s+%-56s+\n" | tr ' ' '-'
