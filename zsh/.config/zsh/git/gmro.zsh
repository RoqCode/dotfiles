gmro() {
  emulate -L zsh
  setopt localoptions pipefail no_aliases

  # --- Checks & Setup (wie zuvor) ---
  for cmd in curl jq fzf; do
    command -v "$cmd" >/dev/null 2>&1 || { print -u2 "Fehler: '$cmd' nicht gefunden"; return 1; }
  done
  local TOKEN="${GL_TOKEN:-${GITLAB_TOKEN:-}}"
  [[ -n "$TOKEN" ]] || { print -u2 "Fehler: Setze GL_TOKEN oder GITLAB_TOKEN"; return 1; }

  # YAML laden (yq) – wie in deinem Snippet
  local GL_HOST="gitlab.com" PROJECT_PATH="" TARGET_BRANCH=""
  local CONFIG_PATH=""
  if [[ -f ".gitlab/mr-config.yml" ]]; then CONFIG_PATH=".gitlab/mr-config.yml"
  elif [[ -f "mr-config.yml" ]]; then CONFIG_PATH="mr-config.yml"; fi
  if [[ -n "$CONFIG_PATH" && -x "$(command -v yq)" ]]; then
    print "[INFO]  using config: $CONFIG_PATH"
    local CFG_GL_HOST CFG_PROJECT_PATH CFG_TARGET_BRANCH
    CFG_GL_HOST="$(yq -r '.gl_host // ""' "$CONFIG_PATH" 2>/dev/null)"
    CFG_PROJECT_PATH="$(yq -r '.project_path // ""' "$CONFIG_PATH" 2>/dev/null)"
    CFG_TARGET_BRANCH="$(yq -r '.default_target_branch // ""' "$CONFIG_PATH" 2>/dev/null)"
    [[ -n "$CFG_GL_HOST" ]] && GL_HOST="$CFG_GL_HOST"
    [[ -n "$CFG_PROJECT_PATH" && -z "${PROJECT_PATH:-}" ]] && PROJECT_PATH="$CFG_PROJECT_PATH"
    [[ -n "$CFG_TARGET_BRANCH" ]] && TARGET_BRANCH="$CFG_TARGET_BRANCH"
  fi

  local GITLAB_API_BASE="${GITLAB_API_BASE:-https://${GL_HOST}/api/v4}"

  # PROJECT_ID auflösen (Arg > ENV > project_path)
  local PROJECT_ID_RESOLVED="${1:-${PROJECT_ID:-}}"
  if [[ -z "$PROJECT_ID_RESOLVED" && -n "$PROJECT_PATH" ]]; then
    local ENC_PATH proj_resp
    if command -v python3 >/dev/null 2>&1; then
      ENC_PATH="$(python3 - "$PROJECT_PATH" <<'PY'
import sys, urllib.parse
print(urllib.parse.quote(sys.argv[1], safe=''))
PY
)"
    else
      ENC_PATH="${PROJECT_PATH//\//%2F}"
    fi
    if proj_resp="$(curl -fsS -H "PRIVATE-TOKEN: $TOKEN" "$GITLAB_API_BASE/projects/$ENC_PATH")"; then
      PROJECT_ID_RESOLVED="$(jq -r '.id // empty' <<<"$proj_resp")"
    fi
  fi
  local PROJECT_ID="${PROJECT_ID_RESOLVED:-71831547}"

  # --- Daten holen ---
  local resp
  if ! resp="$(
    curl -fsS -H "PRIVATE-TOKEN: $TOKEN" \
      "$GITLAB_API_BASE/projects/$PROJECT_ID/merge_requests?state=opened&order_by=updated_at&sort=desc&per_page=100"
  )"; then
    print -u2 "Fehler beim Abrufen der MRs (Projekt $PROJECT_ID)."
    return 1
  fi
  [[ "$(jq 'length' <<<"$resp")" -gt 0 ]] || { print "Keine offenen MRs gefunden (Projekt $PROJECT_ID)."; return 0; }

  # --- Anzeige: zweizeilig + Preview ---
  # Feld 1: sichtbarer Block (2 Zeilen)
  #   Zeile 1: [author]  Titel
  #   Zeile 2: ref • source→target • updated • status
  # Feld 2: URL (für Öffnen)
  # Feld 3: komplettes JSON (für Preview)
  local nul_records
  nul_records="$(
    jq -r '
      .[] |
      . as $it |
      (("[" + (.author.username // "unknown") + "] ") + .title) as $line1 |
      (
        (.references.full // ("!" + (.iid|tostring))) + " • " +
        .source_branch + "→" + .target_branch + " • " +
        ((.updated_at | sub("T"; " "; "g") | sub("Z$"; ""; "g"))) + " • " +
        (.detailed_merge_status // "")
      ) as $line2 |
      ($line1 + "\n" + $line2) + "\t" + (.web_url) + "\t" + (.|tojson) + "\u0000"
    ' <<<"$resp"
  )"

  # Preview-Skript (nutzt Feld 3 = JSON)
  local preview_cmd
  preview_cmd='
    json=$(awk -F "\t" "{print \$3}" <<< "{}");
    title=$(jq -r .title <<< "$json");
    ref=$(jq -r ".references.full // (\"!\" + (.iid|tostring))" <<< "$json");
    url=$(jq -r .web_url <<< "$json");
    author=$(jq -r .author.username <<< "$json");
    draft=$(jq -r .draft <<< "$json");
    conflicts=$(jq -r .has_conflicts <<< "$json");
    ms=$(jq -r .merge_status <<< "$json");
    dms=$(jq -r .detailed_merge_status <<< "$json");
    branches="$(jq -r .source_branch <<< "$json") → $(jq -r .target_branch <<< "$json")";
    updated=$(jq -r .updated_at <<< "$json" | sed -E "s/T/ /; s/Z$//");
    notes=$(jq -r .user_notes_count <<< "$json");
    labels=$(jq -r "[.labels[]?] | join(\", \")" <<< "$json");
    desc=$(jq -r .description <<< "$json");

    bold="\033[1m"; dim="\033[2m"; reset="\033[0m"

    printf "%b%s%b  %s\n" "$bold" "$title" "$reset" "$ref"
    printf "%bURL:%b %s\n" "$bold" "$reset" "$url"
    printf "%bAuthor:%b %s    %bDraft:%b %s    %bConflicts:%b %s\n" "$bold" "$reset" "$author" "$bold" "$reset" "$draft" "$bold" "$reset" "$conflicts"
    printf "%bStatus:%b %s (%s)\n" "$bold" "$reset" "$ms" "$dms"
    printf "%bBranches:%b %s\n" "$bold" "$reset" "$branches"
    printf "%bUpdated:%b %s    %bNotes:%b %s\n" "$bold" "$reset" "$updated" "$bold" "$reset" "$notes"
    if [ -n "$labels" ]; then printf "%bLabels:%b %s\n" "$bold" "$reset" "$labels"; fi
    if [ -n "$desc" ] && [ "$desc" != "null" ]; then
      printf "\n%bDescription:%b\n" "$bold" "$reset"
      printf "%s\n" "$desc" | fold -s -w 100
    fi
  '

  # fzf: liest NUL-getrennte Items, zeigt nur Feld 1, Preview nutzt Feld 3, Enter öffnet Feld 2
  local chosen
  chosen="$(
    print -n -- "$nul_records" \
    | fzf --read0 --with-nth=1 --delimiter=$'\t' --ansi \
          --header=$'ENTER: öffnen  |  ESC: abbrechen' \
          --prompt="MRs ($PROJECT_ID) > " \
          --preview "$preview_cmd" \
          --preview-window=right,70%,wrap
  )" || return 0

  # URL öffnen (Feld 2)
  local url
  url="$(awk -F $'\t' '{print $2}' <<<"$chosen")"
  if [[ -n "$url" ]]; then
    if command -v xdg-open >/dev/null 2>&1; then
      nohup xdg-open "$url" >/dev/null 2>&1 &
    elif command -v open >/dev/null 2>&1; then
      open "$url"
    else
      print -- "$url"
    fi
  fi
}
