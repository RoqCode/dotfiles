setopt PIPE_FAIL

gmr() {
  emulate -L zsh -o pipe_fail -o noxtrace -o noverbose
  setopt localoptions pipe_fail noxtrace

  local CONFIG_PATH GL_HOST PROJECT_PATH TARGET_BRANCH TITLE REVIEWERS
  local CLI_PROJECT_PATH CLI_TARGET_BRANCH CLI_TITLE CLI_REVIEWERS CLI_IID DRY
  local CFG_GL_HOST CFG_PROJECT_PATH CFG_TARGET_BRANCH CFG_REVIEWERS
  local API AUTH_HEADER ENC_PATH PROJECT_ID SOURCE_BRANCH MR_IID MR_URL

  local CONFIG_PATH=""
  if [[ -f ".gitlab/mr-config.yml" ]]; then
    CONFIG_PATH=".gitlab/mr-config.yml"
  elif [[ -f "mr-config.yml" ]]; then
    CONFIG_PATH="mr-config.yml"
  fi

  if [[ -n "$CONFIG_PATH" ]]; then
    echo "[INFO]  using config: $CONFIG_PATH"
    local CFG_GL_HOST CFG_PROJECT_PATH CFG_REVIEWERS CFG_TARGET_BRANCH
    CFG_GL_HOST="$(yq -r '.gl_host // ""' "$CONFIG_PATH" 2>/dev/null)"
    CFG_PROJECT_PATH="$(yq -r '.project_path // ""' "$CONFIG_PATH" 2>/dev/null)"
    CFG_TARGET_BRANCH="$(yq -r '.default_target_branch // ""' "$CONFIG_PATH" 2>/dev/null)"
    local CFG_REVIEWERS=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && CFG_REVIEWERS+=("$line")
    done < <(yq -r '.default_reviewers[]?' "$CONFIG_PATH" 2>/dev/null)

    [[ -n "$CFG_GL_HOST" ]] && GL_HOST="$CFG_GL_HOST"
    [[ -n "$CFG_PROJECT_PATH" && -z "${PROJECT_PATH:-}" ]] && PROJECT_PATH="$CFG_PROJECT_PATH"
    [[ -n "$CFG_TARGET_BRANCH" ]] && TARGET_BRANCH="$CFG_TARGET_BRANCH"
    [[ ${#CFG_REVIEWERS[@]} -gt 0 ]] && DEFAULT_REVIEWERS=("${CFG_REVIEWERS[@]}")
  else
    echo "[WARN]  keine mr-config.yml gefunden → CLI-Argumente oder Defaults werden genutzt."
  fi

  : "${GL_TOKEN:?Bitte setze GL_TOKEN (Personal Access Token mit api-Scope)}"
  local GL_HOST="${GL_HOST:-gitlab.com}"

  local PROJECT_PATH="${PROJECT_PATH:-}"
  local TARGET_BRANCH="${TARGET_BRANCH:-develop}"
  local MR_IID=""
  local CSV_REVIEWERS=""
  local DRY=false
  local DEFAULT_REVIEWERS=("${DEFAULT_REVIEWERS[@]-}")
  local TITLE_OVERRIDE=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project)     PROJECT_PATH="$2"; shift 2;;
      --target)      TARGET_BRANCH="$2"; shift 2;;
      --iid)         MR_IID="$2"; shift 2;;
      --reviewers)   CSV_REVIEWERS="$2"; shift 2;;
      --dry)         DRY=true; shift;;
      --title)       TITLE_OVERRIDE="$2"; shift 2;;
      -h|--help)
        echo "usage: gmr [--project <group/subgroup/project>] [--target develop] [--iid N] [--reviewers a,b] [--title \"Title\"] [--dry]"
        return 0;;
      *) echo "Unbekannte Option: $1"; return 1;;
    esac
  done
  if [[ -z "$PROJECT_PATH" ]]; then
    echo "❌ Kein Projektpfad definiert."
    echo "   - Entweder per Flag:     --project <group/subgroup/project>"
    echo "   - Oder in YAML:          .gitlab/mr-config.yml (project_path: ...)"
    return 1
  fi

  # --- helpers ---
  local START_EPOCH=${EPOCHSECONDS:-$(date +%s)}
  _ts() { print -r -- "$(date '+%H:%M:%S')"; }
  _elapsed() { local now=${EPOCHSECONDS:-$(date +%s)}; print -r -- "$(($now - $START_EPOCH))s"; }
  _step() { echo "[$(_ts)] $1"; }
  _ok()   { echo "[$(_ts)] ✅ $1 ($( _elapsed ))"; }
  _warn() { echo "[$(_ts)] ⚠️  $1"; }
  _die()  { echo "[$(_ts)] ❌ $1"; return 1; }

  local API="https://${GL_HOST}/api/v4"
  local AUTH_HEADER="PRIVATE-TOKEN: ${GL_TOKEN}"

  # URL-encode Pfad (arg-sicher, zsh/bashi kompatibel)
  local ENC_PATH
  ENC_PATH="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$PROJECT_PATH")"

  _step "Projekt ermitteln: $PROJECT_PATH"
  local PROJECT_ID
  PROJECT_ID="$(command curl -sS -H "$AUTH_HEADER" "$API/projects/$ENC_PATH" | jq -r '.id')"
  [[ -n "$PROJECT_ID" && "$PROJECT_ID" != null ]] || { _die "Projekt nicht gefunden: $PROJECT_PATH"; return 1; }
  _ok "Projekt-ID: $PROJECT_ID"

  # Quelle/Ziel bestimmen
  local SOURCE_BRANCH
  SOURCE_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  [[ -n "$SOURCE_BRANCH" ]] || { _die "Konnte aktuellen Branch nicht bestimmen (git)"; return 1; }
  _step "Branch: $SOURCE_BRANCH  → Target: $TARGET_BRANCH"


  # MR erstellen oder vorhandenen finden
  local MR_URL=""
  if [[ -z "$MR_IID" ]]; then
    _step "MR anlegen (falls nicht vorhanden)…"
    # Titel setzen: Default = Branchname, Flag gewinnt
    local TITLE
    if [[ -n "$TITLE_OVERRIDE" ]]; then
      TITLE="$TITLE_OVERRIDE"
    else
      TITLE="$SOURCE_BRANCH"
    fi
    echo "   • Titel: $TITLE"

    if $DRY; then
      _warn "DRY-RUN: überspringe POST /merge_requests"
    else
      local RESP CREATE_IID
      RESP="$(command curl -sS -X POST -H "$AUTH_HEADER" \
              --data-urlencode "source_branch=${SOURCE_BRANCH}" \
              --data-urlencode "target_branch=${TARGET_BRANCH}" \
              --data-urlencode "title=${TITLE}" \
              "$API/projects/${PROJECT_ID}/merge_requests")"

      CREATE_IID="$(jq -r '.iid // empty' <<<"$RESP")"
      MR_URL="$(jq -r '.web_url // empty' <<<"$RESP")"

      if [[ -n "$CREATE_IID" ]]; then
        MR_IID="$CREATE_IID"
        _ok "MR erstellt: !${MR_IID}"
      else
        # evtl. existiert schon einer → per Query finden
        _warn "Konnte MR nicht neu anlegen – suche bestehenden für source_branch=$SOURCE_BRANCH…"
        MR_IID="$(command curl -sS -H "$AUTH_HEADER" \
                 --get --data-urlencode "source_branch=${SOURCE_BRANCH}" \
                 --get --data-urlencode "state=opened" \
                 "$API/projects/${PROJECT_ID}/merge_requests" \
                 | jq -r '.[0].iid // empty')"
        MR_URL="$(command curl -sS -H "$AUTH_HEADER" \
                 --get --data-urlencode "source_branch=${SOURCE_BRANCH}" \
                 --get --data-urlencode "state=opened" \
                 "$API/projects/${PROJECT_ID}/merge_requests" \
                 | jq -r '.[0].web_url // empty')"
        [[ -n "$MR_IID" ]] || { _die "Kein bestehender MR für $SOURCE_BRANCH gefunden und Create fehlgeschlagen."; return 1; }
        _ok "Vorhandenen MR gefunden: !${MR_IID}"
        # Wenn MR existiert und ein Titel via Flag vorgegeben ist: Titel updaten
        if [[ -n "$MR_IID" && -n "$TITLE_OVERRIDE" ]]; then
          _step "Titel aktualisieren auf: $TITLE_OVERRIDE"
          if $DRY; then
            echo "DRY-RUN: PUT $API/projects/${PROJECT_ID}/merge_requests/${MR_IID}  title=$TITLE_OVERRIDE"
          else
            command curl -sS -X PUT -H "$AUTH_HEADER" \
              --data-urlencode "title=${TITLE_OVERRIDE}" \
              "$API/projects/${PROJECT_ID}/merge_requests/${MR_IID}" \
              | jq -r '"   ✓ Neuer Titel: " + .title'
            _ok "Titel aktualisiert"
          fi
        fi
      fi
    fi
  else
    _step "MR übersprungen (IID vorgegeben: !${MR_IID})"
    MR_URL="$(command curl -sS -H "$AUTH_HEADER" "$API/projects/${PROJECT_ID}/merge_requests/${MR_IID}" | jq -r '.web_url // empty')"
  fi

  [[ -n "$MR_URL" ]] && echo "➡️  $MR_URL"

  # Reviewer bestimmen
  local REVIEWERS=()
  if [[ -n "$CSV_REVIEWERS" ]]; then
    local IFS=','; REVIEWERS=(${=CSV_REVIEWERS})
    _step "Reviewer (CLI): ${REVIEWERS[*]}"
  else
    REVIEWERS=("${DEFAULT_REVIEWERS[@]}")
    _step "Reviewer (Default): ${REVIEWERS[*]}"
  fi
  [[ ${#REVIEWERS[@]} -gt 0 ]] || { _warn "Keine Reviewer angegeben – step übersprungen."; echo "✅ Fertig (ohne Reviewer)"; return 0; }

  # Usernames -> IDs (ohne "USER_ID=…" Echo)
  _step "User-IDs auflösen…"
  local USER_IDS=() miss=0
  local NAME

  for NAME in "${REVIEWERS[@]}"; do
    local USER_ID=""
    { IFS= read -r USER_ID; } < <(
      command curl -sS -H "$AUTH_HEADER" \
        --get --data-urlencode "username=${NAME}" \
        "$API/users" | jq -r '.[0].id // empty'
    )

    if [[ -n "$USER_ID" ]]; then
      USER_IDS+=("$USER_ID")
      echo "   • @$NAME  → id ${USER_ID}"
    else
      miss=$((miss+1))
      _warn "Nutzer nicht gefunden: @$NAME"
    fi
  done

  [[ ${#USER_IDS[@]} -gt 0 ]] || { _die "Keine gültigen Reviewer-IDs ermittelt."; return 1; }
  [[ $miss -gt 0 ]] && _warn "$miss Nutzer wurden übersprungen."

  # Existierende Reviewer holen & vereinigen (add, not replace)
  _step "Vorhandene Reviewer lesen…"
  local EXISTING_IDS
  EXISTING_IDS=($(command curl -sS -H "$AUTH_HEADER" \
                  "$API/projects/${PROJECT_ID}/merge_requests/${MR_IID}" \
                | jq -r '.reviewers[]?.id'))
  local ALL_IDS=("${EXISTING_IDS[@]}" "${USER_IDS[@]}")

  # Deduplizieren
  local UNIQUE_IDS=()
  local seen=()
  local id
  for id in "${ALL_IDS[@]}"; do
    [[ -n "${seen[$id]-}" ]] || { UNIQUE_IDS+=("$id"); seen[$id]=1; }
  done

  # Querystring bauen
  local QS=""
  for id in "${UNIQUE_IDS[@]}"; do
    [[ -n "$QS" ]] && QS+="&"
    QS+="reviewer_ids[]=$id"
  done

  _step "Reviewer setzen (${#UNIQUE_IDS[@]})…"
  if $DRY; then
    echo "DRY-RUN: PUT $API/projects/${PROJECT_ID}/merge_requests/${MR_IID}?$QS"
  else
    local ok=true
    echo "— gesetzt —"
    command curl -sS -X PUT -H "$AUTH_HEADER" \
      "$API/projects/${PROJECT_ID}/merge_requests/${MR_IID}?$QS" \
      | jq -re '.reviewers[]? | "   ✓ @" + .username + " (" + (.name // "") + ")"' \
    || ok=false
    $ok && _ok "Reviewer aktualisiert" || _warn "Reviewer-Ausgabe leer oder jq-Fehler"
  fi

  _ok "Done. MR !${MR_IID}"

}
