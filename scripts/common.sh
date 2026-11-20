# Shared helpers for GrokBot Notch scripts. Source this file; do not execute it.
# shellcheck shell=bash

notch_support_dir() {
  printf '%s\n' "${HOME}/Library/Application Support/GrokBot Notch"
}

notch_pid_file() {
  printf '%s\n' "$(notch_support_dir)/server.pid"
}

# Expand a leading ~ so GROKBOT_NODE_BIN=~/.local/bin/node works.
expand_user_path() {
  local raw="$1"
  if [ "$raw" = "~" ]; then
    printf '%s\n' "$HOME"
    return
  fi
  if [ "${raw#"${HOME}/"}" != "$raw" ]; then
    printf '%s\n' "$raw"
    return
  fi
  case "$raw" in
    ~/*) printf '%s\n' "${HOME}/${raw#~/}" ;;
    *) printf '%s\n' "$raw" ;;
  esac
}

# Prefer an explicit override, then well-known install locations (menu-bar apps
# often have a minimal PATH), then whatever `node` is on PATH.
resolve_node_bin() {
  local candidate override
  if [ -n "${GROKBOT_NODE_BIN:-}" ]; then
    override="$(expand_user_path "$GROKBOT_NODE_BIN")"
    if [ -x "$override" ]; then
      printf '%s\n' "$override"
      return 0
    fi
    echo "[warn] GROKBOT_NODE_BIN is set but not executable: $override" >&2
  fi
  for candidate in \
    "$HOME/.local/bin/node" \
    /opt/homebrew/bin/node \
    /usr/local/bin/node \
    "$HOME/.nvm/current/bin/node" \
    "$HOME/.volta/bin/node" \
    "$HOME/.local/share/fnm/aliases/default/bin/node"
  do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  if command -v node >/dev/null 2>&1; then
    command -v node
    return 0
  fi
  return 1
}

# Stop the loopback bridge recorded in the PID file. SIGTERM first; SIGKILL only
# if that same PID is still our server.mjs after a short wait. Never kill by port.
stop_bridge_server() {
  local pid_file old_pid args
  pid_file="$(notch_pid_file)"
  if [ ! -f "$pid_file" ]; then
    return 0
  fi
  old_pid="$(tr -d '[:space:]' < "$pid_file" || true)"
  rm -f "$pid_file"
  if [ -z "$old_pid" ] || ! [[ "$old_pid" =~ ^[0-9]+$ ]]; then
    return 0
  fi
  if [ "$old_pid" -eq 1 ] || [ "$old_pid" -eq "$$" ]; then
    return 0
  fi
  if ! kill -0 "$old_pid" 2>/dev/null; then
    return 0
  fi
  args="$(ps -p "$old_pid" -o args= 2>/dev/null || true)"
  case "$args" in
    *server.mjs*) ;;
    *)
      echo "[launch] PID $old_pid is not the GrokBot Notch bridge; leaving it alone." >&2
      return 0
      ;;
  esac
  echo "[launch] Stopping bridge PID $old_pid..."
  kill -TERM "$old_pid" 2>/dev/null || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if ! kill -0 "$old_pid" 2>/dev/null; then
      return 0
    fi
    sleep 0.2
  done
  echo "[launch] Bridge PID $old_pid did not exit after SIGTERM; sending SIGKILL." >&2
  kill -KILL "$old_pid" 2>/dev/null || true
}

# Ask the running Notch app to quit. Falls back to SIGTERM on the exact
# process name (not pkill -f).
quit_notch_app() {
  local pids
  pids="$(pgrep -x GrokBotNotch || true)"
  if [ -z "$pids" ]; then
    return 0
  fi
  osascript -e 'tell application "GrokBot Notch" to quit' >/dev/null 2>&1 || true
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    pgrep -x GrokBotNotch >/dev/null 2>&1 || return 0
    sleep 0.2
  done
  pids="$(pgrep -x GrokBotNotch || true)"
  if [ -n "$pids" ]; then
    echo "[launch] GrokBotNotch did not quit; sending SIGTERM to PID(s) $pids"
    # shellcheck disable=SC2086
    kill -TERM $pids 2>/dev/null || true
  fi
}

# /Applications if writable without sudo, otherwise ~/Applications.
choose_install_dir() {
  if [ -w /Applications ]; then
    printf '%s\n' "/Applications"
    return 0
  fi
  mkdir -p "${HOME}/Applications"
  printf '%s\n' "${HOME}/Applications"
}

install_app_bundle() {
  local src="$1"
  local dest_dir dest
  if [ ! -d "$src" ]; then
    echo "[error] App bundle not found: $src" >&2
    return 1
  fi
  dest_dir="$(choose_install_dir)"
  dest="${dest_dir}/GrokBot Notch.app"
  echo "[setup] Installing GrokBot Notch.app to ${dest_dir} (no sudo)..."
  if ! rm -rf "$dest" 2>/dev/null || ! cp -R "$src" "$dest" 2>/dev/null; then
    if [ "$dest_dir" = "/Applications" ]; then
      echo "[setup] /Applications is not writable; installing to ~/Applications instead."
      dest_dir="${HOME}/Applications"
      mkdir -p "$dest_dir"
      dest="${dest_dir}/GrokBot Notch.app"
      rm -rf "$dest"
      cp -R "$src" "$dest"
    else
      echo "[error] Could not install to $dest" >&2
      return 1
    fi
  fi
  echo "[ok] Installed to $dest"
}
