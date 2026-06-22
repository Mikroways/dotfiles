#!/usr/bin/env zsh
# Tests para mw-tools-upgrade: flujo de notificaciones y actualización automática.
# Mockea git con repos locales temporales. No toca repos reales.
# Uso: zsh test-updates.sh [-v|--verbose]

setopt LOCAL_OPTIONS EXTENDED_GLOB

# ── Flags ──────────────────────────────────────────────────────────────────────
VERBOSE=0
for arg in "$@"; do [[ "$arg" == "-v" || "$arg" == "--verbose" ]] && VERBOSE=1; done

# ── Colores ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
GRAY='\033[0;90m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0

pass() { echo "  ${GREEN}✔ PASS${NC} $1"; (( PASS++ )) }
fail() { echo "  ${RED}✘ FAIL${NC} $1"; (( FAIL++ )) }
section() { echo "\n${YELLOW}${BOLD}$1${NC}" }

# ── Entorno temporal aislado ───────────────────────────────────────────────────
TMPDIR_TEST=$(mktemp -d)
export HOME="$TMPDIR_TEST"
WARN="${HOME}/.mw-tools-upgrade.warn"
NOTIFY="${HOME}/.mw-tools-upgrade.notify"
LOCK="${HOME}/.mw-tools-upgrade.lock"
LOG="${HOME}/.mw-tools-upgrade.log"

cleanup() { rm -rf "$TMPDIR_TEST" }
trap cleanup EXIT

# ── Repos fake ────────────────────────────────────────────────────────────────
REPO_UPTODATE="${TMPDIR_TEST}/fake-repos/uptodate"
REPO_NEEDSUPDATE="${TMPDIR_TEST}/fake-repos/needsupdate"
REPO_LOCALCHANGES="${TMPDIR_TEST}/fake-repos/localchanges"
REPO_NOTMAIN="${TMPDIR_TEST}/fake-repos/notmain"
REPO_SSHAUTH="${TMPDIR_TEST}/fake-repos/sshauth"
BARE_NEEDSUPDATE="${TMPDIR_TEST}/bare-needsupdate.git"

setup_fake_repos() {
  export GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@test.com"
  export GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@test.com"

  # uptodate: main, en sync con remote
  mkdir -p "$REPO_UPTODATE"
  git -C "$REPO_UPTODATE" init -b main -q
  git -C "$REPO_UPTODATE" commit --allow-empty -m "init" -q
  git -C "$REPO_UPTODATE" remote add origin "$REPO_UPTODATE"
  git -C "$REPO_UPTODATE" fetch -q 2>/dev/null || true

  # needsupdate: main, el remote tiene un commit nuevo que local no tiene
  mkdir -p "$REPO_NEEDSUPDATE"
  git -C "$REPO_NEEDSUPDATE" init -b main -q
  git -C "$REPO_NEEDSUPDATE" commit --allow-empty -m "v1" -q
  git clone --bare -q "$REPO_NEEDSUPDATE" "$BARE_NEEDSUPDATE"
  git -C "$REPO_NEEDSUPDATE" remote add origin "$BARE_NEEDSUPDATE"
  git -C "$REPO_NEEDSUPDATE" fetch -q
  git -C "$REPO_NEEDSUPDATE" branch --set-upstream-to=origin/main main
  _push_commit_to_needsupdate "v2"

  # localchanges: main, tiene un archivo sin trackear
  mkdir -p "$REPO_LOCALCHANGES"
  git -C "$REPO_LOCALCHANGES" init -b main -q
  git -C "$REPO_LOCALCHANGES" commit --allow-empty -m "init" -q
  git -C "$REPO_LOCALCHANGES" remote add origin "$REPO_LOCALCHANGES"
  echo "dirty" > "${REPO_LOCALCHANGES}/dirty.txt"

  # notmain: en branch feature, no en main/master
  mkdir -p "$REPO_NOTMAIN"
  git -C "$REPO_NOTMAIN" init -b feature/test -q
  git -C "$REPO_NOTMAIN" commit --allow-empty -m "init" -q
  git -C "$REPO_NOTMAIN" remote add origin "$REPO_NOTMAIN"

  # sshauth: remote por ssh con una clave que requeriría passphrase
  # (ver fake "ssh" en TEST 12)
  mkdir -p "$REPO_SSHAUTH"
  git -C "$REPO_SSHAUTH" init -b main -q
  git -C "$REPO_SSHAUTH" commit --allow-empty -m "init" -q
  git -C "$REPO_SSHAUTH" remote add origin "git@fakehost-unreachable:mikroways/repo.git"
}

# Agrega un commit al remote de needsupdate sin hacer pull local
_push_commit_to_needsupdate() {
  local msg="$1"
  local tmp="${TMPDIR_TEST}/tmp-push"
  rm -rf "$tmp"
  git clone --local -q "$BARE_NEEDSUPDATE" "$tmp" 2>/dev/null
  git -C "$tmp" commit --allow-empty -m "$msg" -q 2>/dev/null
  git -C "$tmp" push -q origin main 2>/dev/null
  rm -rf "$tmp"
  git -C "$REPO_NEEDSUPDATE" fetch -q 2>/dev/null || true
}

# ── Helpers de verbose ────────────────────────────────────────────────────────

_show_file_content() {
  local label="$1" file="$2"
  if [[ -f "$file" && -s "$file" ]]; then
    echo "${GRAY}    ${label}:${NC}"
    while IFS= read -r line; do echo "${GRAY}      $line${NC}"; done < "$file"
  else
    echo "${GRAY}    ${label}: (no existe)${NC}"
  fi
}

_show_before() {
  [[ $VERBOSE -eq 0 ]] && return
  echo "${CYAN}  Antes:${NC}"
  _show_file_content "lock" "$LOCK"
  _show_file_content "warn" "$WARN"
  _show_file_content "notify" "$NOTIFY"
  if [[ -f "$LOG" ]]; then
    echo "${GRAY}    log:  $(wc -l < $LOG) líneas existentes${NC}"
  else
    echo "${GRAY}    log:  (no existe)${NC}"
  fi
}

_show_after() {
  local lines_before="$1"
  [[ $VERBOSE -eq 0 ]] && return
  echo "${CYAN}  Después:${NC}"

  local total=0
  [[ -f "$LOG" ]] && total=$(wc -l < "$LOG")
  local new=$(( total - lines_before ))
  if [[ $new -gt 0 ]]; then
    echo "${GRAY}    log output:${NC}"
    tail -$new "$LOG" | while IFS= read -r line; do echo "${GRAY}      $line${NC}"; done
  else
    echo "${GRAY}    log output: (ninguno — la función no llegó a correr)${NC}"
  fi

  _show_file_content "warn" "$WARN"
  _show_file_content "notify" "$NOTIFY"
  _show_file_content "lock" "$LOCK"
}

reset_env() {
  local repo_label="$1"
  rm -f "$LOCK" "$WARN" "$NOTIFY" "$LOG"
  [[ $VERBOSE -eq 1 ]] && echo "${CYAN}  Repo bajo prueba: ${repo_label}${NC}"
}

run_upgrade() {
  local lines_before=0
  [[ -f "$LOG" ]] && lines_before=$(wc -l < "$LOG")
  _show_before
  echo "${CYAN}  Ejecutando: ${BOLD}mw-tools-upgrade -y${NC}"
  mw-tools-upgrade -y >> "$LOG" 2>&1
  _show_after "$lines_before"
}

# ── Cargar funciones bajo test ────────────────────────────────────────────────
GIT_UPDATE_CHECK_FILE="$LOCK"
source "$(dirname $0)/zshrc.mikroways.updates" 2>/dev/null || {
  echo "ERROR: no se pudo cargar zshrc.mikroways.updates"; exit 1
}

setup_fake_repos


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 1: Lock file — evita doble ejecución en el mismo día"
# ══════════════════════════════════════════════════════════════════════════════

reset_env "uptodate (repo al día)"
WATCHED_DIRS=("$REPO_UPTODATE")

[[ $VERBOSE -eq 1 ]] && echo "${CYAN}  Corrida 1 — sin lock, debe correr completo:${NC}"
run_upgrade
if [[ -f "$LOCK" && $(cat "$LOCK") == $(date +%Y-%m-%d) ]]; then
  pass "Primera corrida escribe el lock con la fecha de hoy"
else
  fail "Primera corrida no escribió el lock correcto"
fi

[[ $VERBOSE -eq 1 ]] && echo "${CYAN}  Corrida 2 — lock de hoy ya existe, debe salir sin hacer nada:${NC}"
local lines_before=$(wc -l < "$LOG")
run_upgrade
if [[ $(wc -l < "$LOG") -eq $lines_before ]]; then
  pass "Segunda corrida con lock de hoy no agrega nada al log"
else
  fail "Segunda corrida debería salir por lock, pero escribió al log"
fi


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 2: Lock del día anterior — permite nueva corrida"
# ══════════════════════════════════════════════════════════════════════════════

reset_env "uptodate (repo al día)"
WATCHED_DIRS=("$REPO_UPTODATE")
date -d yesterday +%Y-%m-%d > "$LOCK"

run_upgrade
if grep -q "Checking for Mikroways" "$LOG"; then
  pass "Lock de fecha anterior no bloquea el check"
else
  fail "Lock de fecha anterior bloqueó el check incorrectamente"
fi


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 3: Repo al día — no se escribe warn ni notify"
# ══════════════════════════════════════════════════════════════════════════════

reset_env "uptodate (repo al día, sin updates remotos)"
WATCHED_DIRS=("$REPO_UPTODATE")

run_upgrade
if [[ ! -f "$WARN" ]]; then
  pass "Sin updates: warn no creado"
else
  fail "Sin updates: warn creado innecesariamente — contenido: $(cat $WARN)"
fi
if [[ ! -f "$NOTIFY" ]]; then
  pass "Sin updates: notify no creado"
else
  fail "Sin updates: notify creado innecesariamente — contenido: $(cat $NOTIFY)"
fi
if grep -q "✅" "$LOG"; then
  pass "Sin updates: log muestra ✅"
else
  fail "Sin updates: log no muestra ✅"
fi


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 4: Repo con update disponible — notify escrito, warn NO escrito"
# ══════════════════════════════════════════════════════════════════════════════

reset_env "needsupdate (remote tiene un commit nuevo)"
WATCHED_DIRS=("$REPO_NEEDSUPDATE")

run_upgrade
if [[ -f "$NOTIFY" ]]; then
  pass "Con update: notify creado"
  if grep -q "actualizadas" "$NOTIFY"; then
    pass "Notify contiene el mensaje de actualización"
  else
    fail "Notify existe pero no menciona 'actualizadas': $(cat $NOTIFY)"
  fi
else
  fail "Con update: notify NO fue creado — el usuario no se entera del update"
fi
if [[ ! -f "$WARN" ]] || [[ ! -s "$WARN" ]]; then
  pass "Con update: warn no escrito (no hay problemas que requieran acción)"
else
  fail "Con update: warn escrito innecesariamente — contenido: $(cat $WARN)"
fi
if grep -q "⚠️" "$LOG"; then
  pass "Log muestra ⚠️ para el repo con update"
else
  fail "Log no muestra ⚠️"
fi


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 5: Notify se muestra una vez y se borra — warn persiste"
# ══════════════════════════════════════════════════════════════════════════════

echo "  ✔️  mw-tools: actualizadas: /fake/repo" > "$NOTIFY"
echo "  🚩 mw-tools: cambios locales sin commitear en: /fake/repo" > "$WARN"
[[ $VERBOSE -eq 1 ]] && { echo "${CYAN}  Antes:${NC}"; _show_file_content "notify" "$NOTIFY"; _show_file_content "warn" "$WARN" }

local notify_output warn_output
notify_output=$(if [[ -f "$NOTIFY" ]]; then cat "$NOTIFY"; rm -f "$NOTIFY"; fi)
warn_output=$(if [[ -f "$WARN" ]]; then cat "$WARN"; fi)

[[ $VERBOSE -eq 1 ]] && {
  echo "${CYAN}  Después:${NC}"
  echo "${GRAY}    notify mostrado: $notify_output${NC}"
  echo "${GRAY}    warn mostrado:   $warn_output${NC}"
  _show_file_content "notify" "$NOTIFY"
  _show_file_content "warn" "$WARN"
}

if echo "$notify_output" | grep -q "actualizadas"; then
  pass "Notify se muestra al abrir el shell"
else
  fail "Notify no se mostró"
fi
if [[ ! -f "$NOTIFY" ]]; then
  pass "Notify se elimina después de mostrarse (one-shot)"
else
  fail "Notify no se eliminó"
fi
if echo "$warn_output" | grep -q "cambios locales"; then
  pass "Warn se muestra al abrir el shell"
else
  fail "Warn no se mostró"
fi
if [[ -f "$WARN" ]]; then
  pass "Warn NO se borra al mostrarse (persiste hasta que se resuelva)"
else
  fail "Warn fue borrado — el usuario no lo vería en la próxima terminal"
fi


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 6: Repo con cambios locales — warn escrito, notify NO escrito, lock escrito"
# ══════════════════════════════════════════════════════════════════════════════

reset_env "localchanges (tiene dirty.txt sin trackear)"
WATCHED_DIRS=("$REPO_LOCALCHANGES")

run_upgrade
if [[ -f "$WARN" ]]; then
  pass "Cambios locales: warn escrito"
  if grep -q "cambios locales" "$WARN"; then
    pass "Warn menciona los cambios locales"
  else
    fail "Warn no menciona 'cambios locales': $(cat $WARN)"
  fi
else
  fail "Cambios locales: warn no escrito — el usuario no se entera"
fi
if [[ ! -f "$NOTIFY" ]] || [[ ! -s "$NOTIFY" ]]; then
  pass "Cambios locales: notify no escrito (no hubo actualización)"
else
  fail "Cambios locales: notify escrito innecesariamente — contenido: $(cat $NOTIFY)"
fi
if [[ -f "$LOCK" && $(cat "$LOCK") == $(date +%Y-%m-%d) ]]; then
  pass "Cambios locales: lock escrito — background no se dispara en cada terminal"
else
  fail "Cambios locales: lock no escrito — background se dispararía en cada terminal"
fi


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 7: Repo no en main — warn escrito, notify NO escrito, lock escrito"
# ══════════════════════════════════════════════════════════════════════════════

reset_env "notmain (en branch feature/test)"
WATCHED_DIRS=("$REPO_NOTMAIN")

run_upgrade
if [[ -f "$WARN" ]]; then
  pass "Repo en branch no-main: warn escrito"
  if grep -q "rama no principal" "$WARN"; then
    pass "Warn menciona la rama no principal"
  else
    fail "Warn no menciona 'rama no principal': $(cat $WARN)"
  fi
else
  fail "Repo en branch no-main: warn no escrito"
fi
if [[ ! -f "$NOTIFY" ]] || [[ ! -s "$NOTIFY" ]]; then
  pass "Repo en branch no-main: notify no escrito (no hubo actualización)"
else
  fail "Repo en branch no-main: notify escrito innecesariamente"
fi
if [[ -f "$LOCK" && $(cat "$LOCK") == $(date +%Y-%m-%d) ]]; then
  pass "Repo en branch: lock escrito — background no se dispara en cada terminal"
else
  fail "Repo en branch: lock no escrito — background se dispararía en cada terminal"
fi


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 8: mw-tools-force-upgrade — ignora lock y output va a stdout"
# ══════════════════════════════════════════════════════════════════════════════

reset_env "uptodate"
WATCHED_DIRS=("$REPO_UPTODATE")
echo "$(date +%Y-%m-%d)" > "$LOCK"
[[ $VERBOSE -eq 1 ]] && { echo "${CYAN}  Antes:${NC}"; _show_file_content "lock" "$LOCK" }

local force_output
force_output=$(mw-tools-force-upgrade 2>&1)

[[ $VERBOSE -eq 1 ]] && {
  echo "${CYAN}  Output de force-upgrade (va a stdout, no a warn/notify/log):${NC}"
  echo "$force_output" | while IFS= read -r line; do echo "${GRAY}    $line${NC}"; done
  echo "${CYAN}  Después:${NC}"
  _show_file_content "warn" "$WARN"
  _show_file_content "notify" "$NOTIFY"
  _show_file_content "lock" "$LOCK"
}

if echo "$force_output" | grep -q "Checking for Mikroways"; then
  pass "force-upgrade corre el check a pesar del lock de hoy"
else
  fail "force-upgrade no corrió el check"
fi
if [[ ! -f "$WARN" ]] || [[ ! -s "$WARN" ]]; then
  pass "force-upgrade: sin problemas, warn no escrito"
else
  fail "force-upgrade: warn escrito cuando no debería"
fi


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 9: Warn se limpia cuando el check es limpio"
# ══════════════════════════════════════════════════════════════════════════════

echo "  🚩 mw-tools: cambios locales sin commitear en: /fake/repo" > "$WARN"
rm -f "$LOCK"
WATCHED_DIRS=("$REPO_UPTODATE")

[[ $VERBOSE -eq 1 ]] && { echo "${CYAN}  Estado inicial: warn existe de chequeo anterior${NC}"; _show_file_content "warn" "$WARN" }

run_upgrade

if [[ ! -f "$WARN" ]]; then
  pass "Check limpio: warn eliminado (problema resuelto)"
else
  fail "Check limpio: warn NO eliminado — contenido: $(cat $WARN)"
fi


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 10: Race condition — dos shells abren casi simultáneamente"
# ══════════════════════════════════════════════════════════════════════════════

reset_env "needsupdate (con nuevo commit remoto)"
WATCHED_DIRS=("$REPO_NEEDSUPDATE")
_push_commit_to_needsupdate "v3"

[[ $VERBOSE -eq 1 ]] && echo "${CYAN}  BG1 arranca con 0.4s de delay (simula fetch lento)${NC}"
{ sleep 0.4; GIT_UPDATE_CHECK_FILE="$LOCK"; WATCHED_DIRS=("$REPO_NEEDSUPDATE")
  mw-tools-upgrade -y >> "$LOG" 2>&1 } &!

sleep 0.1
[[ $VERBOSE -eq 1 ]] && echo "${CYAN}  BG2 arranca antes de que BG1 escriba el lock${NC}"
{ GIT_UPDATE_CHECK_FILE="$LOCK"; WATCHED_DIRS=("$REPO_NEEDSUPDATE")
  mw-tools-upgrade -y >> "$LOG" 2>&1 } &!

sleep 3
[[ $VERBOSE -eq 1 ]] && {
  echo "${CYAN}  Después (ambos BGs terminaron):${NC}"
  _show_file_content "notify" "$NOTIFY"
  _show_file_content "warn" "$WARN"
  _show_file_content "lock" "$LOCK"
  echo "${GRAY}    log:${NC}"
  [[ -f "$LOG" ]] && while IFS= read -r line; do echo "${GRAY}      $line${NC}"; done < "$LOG"
}

if [[ -f "$NOTIFY" ]]; then
  pass "Race condition: al menos un BG escribió el notify"
else
  if grep -q "actualizadas\|All tools up to date\|✅" "$LOG" 2>/dev/null; then
    pass "Race condition: repo procesado — el segundo BG vio el lock y el primero ya actualizó"
  else
    fail "Race condition: notify ausente y sin evidencia de procesamiento"
  fi
fi


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 11: Log se rota a 500 líneas"
# ══════════════════════════════════════════════════════════════════════════════

reset_env "uptodate"
WATCHED_DIRS=("$REPO_UPTODATE")
python3 -c "print('\n'.join(['line ' + str(i) for i in range(600)]))" > "$LOG"
[[ $VERBOSE -eq 1 ]] && echo "${CYAN}  Log pre-existente: 600 líneas${NC}"

{
  [[ -f "$LOG" ]] && tail -500 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
  mw-tools-upgrade -y >> "$LOG" 2>&1
} 2>/dev/null

local lines=$(wc -l < "$LOG")
[[ $VERBOSE -eq 1 ]] && echo "${CYAN}  Líneas en log después de rotar y correr: $lines${NC}"
if [[ $lines -le 520 ]]; then
  pass "Log rotado correctamente: $lines líneas (límite 500 + output del run)"
else
  fail "Log no rotado: $lines líneas (debería ser ≤520)"
fi


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 12: Clave SSH con passphrase — no se cuelga pidiéndola en background"
# ══════════════════════════════════════════════════════════════════════════════
# Reproduce el bug reportado: si la clave necesita passphrase y no hay
# terminal/agente disponible, ssh quedaría esperando input para siempre
# (o disparando un askpash gráfico que puede crashear). mw-tools-upgrade
# debe forzar BatchMode=yes para que git/ssh fallen rápido en vez de pedir
# la passphrase, y reportar el error como un .warn con un hint de ssh-add.

reset_env "sshauth (remote ssh, simula clave bloqueada con passphrase)"
WATCHED_DIRS=("$REPO_SSHAUTH")

# ssh fake: si recibe BatchMode=yes falla rápido (lo esperable); si no lo
# recibe, simula quedarse esperando la passphrase (lo que rompía antes).
mkdir -p "$TMPDIR_TEST/fakebin"
cat > "$TMPDIR_TEST/fakebin/ssh" <<'FAKESSH'
#!/bin/sh
batch=0
for a in "$@"; do
  case "$a" in
    *BatchMode=yes*) batch=1 ;;
  esac
done
if [ "$batch" -eq 1 ]; then
  echo "git@fakehost-unreachable: Permission denied (publickey)." >&2
  exit 255
else
  sleep 5
  exit 1
fi
FAKESSH
chmod +x "$TMPDIR_TEST/fakebin/ssh"

local OLDPATH="$PATH"
export PATH="$TMPDIR_TEST/fakebin:$PATH"

local start_ts=$(date +%s)
run_upgrade
local elapsed=$(( $(date +%s) - start_ts ))

export PATH="$OLDPATH"

if [[ $elapsed -le 3 ]]; then
  pass "No se cuelga esperando la passphrase (terminó en ${elapsed}s, no en >5s)"
else
  fail "Se colgó esperando la passphrase (tardó ${elapsed}s) — falta BatchMode=yes"
fi
if grep -q "Permission denied" "$LOG"; then
  pass "El error de auth se reporta en el log"
else
  fail "El error de auth no aparece en el log:\n$(cat $LOG)"
fi
if [[ -f "$WARN" ]] && grep -q "ssh-add" "$WARN"; then
  pass "El warn sugiere 'ssh-add' para cargar la clave en el agente"
else
  fail "El warn no sugiere ssh-add: $(cat $WARN 2>/dev/null)"
fi


# ══════════════════════════════════════════════════════════════════════════════
section "TEST 13: Error de fetch NO-auth — el warn NO sugiere ssh-add"
# ══════════════════════════════════════════════════════════════════════════════
# Complemento del TEST 12: si el fetch falla por algo que no es autenticación
# (p.ej. el host no resuelve), el hint de ssh-add no debe aparecer.

reset_env "sshauth (remote ssh, simula host inalcanzable)"
WATCHED_DIRS=("$REPO_SSHAUTH")

# ssh fake: siempre falla con un error que NO es de auth.
cat > "$TMPDIR_TEST/fakebin/ssh" <<'FAKESSH'
#!/bin/sh
echo "ssh: Could not resolve hostname fakehost-unreachable: Name or service not known" >&2
exit 255
FAKESSH
chmod +x "$TMPDIR_TEST/fakebin/ssh"

OLDPATH="$PATH"
export PATH="$TMPDIR_TEST/fakebin:$PATH"
run_upgrade
export PATH="$OLDPATH"

if [[ -f "$WARN" ]] && grep -q "error al hacer fetch" "$WARN"; then
  pass "El error de fetch se reporta en el warn"
else
  fail "El error de fetch no aparece en el warn: $(cat $WARN 2>/dev/null)"
fi
if [[ -f "$WARN" ]] && grep -q "ssh-add" "$WARN"; then
  fail "El warn sugiere ssh-add ante un error que no es de auth: $(cat $WARN)"
else
  pass "El warn NO sugiere ssh-add (el error no era de autenticación)"
fi


# ══════════════════════════════════════════════════════════════════════════════
echo "\n${BOLD}$(printf '─%.0s' {1..50})${NC}"
echo "Resultados: ${GREEN}${BOLD}${PASS} PASS${NC}  ${RED}${BOLD}${FAIL} FAIL${NC}"
echo "${BOLD}$(printf '─%.0s' {1..50})${NC}"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
