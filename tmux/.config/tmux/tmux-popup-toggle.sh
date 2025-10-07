#!/usr/bin/env bash
# Persistente Popup-Session + Path-Sync beim Öffnen.

PARENT_SESSION="$(tmux display -p '#S')"
POPUP_SESSION="_popup_${PARENT_SESSION}"

# Pfad des aufrufenden Panes (wo du C-g drückst)
TARGET_DIR="$(tmux display -p '#{pane_current_path}')"

# Optional: auf Git-Root normalisieren (auskommentieren, falls nicht gewünscht)
# if ROOT="$(git -C "$TARGET_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
#   TARGET_DIR="$ROOT"
# fi

# 1) Session existiert? Falls nein: anlegen (Start im TARGET_DIR).
if ! tmux has-session -t "$POPUP_SESSION" 2>/dev/null; then
  # -dP: detached + gibt ID aus; -c: Startverzeichnis
  SID="$(tmux new-session -dP -s "$POPUP_SESSION" -c "$TARGET_DIR" -F '#{session_id}')"
  # Key-Table für Popup-Controls
  tmux set-option -t "$SID" key-table popup 2>/dev/null
  tmux set-option -t "$SID" status off 2>/dev/null
  tmux set-option -t "$SID" prefix None 2>/dev/null
else
  # 2) Session existiert: ggf. in TARGET_DIR springen
  CURRENT_DIR="$(tmux display -p -t "$POPUP_SESSION":. '#{pane_current_path}')"

  if [ "$CURRENT_DIR" != "$TARGET_DIR" ]; then
    # Aktiver Prozess im Popup?
    CMD="$(tmux display -p -t "$POPUP_SESSION":. '#{pane_current_command}')"
    case "$CMD" in
    zsh | bash | fish | sh | ash | nu)
      # Shell am Prompt -> cd hinschicken
      ESCAPED_TARGET="$(printf '%q' "$TARGET_DIR")"
      tmux send-keys -t "$POPUP_SESSION":. "cd -- $ESCAPED_TARGET && clear" C-m
      ;;
    *)
      # Kein Prompt (z.B. nvim/top): neues Window im Zielpfad erstellen
      NEWW="$(tmux new-window -P -t "$POPUP_SESSION" -c "$TARGET_DIR" -F '#{window_id}')"
      tmux select-window -t "$NEWW"
      ;;
    esac
  fi
fi

# 3) Attach ins Popup (zeigt aktives Window der Popup-Session)
exec tmux attach -t "$POPUP_SESSION"
