#!/usr/bin/env bash
set -Eeuo pipefail

# Usage:
#   ./run.sh
#   ./run.sh <layout.gds|layout.mag> <top_cell> [out_dir]
#
# Optional:
#   export KLAYOUT_DRC_DECK=/path/to/sky130A_mr.drc
#   export MAGIC_RC=/usr/share/pdk/sky130A/libs.tech/magic/sky130A.magicrc
#   export THREADS=8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAGIC_TCL="$SCRIPT_DIR/magic_sky130_drc.tcl"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEFAULT_GDS_DIR="$ROOT_DIR/gds"

find_single_gds() {
    mapfile -t gds_files < <(find "$DEFAULT_GDS_DIR" -maxdepth 1 -type f -name '*.gds' | sort)

    if [[ "${#gds_files[@]}" -eq 0 ]]; then
        echo "ERROR: No .gds file found in $DEFAULT_GDS_DIR"
        exit 2
    fi

    if [[ "${#gds_files[@]}" -gt 1 ]]; then
        echo "ERROR: Multiple .gds files found in $DEFAULT_GDS_DIR"
        printf '  %s\n' "${gds_files[@]}"
        echo "Please call: $0 <layout.gds|layout.mag> <top_cell> [out_dir]"
        exit 2
    fi

    LAYOUT="$(realpath "${gds_files[0]}")"
    TOP="$(basename "$LAYOUT" .gds)"
}

if [[ $# -eq 0 ]]; then
    find_single_gds
    OUT_DIR="drc_reports"
elif [[ $# -ge 2 ]]; then
    LAYOUT="$(realpath "$1")"
    TOP="$2"
    OUT_DIR="${3:-drc_reports}"
else
    echo "Usage: $0 [<layout.gds|layout.mag> <top_cell> [out_dir]]"
    exit 2
fi

mkdir -p "$OUT_DIR"

PDK_ROOT="${PDK_ROOT:-/usr/local/share/pdk}"
PDK="${PDK:-sky130A}"

MAGIC_RC="${MAGIC_RC:-$PDK_ROOT/$PDK/libs.tech/magic/sky130A.magicrc}"
THREADS="${THREADS:-$(nproc)}"

echo "== SKY130 DRC =="
echo "Layout     : $LAYOUT"
echo "Top cell   : $TOP"
echo "PDK_ROOT   : $PDK_ROOT"
echo "PDK        : $PDK"
echo "Output dir : $OUT_DIR"
echo

###############################################################################
# Magic DRC
###############################################################################

if [[ ! -f "$MAGIC_RC" ]]; then
    echo "ERROR: Magic rc file not found:"
    echo "  $MAGIC_RC"
    echo "Set MAGIC_RC manually."
    exit 2
fi

if [[ ! -f "$MAGIC_TCL" ]]; then
    echo "ERROR: Magic TCL script not found:"
    echo "  $MAGIC_TCL"
    exit 2
fi

echo "== Running Magic DRC =="

export MAGIC_INPUT="$LAYOUT"
export MAGIC_TOP="$TOP"
export MAGIC_OUT_DIR="$(realpath "$OUT_DIR")"
export MAGIC_DO_EXTRACT="${MAGIC_DO_EXTRACT:-1}"

set +e
magic -dnull -noconsole -rcfile "$MAGIC_RC" "$MAGIC_TCL" \
    2>&1 | tee "$OUT_DIR/${TOP}.magic_drc.log"
MAGIC_STATUS="${PIPESTATUS[0]}"
set -e

echo "Magic DRC exit code: $MAGIC_STATUS"
echo

###############################################################################
# KLayout DRC
###############################################################################

find_klayout_deck() {
    local candidates=(
        "${KLAYOUT_DRC_DECK:-}"
        "$PDK_ROOT/$PDK/libs.tech/klayout/drc/sky130.lydrc"
        "$PDK_ROOT/$PDK/libs.tech/klayout/drc/sky130A.lydrc"
        "$PDK_ROOT/$PDK/libs.tech/klayout/drc/sky130A_mr.drc"
        "$PDK_ROOT/$PDK/libs.tech/klayout/tech-files/sky130A_mr.drc"
        "$PDK_ROOT/$PDK/libs.tech/klayout/tech/sky130/drc/sky130.lydrc"
        "$PDK_ROOT/$PDK/libs.tech/klayout/tech/sky130A/drc/sky130.lydrc"
        "./sky130A_mr.drc"
        "./drc/sky130A_mr.drc"
        "./mpw_precheck/checks/tech-files/sky130A_mr.drc"
    )

    for f in "${candidates[@]}"; do
        [[ -n "$f" && -f "$f" ]] && {
            realpath "$f"
            return 0
        }
    done

    return 1
}

if ! command -v klayout >/dev/null 2>&1; then
    echo "WARNING: klayout command not found. Skipping KLayout DRC."
    exit "$MAGIC_STATUS"
fi

if ! KLAYOUT_DECK="$(find_klayout_deck)"; then
    echo "WARNING: KLayout SKY130 DRC deck not found. Skipping KLayout DRC."
    echo
    echo "You can install/use mpw_precheck deck, for example:"
    echo "  git clone https://github.com/efabless/mpw_precheck"
    echo "  export KLAYOUT_DRC_DECK=\$PWD/mpw_precheck/checks/tech-files/sky130A_mr.drc"
    exit "$MAGIC_STATUS"
fi

echo "== Running KLayout DRC =="
echo "Deck: $KLAYOUT_DECK"

KLAYOUT_PATH="${KLAYOUT_PATH:-$PDK_ROOT/$PDK/libs.tech/klayout}"
export KLAYOUT_PATH

KLAYOUT_REPORT="$OUT_DIR/${TOP}.klayout_drc.lyrdb"
KLAYOUT_LOG="$OUT_DIR/${TOP}.klayout_drc.log"

set +e
klayout -b \
    -r "$KLAYOUT_DECK" \
    -rd input="$LAYOUT" \
    -rd top_cell="$TOP" \
    -rd report="$KLAYOUT_REPORT" \
    -rd feol=true \
    -rd beol=true \
    -rd offgrid=true \
    -rd floating_met=true \
    -rd sram_exclude=false \
    -rd seal=false \
    -rd thr="$THREADS" \
    2>&1 | tee "$KLAYOUT_LOG"
KLAYOUT_STATUS="${PIPESTATUS[0]}"
set -e

echo
echo "== DRC summary =="
echo "Magic log       : $OUT_DIR/${TOP}.magic_drc.log"
echo "Magic report    : $OUT_DIR/${TOP}.magic_drc.txt"
echo "Magic feedback  : $OUT_DIR/${TOP}.magic_feedback.tcl"
echo "KLayout log     : $KLAYOUT_LOG"
echo "KLayout report  : $KLAYOUT_REPORT"
echo
echo "Magic exit code  : $MAGIC_STATUS"
echo "KLayout exit code: $KLAYOUT_STATUS"

if [[ "$MAGIC_STATUS" -ne 0 || "$KLAYOUT_STATUS" -ne 0 ]]; then
    exit 1
fi
