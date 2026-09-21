echo "Retire the Hermes that mise built; Hermes now updates itself"

# Hermes installs the way Hermes Desktop does now: upstream's installer makes a checkout under ~/.hermes that `hermes update` fast-forwards. The wrapper that built Hermes through mise had nothing an update could move, so it goes, with the mise environment it built. Only the wrapper Omarchy wrote proves that environment is Omarchy's to remove; a hermes the user set up themselves, and a mise environment without the wrapper, stay as they are.
wrapper="$HOME/.local/bin/hermes"
marker='# Written by omarchy-install-hermes-cli.'
tool='pipx:hermes-agent[extras=all]'

omarchy_wrapper() {
  [[ -f $1 && ! -L $1 ]] && grep -qxF "$marker" "$1"
}

# The proof is the wrapper at its path, or a copy of it the runtime installer saved aside before upstream's installer took the name: a user who chose Hermes before this ran has the wrapper there and the environment still requested.
owned=false
if omarchy_wrapper "$wrapper"; then
  owned=true
else
  for saved in "$HOME/.local/bin"/.hermes-before-desktop.*/hermes; do
    if omarchy_wrapper "$saved"; then
      owned=true
      break
    fi
  done
fi

# Gone means neither installed nor still asked for in the global config, where `mise up` would build it again. `mise rm -g` exits 0 whether or not it removed anything, so the listing is read instead, and a listing that cannot be read -- mise broken, or not there to read it -- is not an answer; the key carries the backend and name, with or without the options.
retired() {
  local requested
  requested=$(mise ls -g --json 2>/dev/null) || return 1
  ! mise where "$tool" >/dev/null 2>&1 && ! grep -qF '"pipx:hermes-agent' <<<"$requested"
}

if [[ $owned == "true" ]]; then
  # The environment goes before the wrapper, and is judged by what is left rather than by what the commands claimed: once the wrapper is gone nothing marks the environment as Omarchy's, so a rerun could not finish what a failed removal left behind.
  if ! retired; then
    mise rm -g "$tool" >/dev/null 2>&1 || true
    mise uninstall --all "$tool" >/dev/null 2>&1 || true
    if ! retired; then
      echo "Could not remove the Hermes that mise built. Finish by hand, then run omarchy-migrate:" >&2
      if omarchy-cmd-missing mise; then
        echo "  omarchy pkg add mise" >&2
      fi
      echo "  mise rm -g '$tool'" >&2
      echo "  mise uninstall --all '$tool'" >&2
      exit 1
    fi
  fi
  if omarchy_wrapper "$wrapper"; then
    rm -f "$wrapper"
  fi
fi

# Choosing Hermes again is what installs the runtime, and nothing else will.
if [[ $(omarchy-default-agent) == "hermes" ]] && ! omarchy-install-hermes-cli --check; then
  echo "Hermes is the default agent but is no longer installed. Choose it again under Setup > Default Agent, or run: omarchy default agent hermes"
fi
