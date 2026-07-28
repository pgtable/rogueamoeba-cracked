#!/usr/bin/env bash
# rogueamoeba-cracked
# Cracked by pgtable.

set -uo pipefail

VERSION="1.1.0"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"

APPS=(
  "Airfoil|Airfoil.app|https://cdn.rogueamoeba.com/airfoil/mac/download/Airfoil.zip"
  "Audio Hijack|Audio Hijack.app|https://cdn.rogueamoeba.com/audiohijack/download/AudioHijack.zip"
  "Farrago|Farrago.app|https://cdn.rogueamoeba.com/farrago/download/Farrago.zip"
  "Fission|Fission.app|https://cdn.rogueamoeba.com/fission/download/Fission.zip"
  "Loopback|Loopback.app|https://cdn.rogueamoeba.com/loopback/download/Loopback.zip"
  "Piezo|Piezo.app|https://cdn.rogueamoeba.com/piezo/download/Piezo.zip"
  "SoundSource|SoundSource.app|https://cdn.rogueamoeba.com/soundsource/download/SoundSource.zip"
)

app_name()   { printf '%s' "${1%%|*}"; }
app_bundle() { local rest=${1#*|}; printf '%s' "${rest%%|*}"; }
app_url()    { printf '%s' "${1##*|}"; }

LB_INDEX=-1
for i in "${!APPS[@]}"; do
  [[ $(app_name "${APPS[i]}") == "Loopback" ]] && { LB_INDEX=$i; break; }
done

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_REV=$'\033[7m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_MAGENTA=$'\033[35m'; C_CYAN=$'\033[36m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''; C_REV=''
  C_RED=''; C_GREEN=''; C_YELLOW=''; C_MAGENTA=''; C_CYAN=''
fi

log()   { printf '%s[+]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()  { printf '%s[!]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
err()   { printf '%s[x]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
title() { printf '\n%s%s=== %s ===%s\n' "$C_BOLD" "$C_CYAN" "$*" "$C_RESET"; }
die()   { err "$*"; exit 1; }

check_env() {
  [[ "$(uname -s)" == "Darwin" ]] || die "macOS only."

  local missing=()
  for cmd in curl unzip codesign lipo nm python3; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  [[ ${#missing[@]} -eq 0 ]] || die "Missing: ${missing[*]}. Install Xcode CLT: xcode-select --install"
}

# TUI

CURSOR=0
LB_MOD=0
MSG=""
SELECTED=()

tui_row() { # tui_row <under-cursor> <checked> <label>
  local mark=' '
  (( $2 )) && mark='x'
  if (( $1 )); then
    printf '  %s>%s %s[%s] %s%s\033[K\n' "$C_CYAN" "$C_RESET" "$C_REV" "$mark" "$3" "$C_RESET"
  elif (( $2 )); then
    printf '    %s[%s] %s%s\033[K\n' "$C_GREEN" "$mark" "$3" "$C_RESET"
  else
    printf '    %s[%s] %s%s\033[K\n' "$C_DIM" "$mark" "$3" "$C_RESET"
  fi
}

tui_status() {
  local count=0 i
  for ((i = 0; i < ${#APPS[@]}; i++)); do
    (( SELECTED[i] )) && ((count += 1))
  done

  if [[ -n "$MSG" ]]; then
    printf '  %s%s%s\033[K\n' "$C_YELLOW" "$MSG" "$C_RESET"
  elif (( LB_MOD )) && (( ! SELECTED[LB_INDEX] )); then
    printf '  %sLoopback mod is on but Loopback is not selected%s\033[K\n' \
      "$C_YELLOW" "$C_RESET"
  elif (( count == 1 )); then
    printf '  %s1 app selected%s\033[K\n' "$C_DIM" "$C_RESET"
  else
    printf '  %s%d apps selected%s\033[K\n' "$C_DIM" "$count" "$C_RESET"
  fi
}

tui_draw() {
  local i name
  printf '\033[H'
  printf '\n  %s%srogue amoeba cracker%s %sv%s%s\n' \
    "$C_BOLD" "$C_MAGENTA" "$C_RESET" "$C_DIM" "$VERSION" "$C_RESET"
  printf '  %scracked by pgtable%s\n\n' "$C_DIM" "$C_RESET"

  for i in "${!APPS[@]}"; do
    printf -v name '%-13s' "$(app_name "${APPS[i]}")"
    tui_row "$(( i == CURSOR ))" "${SELECTED[i]}" "$name"
  done

  printf '\n'
  tui_row "$(( CURSOR == ${#APPS[@]} ))" "$LB_MOD" "Loopback 300% volume"

  printf '\n'
  tui_status
  printf '\n  %sspace toggle · a all · n none · enter crack · q quit%s\033[K\033[J' \
    "$C_DIM" "$C_RESET"
}

tui_pick() {
  local n=${#APPS[@]} i key rest

  for ((i = 0; i < n; i++)); do SELECTED[i]=0; done

  printf '\033[?25l\033[H\033[J'
  tui_draw

  while IFS= read -rsn1 key < /dev/tty; do
    MSG=""
    case $key in
      $'\033')
        read -rsn2 -t 1 rest < /dev/tty || rest=""
        case $rest in
          '[A') (( CURSOR > 0 )) && ((CURSOR -= 1)) ;;
          '[B') (( CURSOR < n )) && ((CURSOR += 1)) ;;
        esac
        ;;
      k) (( CURSOR > 0 )) && ((CURSOR -= 1)) ;;
      j) (( CURSOR < n )) && ((CURSOR += 1)) ;;
      ' ')
        if (( CURSOR < n )); then
          SELECTED[CURSOR]=$(( 1 - SELECTED[CURSOR] ))
        else
          LB_MOD=$(( 1 - LB_MOD ))
        fi
        ;;
      a) for ((i = 0; i < n; i++)); do SELECTED[i]=1; done ;;
      n) for ((i = 0; i < n; i++)); do SELECTED[i]=0; done; LB_MOD=0 ;;
      q) break ;;
      '')
        for ((i = 0; i < n; i++)); do
          (( SELECTED[i] )) && { printf '\033[?25h\033[H\033[J'; return 0; }
        done
        MSG="select at least one app"
        ;;
    esac
    tui_draw
  done

  printf '\033[?25h\033[H\033[J'
  return 1
}

# Mach-O helpers

nm_addr() { # nm_addr <binary> <arch> <symbol-regex>
  nm -arch "$2" "$1" 2>/dev/null | awk -v re="$3" '$0 ~ re {print $1; exit}'
}

split_fat() { # split_fat <binary> <dir>: writes <dir>/x64 and <dir>/arm
  lipo -thin x86_64 "$1" -output "$2/x64" 2>/dev/null &&
  lipo -thin arm64  "$1" -output "$2/arm" 2>/dev/null
}

join_fat() { # join_fat <dir> <dest-binary>
  lipo -create "$1/x64" "$1/arm" -output "$1/new" 2>/dev/null &&
  cp "$1/new" "$2" && chmod +x "$2"
}

stub_return_one() { # stub_return_one <slice-file> <hex-offset> <arch>
  case $3 in
    x86_64) printf '\xb8\x01\x00\x00\x00\xc3' ;;        # mov eax, 1; ret
    arm64)  printf '\x20\x00\x80\x52\xc0\x03\x5f\xd6' ;; # mov w0, #1; ret
    *)      return 1 ;;
  esac | dd of="$1" bs=1 seek=$((16#$2)) conv=notrunc 2>/dev/null
}

stub_tail_jump() { # stub_tail_jump <slice-file> <hex-src> <hex-dst> <arch>
  local src=$((16#$2)) dst=$((16#$3)) v hex bytes
  case $4 in
    x86_64) v=$(( (dst - (src + 5)) & 0xffffffff )); bytes='\xe9' ;;
    arm64)  v=$(( 0x14000000 | (((dst - src) >> 2) & 0x3ffffff) )); bytes='' ;;
    *)      return 1 ;;
  esac
  printf -v hex '%08x' "$v"
  printf '%b' "$bytes\\x${hex:6:2}\\x${hex:4:2}\\x${hex:2:2}\\x${hex:0:2}" |
    dd of="$1" bs=1 seek="$src" conv=notrunc 2>/dev/null
}

find_app_bundle() {
  find "$1" -maxdepth 2 -name "*.app" -print -quit 2>/dev/null
}

# Protein.framework: stub the license check
# Old builds export C functions, new builds compare
# -[PTAppController licenseBits] against -licenseBitsGoodly at every call site.

patch_protein_slice() { # patch_protein_slice <fat-bin> <slice-file> <arch>
  local bin=$1 slice=$2 arch=$3 bits goodly

  bits=$(nm_addr "$bin" "$arch" ' T _PTApplicationLicenseBits$')
  goodly=$(nm_addr "$bin" "$arch" ' T _PTApplicationLicenseBitsGoodly$')
  if [[ -n "$bits" && -n "$goodly" ]]; then
    stub_return_one "$slice" "$bits" "$arch"
    stub_return_one "$slice" "$goodly" "$arch"
    return 0
  fi

  bits=$(nm_addr "$bin" "$arch" ' t -[[]PTAppController licenseBits[]]$')
  goodly=$(nm_addr "$bin" "$arch" ' t -[[]PTAppController licenseBitsGoodly[]]$')
  if [[ -n "$bits" && -n "$goodly" ]]; then
    # make licenseBits return licenseBitsGoodly's value, so bits == goodly always
    stub_tail_jump "$slice" "$bits" "$goodly" "$arch"
    return 0
  fi

  return 1
}

patch_protein() {
  local fw=$1 bin="$1/Versions/A/Protein" tmpdir
  [[ -f "$bin" ]] || { err "Protein binary not found."; return 1; }

  log "Patching Protein.framework..."

  tmpdir=$(mktemp -d) || return 1
  if ! split_fat "$bin" "$tmpdir"; then
    rm -rf "$tmpdir"; err "Failed to extract slices."; return 1
  fi

  local arch slice
  for arch in x86_64 arm64; do
    [[ $arch == x86_64 ]] && slice=x64 || slice=arm
    if ! patch_protein_slice "$bin" "$tmpdir/$slice" "$arch"; then
      rm -rf "$tmpdir"; err "License check symbols not found ($arch)."; return 1
    fi
  done

  if ! join_fat "$tmpdir" "$bin"; then
    rm -rf "$tmpdir"; err "Failed to reassemble universal binary."; return 1
  fi

  rm -rf "$tmpdir"
  log "Protein.framework patched."
}

apply_license_html() {
  local fw=$1 html_dir
  html_dir=$(find "$fw" -type d -name "LicenseWindow" -print -quit 2>/dev/null)

  if [[ -z "$html_dir" || ! -f "$html_dir/license.html" ]]; then
    warn "License HTML not found, skipping."
    return 0
  fi

  cat > "$html_dir/license.html" <<'HTML_EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<link href="style.css" rel="stylesheet">
<title>License</title>
<style>
  html, body { height: 100%; margin: 0; }
  .wrap {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100vh;
    text-align: center;
    padding: 40px;
    box-sizing: border-box;
  }
  .check {
    font-size: 72px;
    color: #34c759;
    margin-bottom: 14px;
  }
  .wrap h1 {
    font-size: 44px;
    font-weight: 700;
    margin: 0 0 6px 0;
    letter-spacing: -0.5px;
  }
  .wrap .sub {
    font-size: 16px;
    opacity: 0.65;
    margin: 0;
  }
  .tag {
    margin-top: 28px;
    font-size: 12px;
    opacity: 0.45;
    letter-spacing: 0.5px;
  }
</style>
</head>
<body>
  <div class="wrap">
    <div class="check">&#10003;</div>
    <h1>Cracked by pgtable</h1>
    <p class="sub">Fully unlocked. No license required.</p>
    <p class="tag">Rogue Amoeba licensing bypassed.</p>
  </div>
</body>
</html>
HTML_EOF
}

# Loopback 300% volume

apply_loopback_volume() {
  local app=$1
  log "Applying Loopback 300% volume..."

  local tpl="$app/Contents/Resources/Templates.json"
  if [[ -f "$tpl" ]]; then
    sed -i '' 's/gxRangeMax: 100,/gxRangeMax: 300,/' "$tpl"
    log "Slider range bumped to 300%."
  else
    warn "Templates.json not found, slider cap unchanged."
  fi

  local acp_fw
  acp_fw=$(find "$app/Contents/Frameworks" -maxdepth 1 -type d -name "ACP.framework" -print -quit 2>/dev/null)
  if [[ -z "$acp_fw" ]]; then
    warn "ACP.framework not found, audio clamp unchanged."
    return 0
  fi

  local acp_bin="$acp_fw/Versions/A/ACP"
  [[ -f "$acp_bin" ]] || { warn "ACP binary not found."; return 0; }

  patch_acp "$acp_bin"
}

patch_acp() {
  local bin=$1 tmpdir
  tmpdir=$(mktemp -d) || return 1

  lipo -thin x86_64 "$bin" -output "$tmpdir/x64" 2>/dev/null
  lipo -thin arm64  "$bin" -output "$tmpdir/arm" 2>/dev/null

  local x64_player x64_source arm_player arm_source
  x64_player=$(nm_addr "$bin" x86_64 '^[0-9a-f]+ t -[[]ACPPlayer setVolume:[]]$')
  x64_source=$(nm_addr "$bin" x86_64 '^[0-9a-f]+ t -[[]ACPSource setVolume:[]]$')
  arm_player=$(nm_addr "$bin" arm64  '^[0-9a-f]+ t -[[]ACPPlayer setVolume:[]]$')
  arm_source=$(nm_addr "$bin" arm64  '^[0-9a-f]+ t -[[]ACPSource setVolume:[]]$')

  if [[ -z "$x64_player" && -z "$arm_player" ]]; then
    rm -rf "$tmpdir"
    warn "setVolume: symbols not found in this build. Skipping ACP patch."
    return 0
  fi

  python3 - "$tmpdir/arm" "$arm_player" "$arm_source" "$tmpdir/x64" "$x64_player" "$x64_source" <<'PY_EOF'
import os
import sys

arm_path, arm_p, arm_s, x64_path, x64_p, x64_s = sys.argv[1:7]

def patch_arm(path, addrs):
    if not any(addrs) or not os.path.exists(path):
        return
    with open(path, "rb") as f:
        data = bytearray(f.read())
    # fmov d2, #1.0  ->  fmov d2, #3.0
    pat = bytes.fromhex("02106e1e")
    rep = bytes.fromhex("0210611e")
    for a in addrs:
        if not a:
            continue
        off = int(a, 16)
        idx = data.find(pat, off, off + 80)
        if idx < 0:
            sys.stderr.write(f"WARN: arm fmov pattern not found at {off:#x}\n")
            continue
        data[idx:idx+4] = rep
    with open(path, "wb") as f:
        f.write(data)

def patch_x64(path, addrs):
    if not any(addrs) or not os.path.exists(path):
        return
    with open(path, "rb") as f:
        data = bytearray(f.read())
    # cmpltsd -> cmpunordsd, imm8 0x01 -> 0x03
    for a in addrs:
        if not a:
            continue
        off = int(a, 16)
        region = data[off:off+120]
        i = 0
        patched = False
        while i < len(region) - 5:
            if region[i] in (0x66, 0xF2, 0xF3) and region[i+1] == 0x0F and region[i+2] == 0xC2 and region[i+4] == 0x01:
                data[off+i+4] = 0x03
                patched = True
                break
            i += 1
        if not patched:
            sys.stderr.write(f"WARN: x64 cmp*sd not found at {off:#x}\n")
    with open(path, "wb") as f:
        f.write(data)

patch_arm(arm_path, [arm_p, arm_s])
patch_x64(x64_path, [x64_p, x64_s])
print("OK")
PY_EOF

  if ! join_fat "$tmpdir" "$bin"; then
    rm -rf "$tmpdir"; err "Failed to reassemble ACP."; return 1
  fi
  rm -rf "$tmpdir"
  log "Volume clamps removed."
}

# Install

resign() {
  log "Re-signing..."
  codesign --force --deep --sign - "$1" >/dev/null 2>&1
  xattr -dr com.apple.quarantine "$1" >/dev/null 2>&1 || true
}

quit_if_running() {
  if pgrep -f "$1/Contents/MacOS" >/dev/null 2>&1; then
    log "Quitting running $(basename "$1" .app)..."
    pkill -f "$1/Contents/MacOS" 2>/dev/null || true
    sleep 2
  fi
}

# Crack

crack_app() {
  local entry=$1
  local name bundle url
  name=$(app_name "$entry")
  bundle=$(app_bundle "$entry")
  url=$(app_url "$entry")
  local dest="$INSTALL_DIR/$bundle"

  title "Cracking $name"
  quit_if_running "$bundle"

  local work
  work=$(mktemp -d) || { err "mktemp failed."; return 1; }

  log "Downloading $name..."
  if ! curl -fsSL --progress-bar "$url" -o "$work/app.zip"; then
    rm -rf "$work"; err "Download failed."; return 1
  fi

  if ! unzip -q "$work/app.zip" -d "$work"; then
    rm -rf "$work"; err "Extraction failed."; return 1
  fi

  local app
  app=$(find_app_bundle "$work")
  if [[ -z "$app" ]]; then
    rm -rf "$work"; err "App bundle not found in archive."; return 1
  fi

  local protein_fw
  protein_fw=$(find "$app/Contents/Frameworks" -maxdepth 1 -type d -name "Protein.framework" -print -quit 2>/dev/null)
  if [[ -z "$protein_fw" ]]; then
    rm -rf "$work"; err "Protein.framework not found. This app may not be supported."; return 1
  fi

  if ! patch_protein "$protein_fw"; then
    rm -rf "$work"; err "Protein patch failed."; return 1
  fi

  apply_license_html "$protein_fw"

  if (( LB_MOD )) && [[ $name == "Loopback" ]]; then
    apply_loopback_volume "$app"
  fi

  resign "$app"

  log "Installing to $dest..."
  if [[ -d "$dest" ]] && ! rm -rf "$dest"; then
    rm -rf "$work"; err "Cannot remove existing $dest. Quit the app first."; return 1
  fi
  cp -R "$app" "$dest"

  rm -rf "$work"
  log "$name cracked and installed."
}

# Main

main() {
  check_env
  trap 'printf "\033[?25h"' EXIT

  if ! tui_pick; then
    echo "Aborted."
    exit 0
  fi

  local picks=() names=() i
  for i in "${!APPS[@]}"; do
    if (( SELECTED[i] )); then
      picks+=("${APPS[i]}")
      names+=("$(app_name "${APPS[i]}")")
    fi
  done

  local names_str
  printf -v names_str ', %s' "${names[@]}"
  title "Will crack: ${names_str:2}"

  if (( LB_MOD )); then
    if (( SELECTED[LB_INDEX] )); then
      log "With: Loopback 300% volume mod"
    else
      warn "Loopback mod enabled but Loopback not selected, ignoring."
    fi
  fi
  echo

  local failures=0 entry
  for entry in "${picks[@]}"; do
    crack_app "$entry" || ((failures += 1))
  done

  title "Done"
  if (( failures == 0 )); then
    log "All selected apps cracked."
  else
    warn "$failures app(s) failed. See output above."
  fi
  echo
  log "Cracked by pgtable."
}

main "$@"
