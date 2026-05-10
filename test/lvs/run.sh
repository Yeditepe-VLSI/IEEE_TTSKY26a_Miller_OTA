#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORK_DIR="$SCRIPT_DIR/work"
GDS_DIR="$ROOT_DIR/gds"
MAGIC_RC="$ROOT_DIR/src/magic2/.magicrc"
SCHEMATIC_SPICE="$ROOT_DIR/src/miller_ota.sp"
SCHEMATIC_CIRCUIT="miller_ota"
LAYOUT_PIN_KEEP_LIST="VDPWR,ua[1],ua[0],VGND"
NETGEN_SETUP="/usr/local/share/pdk/sky130A/libs.tech/netgen/sky130A_setup.tcl"
MAGIC_LOG="$WORK_DIR/magic.log"
LVS_REPORT="$WORK_DIR/comp.out"

usage() {
	echo "Kullanim:"
	echo "  $0 extract   -> GDS'den ham extract spice uretir"
	echo "  $0 run       -> Mevcut extract spice dosyasini kullanip LVS calistirir"
	echo "  $0 all       -> extract ve run adimlarini birlikte yapar"
}

find_single_gds() {
	mapfile -t gds_files < <(find "$GDS_DIR" -maxdepth 1 -type f -name '*.gds' | sort)

	if [ "${#gds_files[@]}" -eq 0 ]; then
		echo "Hata: $GDS_DIR klasoru icinde .gds dosyasi bulunamadi."
		exit 1
	fi

	if [ "${#gds_files[@]}" -gt 1 ]; then
		echo "Hata: $GDS_DIR klasoru icinde birden fazla .gds dosyasi bulundu."
		printf '  %s\n' "${gds_files[@]}"
		exit 1
	fi

	gds_path="${gds_files[0]}"
	gds_name="$(basename "$gds_path" .gds)"
	raw_layout_spice="$WORK_DIR/$gds_name.spice"
	filtered_layout_spice="$WORK_DIR/$gds_name.lvs.spice"
}

filter_layout_spice() {
	local layout_circuit

	if [ ! -f "$raw_layout_spice" ]; then
		echo "Hata: Extract spice dosyasi bulunamadi: $raw_layout_spice"
		echo "Once '$0 extract' calistirabilir ya da dosyayi elle olusturabilirsin."
		exit 1
	fi

	layout_circuit="$(awk 'tolower($1) == ".subckt" { print $2; exit }' "$raw_layout_spice")"

	if [ -z "$layout_circuit" ]; then
		echo "Hata: Extract edilen spice dosyasinda .subckt adi bulunamadi."
		exit 1
	fi

	awk -v circuit="$layout_circuit" -v keep_list="$LAYOUT_PIN_KEEP_LIST" '
	BEGIN {
		header_written = 0
		entry_count = split(keep_list, entries, ",")
		for (i = 1; i <= entry_count; i++) {
			header = header " " entries[i]
		}
	}
	tolower($1) == ".subckt" {
		in_header = 1
		print ".subckt " circuit header
		header_written = 1
		next
	}
	in_header && $1 == "+" {
		next
	}
	{
		if (in_header) {
			in_header = 0
		}
		print
	}
	END {
		if (!header_written) {
			exit 1
		}
	}
	' "$raw_layout_spice" > "$filtered_layout_spice"

	if [ ! -s "$filtered_layout_spice" ]; then
		echo "Hata: Filtrelenmis LVS spice dosyasi olusturulamadi: $filtered_layout_spice"
		exit 1
	fi
}

do_extract() {
	find_single_gds
	mkdir -p "$WORK_DIR"
	rm -f \
		"$MAGIC_LOG" \
		"$WORK_DIR/$gds_name.ext" \
		"$WORK_DIR/$gds_name.res.ext" \
		"$WORK_DIR/$gds_name.nodes" \
		"$WORK_DIR/$gds_name.sim" \
		"$raw_layout_spice" \
		"$filtered_layout_spice"

	echo "Kullanilan GDS: $gds_path"

	(
		cd "$WORK_DIR"
		printf '%s\n' \
			"gds read $gds_path" \
			"load $gds_name" \
			"extract all" \
			"ext2spice lvs" \
			"ext2spice" \
			"quit -noprompt" \
		| magic -dnull -noconsole -rcfile "$MAGIC_RC" > "$MAGIC_LOG" 2>&1
	)

	if [ ! -f "$raw_layout_spice" ]; then
		echo "Hata: Extract sonrasi spice dosyasi uretilmedi: $raw_layout_spice"
		echo "Detaylar icin $MAGIC_LOG dosyasina bak."
		exit 1
	fi

	echo "Magic log: $MAGIC_LOG"
	echo "Ham extract spice: $raw_layout_spice"
}

do_run() {
	find_single_gds
	mkdir -p "$WORK_DIR"
	rm -f "$LVS_REPORT" "$filtered_layout_spice"

	filter_layout_spice

	local layout_circuit
	layout_circuit="$(awk 'tolower($1) == ".subckt" { print $2; exit }' "$filtered_layout_spice")"

	(
		cd "$WORK_DIR"
		netgen -batch lvs \
			"$SCHEMATIC_SPICE $SCHEMATIC_CIRCUIT" \
			"$filtered_layout_spice $layout_circuit" \
			"$NETGEN_SETUP" \
			"$LVS_REPORT"
	)

	echo "Ham extract spice: $raw_layout_spice"
	echo "Filtrelenmis LVS spice: $filtered_layout_spice"
	echo "LVS sonucu: $LVS_REPORT"
}

main() {
	local cmd="${1:-all}"

	case "$cmd" in
		extract)
			do_extract
			;;
		run)
			do_run
			;;
		all)
			do_extract
			do_run
			;;
		-h|--help|help)
			usage
			;;
		*)
			echo "Hata: Bilinmeyen komut '$cmd'"
			usage
			exit 1
			;;
	esac
}

main "$@"
