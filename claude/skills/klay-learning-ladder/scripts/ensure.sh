#!/usr/bin/env bash
set -euo pipefail

HOME_DIR="${LEARNING_LADDER_HOME:-$HOME/.local/share/klay-learning-ladder}"

REPOS=(
  "diagram-design https://github.com/cathrynlavery/diagram-design.git 0cf73c3fcc56667ad91a9a04c439ac6ccfabc9d1"
  "motionmaxxing https://github.com/Tejashmakwana/motionmaxxing.git 8c8ec0f2a6f6c9a0da15cd24f7b1298ab298368c"
  "iwrzwr-visual-archive https://github.com/kaganin/iwrzwr-visual-archive.git 794af320e89ebb1db545de5a977ad4cfda3628f0"
  "img2threejs https://github.com/img2threejs/img2threejs.git 3e7099e1b7fe93e187e06db4bdbe1e1906c21a28"
)

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing dependency: $1 ($2)" >&2; exit 1; }; }
want() { command -v "$1" >/dev/null 2>&1 || echo "warning: $1 missing, $3 will not work ($2)" >&2; }

need git "xcode-select --install"
need node "nvm install 22"
need python3 "brew install python@3.12"
want ffmpeg "brew install ffmpeg" "stage 4 (video)"

if command -v ffmpeg >/dev/null 2>&1 && ! ffmpeg -hide_banner -filters 2>/dev/null | grep -q " drawtext "; then
  echo "note: ffmpeg has no drawtext filter; scripts/look.sh works around it" >&2
fi

node -e 'process.exit(+process.versions.node.split(".")[0] >= 22 ? 0 : 1)' \
  || { echo "node >= 22 required (nvm install 22)" >&2; exit 1; }

[ -d "/Applications/Google Chrome.app" ] || command -v google-chrome >/dev/null 2>&1 \
  || echo "warning: Chrome missing, stage 4 rendering will not work" >&2

mkdir -p "$HOME_DIR"
for entry in "${REPOS[@]}"; do
  read -r name url sha <<<"$entry"
  dir="$HOME_DIR/$name"
  if [ "$(git -C "$dir" rev-parse HEAD 2>/dev/null)" != "$sha" ]; then
    echo "fetching $name@${sha:0:7} into $dir" >&2
    rm -rf "$dir"
    git init --quiet "$dir"
    git -C "$dir" remote add origin "$url"
    git -C "$dir" fetch --quiet --depth 1 origin "$sha"
    git -C "$dir" -c advice.detachedHead=false checkout --quiet FETCH_HEAD
  fi
  key=$(echo "$name" | tr 'a-z-' 'A-Z_')
  echo "${key}=$dir"
done
echo "DIAGRAM_SKILL=$HOME_DIR/diagram-design/skills/diagram-design"
echo "LADDER_SKILL=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TEMML_VERSION=0.14.0
if [ "$(node -p "try{require('$HOME_DIR/node/node_modules/temml/package.json').version}catch(e){''}" 2>/dev/null)" != "$TEMML_VERSION" ]; then
  echo "installing temml@$TEMML_VERSION into $HOME_DIR/node" >&2
  mkdir -p "$HOME_DIR/node"
  [ -f "$HOME_DIR/node/package.json" ] || echo '{"private":true}' > "$HOME_DIR/node/package.json"
  npm install --silent --save-exact --prefix "$HOME_DIR/node" "temml@$TEMML_VERSION" >/dev/null
fi

if command -v agent-voice >/dev/null 2>&1; then
  echo "AGENT_VOICE=$(command -v agent-voice)"
else
  echo "note: agent-voice missing; stages 1 and 4 need it: uv tool install git+https://github.com/klaygomes/agent-voice@v0.1.0 (or a local checkout: uv tool install ~/personal/agent-voice)" >&2
fi
