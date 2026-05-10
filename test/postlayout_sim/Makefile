SHELL := /bin/bash

ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/../..)
TEST_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
WORK_DIR := $(TEST_DIR)/work
GDS_DIR := $(ROOT_DIR)/gds
MAGIC_RC := $(ROOT_DIR)/src/magic2/.magicrc
TEST_SPICE_TEMPLATE := $(TEST_DIR)/miller_ota_postLayout_test_trans.sp
TEST_SPICE_RUN := $(WORK_DIR)/miller_ota_postLayout_test_trans_run.sp
MAGIC_LOG := $(WORK_DIR)/magic.log
NGSPICE_LOG := $(WORK_DIR)/ngspice.log

.PHONY: all extract run clean

all: run

# Adim 1:
# - Sadece ./gds klasorundeki .gds dosyalarina bak.
# - 0 dosya varsa hata ver.
# - 1'den fazla dosya varsa uyari ver ve dur.
#
# Adim 2:
# - Tek bulunan GDS dosyasini headless magic ile ac.
# - Kullanici tarafindan istenen extract/ext2sim/extresist/ext2spice
#   komutlarini ayni sirada calistir.
# - Magic ciktilarini magic.log dosyasina yaz.
#
# Adim 3:
# - Uretilen tum otomatik dosyalari work/ altinda tut.
# - Kalici .sp testbench dosyasini degistirme.
# - Onun yerine bir kopya olusturup $gds_out$ alanlarini o kopyada doldur.
extract:
	@set -euo pipefail; \
	mapfile -t gds_files < <(find "$(GDS_DIR)" -maxdepth 1 -type f -name '*.gds' | sort); \
	if [ "$${#gds_files[@]}" -eq 0 ]; then \
		echo "Hata: $(GDS_DIR) klasoru icinde .gds dosyasi bulunamadi."; \
		exit 1; \
	fi; \
	if [ "$${#gds_files[@]}" -gt 1 ]; then \
		echo "Uyari: $(GDS_DIR) klasoru icinde birden fazla .gds dosyasi bulundu. Islem durduruldu."; \
		printf '  %s\n' "$${gds_files[@]}"; \
		exit 1; \
	fi; \
	gds_path="$${gds_files[0]}"; \
	gds_name="$$(basename "$$gds_path" .gds)"; \
	echo "Kullanilan GDS: $$gds_path"; \
	mkdir -p "$(WORK_DIR)"; \
	rm -f "$(TEST_DIR)/magic.log" "$(TEST_DIR)/ngspice.log" "$(TEST_DIR)/miller_ota_postLayout_test_trans_run.sp"; \
	rm -f "$(TEST_DIR)/$$gds_name.ext" "$(TEST_DIR)/$$gds_name.res.ext" "$(TEST_DIR)/$$gds_name.sim" "$(TEST_DIR)/$$gds_name.spice" "$(TEST_DIR)/$$gds_name.nodes"; \
	rm -f "$(MAGIC_LOG)" "$(TEST_SPICE_RUN)" "$(WORK_DIR)/$$gds_name.ext" "$(WORK_DIR)/$$gds_name.res.ext" "$(WORK_DIR)/$$gds_name.sim" "$(WORK_DIR)/$$gds_name.spice" "$(WORK_DIR)/$$gds_name.nodes"; \
	cd "$(WORK_DIR)"; \
	printf '%s\n' \
		"gds read $$gds_path" \
		"load $$gds_name" \
		"extract do local" \
		"extract all" \
		"select top cell" \
		"extresist tolerance 10" \
		"extresist" \
		"ext2spice lvs" \
		"ext2spice cthresh 0" \
		"ext2spice extresist on" \
		"ext2spice" \
		"quit -noprompt" \
	| magic -dnull -noconsole -rcfile "$(MAGIC_RC)" > "$(MAGIC_LOG)" 2>&1; \
	if [ ! -f "$(WORK_DIR)/$$gds_name.spice" ]; then \
		echo "Hata: Magic spice cikti dosyasini uretemedi: $(WORK_DIR)/$$gds_name.spice"; \
		echo "Detaylar icin $(MAGIC_LOG) dosyasina bak."; \
		exit 1; \
	fi; \
	sed -e 's|\$$gds_out\$$|'"$$gds_name"'|g' "$(TEST_SPICE_TEMPLATE)" > "$(TEST_SPICE_RUN)"; \
	echo "Calisma netlisti olusturuldu: $(TEST_SPICE_RUN)"; \
	echo "Magic log hazir: $(MAGIC_LOG)"

# Adim 4:
# - run hedefi extract olmadan calismaz.
# - Once extract tetiklenir, sonra ngspice olusturulan kopya netlisti
#   interaktif modda calistirir.
run: extract
	@set -euo pipefail; \
	include_file="$$(sed -n -E 's|^\.include[[:space:]]+(.+\.spice)$$|\1|p' "$(TEST_SPICE_RUN)" | head -n 1)"; \
	if [ -z "$$include_file" ]; then \
		echo "Hata: $(TEST_SPICE_RUN) icinde .include satiri bulunamadi."; \
		exit 1; \
	fi; \
	if [ ! -f "$(WORK_DIR)/$$include_file" ]; then \
		echo "Hata: Beklenen spice dosyasi bulunamadi: $(WORK_DIR)/$$include_file"; \
		exit 1; \
	fi; \
	expected_pins="$$(awk 'BEGIN {count = 0; capture = 0; printed = 0} \
		tolower($$1) == ".subckt" {capture = 1; for (i = 3; i <= NF; i++) count++; next} \
		capture && $$1 == "+" {for (i = 2; i <= NF; i++) count++; next} \
		capture {print count; printed = 1; exit} \
		END {if (capture && !printed) print count}' "$(WORK_DIR)/$$include_file")"; \
	actual_pins="$$(awk 'BEGIN {count = 0; capture = 0; printed = 0} \
		tolower($$1) == "x1" {capture = 1; count += NF - 2; next} \
		capture && $$1 == "+" {count += NF - 1; next} \
		capture {print count; printed = 1; exit} \
		END {if (capture && !printed) print count}' "$(TEST_SPICE_RUN)")"; \
	if [ -z "$$expected_pins" ] || [ -z "$$actual_pins" ]; then \
		echo "Hata: Subckt veya x1 baglanti sayisi okunamadi."; \
		exit 1; \
	fi; \
	if [ "$$expected_pins" != "$$actual_pins" ]; then \
		echo "Hata: x1 instance baglanti sayisi ile extracted subckt uyusmuyor."; \
		echo "Test netlist x1 baglanti sayisi: $$actual_pins"; \
		echo "Extracted subckt beklenen baglanti sayisi: $$expected_pins"; \
		echo "Testbench pin eslemesini guncellemeden ngspice calistirilamiyor."; \
		exit 1; \
	fi; \
	if [ -z "$${DISPLAY:-}" ]; then \
		echo "Hata: ngspice plot icin DISPLAY tanimli degil."; \
		echo "Non-batch modda plot kullanmak icin calisan bir X display gerekli."; \
		exit 1; \
	fi; \
	if command -v xdpyinfo >/dev/null 2>&1 && ! xdpyinfo >/dev/null 2>&1; then \
		echo "Hata: DISPLAY=$$DISPLAY erisilemiyor."; \
		echo "Non-batch ngspice plot icin calisan bir X display gerekli."; \
		exit 1; \
	fi; \
	cd "$(WORK_DIR)"; \
	echo "Ngspice interaktif modda aciliyor. Cikmak icin ngspice icinde 'quit' yazabilirsin."; \
	script -q -e -f -c "ngspice $(notdir $(TEST_SPICE_RUN))" "$(NGSPICE_LOG)"; \
	echo "Ngspice kapandi. Log: $(NGSPICE_LOG)"

clean:
	@mkdir -p "$(WORK_DIR)"
	@find "$(WORK_DIR)" -maxdepth 1 -type f -delete
	@find "$(TEST_DIR)" -maxdepth 1 -type f \
		\( -name 'magic.log' -o -name 'ngspice.log' -o -name 'miller_ota_postLayout_test_trans_run.sp' -o -name '*.ext' -o -name '*.res.ext' -o -name '*.sim' -o -name '*.nodes' -o -name '*.spice' \) \
		-delete
