CONFIG_PATH   ?= ${HOME}/.config/
BIN_PATH      ?= ${HOME}/bin/
CLAUDE_PATH   ?= ${HOME}/.claude/
LAUNCH_AGENTS ?= ${HOME}/Library/LaunchAgents/

VIM         := $(addprefix ${CONFIG_PATH}, $(shell find nvim    -type f))
ZSH         := $(addprefix ${CONFIG_PATH}, $(shell find zsh     -type f))
GHOSTTY     := $(addprefix ${CONFIG_PATH}, $(shell find ghostty -type f))
TMUX        := $(addprefix ${CONFIG_PATH}, $(shell find tmux    -type f))
RANGER      := $(addprefix ${CONFIG_PATH}, $(shell find ranger  -type f))
BAT         := $(addprefix ${CONFIG_PATH}, $(shell find bat     -type f))
BIN         := $(addprefix ${BIN_PATH},    $(shell find bin -type f | sed 's|^bin/||'))
MAC         := $(CONFIG_PATH)mac/setup.sh
GIT         := ${HOME}/.gitconfig
BREW        := $(HOME)/Brewfile
NODE        := $(CONFIG_PATH)/node/globals
TASKWARRIOR := $(CONFIG_PATH)task/taskrc

SKILLS := klay-meeting-search klay-worktree klay-verify-before-done klay-manage-git-worktrees \
          klay-prove-dont-speculate klay-review-pr shared klay-plan-reviewer

CREATE_TARGET_DIR = if [ ! -d "$(@D)" ]; then mkdir -p "$(@D)" && echo "'$(@D)' created."; fi;

define LINK_CONFIG
@$(call CREATE_TARGET_DIR)
@if [ ! -d $< ]; then \
	echo "Including '${^}' configuration to '${@}'";\
	ln -sf "$(CURDIR)/$<" "$@";\
fi
endef

.PHONY: ghostty vim zsh mac brew git node tmux ranger bat bin launchd claude skills taskwarrior plan-reviewer all help
.SECONDEXPANSION:
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

vim: $(VIM) ;@ ## Install neovim configuration
$(VIM): $$(subst ${CONFIG_PATH},, $$@)
	$(LINK_CONFIG)

ghostty: $(GHOSTTY) ;@ ## Install ghostty configuration
$(GHOSTTY): $$(subst ${CONFIG_PATH},, $$@)
	$(LINK_CONFIG)

bat: $(BAT) ;@ ## Install bat configuration
$(BAT): $$(subst ${CONFIG_PATH},, $$@)
	$(LINK_CONFIG)

ranger: $(RANGER) ;@ ## Install ranger configuration
$(RANGER): $$(subst ${CONFIG_PATH},, $$@)
	$(LINK_CONFIG)

tmux: $(TMUX) ## Install tmux configuration
	@./tmux/install.sh
$(TMUX): $$(subst ${CONFIG_PATH},, $$@)
	$(LINK_CONFIG)

zsh: $(ZSH) ;@ ## Configure zsh default alias, functions and etc.
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

mac: $(MAC) ;@ ## Configure mac settings
$(MAC): $$(subst ${CONFIG_PATH},, $$@)
	@$(call CREATE_TARGET_DIR)
	@ln -sf "$(CURDIR)/${^}" ${@}
	@${@} || :

brew: $(BREW) ;@ ## Install brew packages
$(BREW): brew/Brewfile
	@ln -sf "$(CURDIR)/$(^)" $(@)
	@./brew/install.sh
	@source ./brew/shellenv.sh && brew bundle cleanup --force --file=$(@); brew bundle --file=$(@) --force && ./brew/setup.sh

git: $(GIT); ## Install git configuration
$(GIT): $(wildcard git/*)
	@source ./git/setup.sh || :

node: $(NODE) ;@ ## Install nvm, node lts and global packages
$(NODE): node/globals
	@./node/install.sh
	@mkdir -p "$(@D)"
	@ln -sf "$(CURDIR)/${^}" "${@}"

bin: $(BIN) ;@ ## Install bin scripts to ~/bin
$(BIN): $$(addprefix bin/, $$(notdir $$@))
	@$(call CREATE_TARGET_DIR)
	@echo "Including '${^}' to '${@}'"
	@ln -sf "$(CURDIR)/${^}" "${@}"
	@chmod +x "${@}"

launchd: ;@ ## Install and load launchd agents
	@mkdir -p ${LAUNCH_AGENTS}
	@for plist in $(CURDIR)/launchd/*.plist; do \
		name=$$(basename $$plist); \
		ln -sf "$$plist" "${LAUNCH_AGENTS}$$name"; \
		launchctl load -w "${LAUNCH_AGENTS}$$name" 2>/dev/null || true; \
		echo "Loaded $$name"; \
	done

claude: ;@ ## Install Claude Code settings (symlinks into ~/.claude)
	@mkdir -p ${CLAUDE_PATH}
	@ln -sf "$(CURDIR)/claude/settings.local.json" "${CLAUDE_PATH}settings.local.json"
	@chmod +x "$(CURDIR)/scripts/claude-statusline.sh"
	@[ -f "${CLAUDE_PATH}settings.json" ] || echo '{}' > "${CLAUDE_PATH}settings.json"
	@for patch in $(CURDIR)/claude/settings.*.json; do \
		jq -s '.[0] * .[1]' "${CLAUDE_PATH}settings.json" "$$patch" > /tmp/claude-settings-merged.json \
		&& mv /tmp/claude-settings-merged.json "${CLAUDE_PATH}settings.json" \
		&& echo "Applied $$(basename $$patch)"; \
	done

taskwarrior: $(TASKWARRIOR) ;@ ## Install taskwarrior configuration
$(TASKWARRIOR): taskwarrior/taskrc
	@$(call CREATE_TARGET_DIR)
	@echo "Including 'taskwarrior/taskrc' to '$(TASKWARRIOR)'"
	@ln -sf "$(CURDIR)/taskwarrior/taskrc" "$(TASKWARRIOR)"

plan-reviewer: ;@ ## Build plan-reviewer tool and install to ~/bin
	@echo "Building plan-reviewer..."
	@export NVM_DIR="$$HOME/.nvm" && \. "$$NVM_DIR/nvm.sh" && \
		cd tools/plan-reviewer && nvm install && nvm use && npm install && npm run build
	@ln -sf "$(CURDIR)/tools/plan-reviewer/dist/cli.js" "${BIN_PATH}plan-reviewer"
	@chmod +x "${BIN_PATH}plan-reviewer"
	@echo "plan-reviewer installed to ${BIN_PATH}plan-reviewer"

skills: ;@ ## Install Claude Code skills (symlinks into ~/.claude/skills)
	@mkdir -p ${HOME}/.claude/skills
	@for skill in $(SKILLS); do \
		ln -sf "$(CURDIR)/skills/$$skill" "${HOME}/.claude/skills/$$skill"; \
	done
	@chmod +x "$(CURDIR)/skills/klay-meeting-search/tools/query.py"
	@[ -f "$(CURDIR)/.env" ] || cp "$(CURDIR)/.env.example" "$(CURDIR)/.env"
	@echo "Skills installed"

all: ;@ ## Run all configurations
	@for target in mac zsh brew node git vim tmux ranger bat bin launchd claude skills taskwarrior plan-reviewer; do \
		echo "Running $$target..."; \
		$(MAKE) $$target || echo "Warning: $$target failed, continuing..."; \
	done

# https://michaelgoerz.net/notes/self-documenting-makefiles.html
help: ## Show this help
	@echo "$$PRINT_HELP_PROLOGUE"
	@grep -E '^([a-zA-Z_-]+):.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{gsub(/^[ \t]+/, "", $$2);printf "| %-19s| %-55s|\n", $$1, $$2}'
	@printf "+%20s+%-56s+\n" | tr ' ' '-'
