# Test Flows

This directory contains three common verification flows:

- `drc`: run Magic and KLayout DRC checks
- `lvs`: extract a layout netlist and compare it against the schematic with Netgen
- `postlayout_sim`: extract a post-layout SPICE netlist and run ngspice

All flows assume there is exactly one `.gds` file in the project `gds/` directory. If more than one GDS file is present, the scripts stop and ask you to choose explicitly.

## DRC

The DRC flow is located in `test/drc`.

Run it from the terminal:

```bash
cd test/drc
git clone https://github.com/efabless/mpw_precheck
./run.sh
```

This command automatically:

- finds the single GDS file in `../../gds`
- uses the GDS filename as the top cell name
- runs Magic DRC
- runs KLayout DRC

Generated reports are written to `test/drc/drc_reports/`.

If needed, you can still call it explicitly:

```bash
cd test/drc
./run.sh ../../gds/tt_um_analog_ota_v3_IEEE.gds tt_um_analog_ota_v3_IEEE
```

## LVS

The LVS flow is located in `test/lvs`.

It is split into two steps so you can inspect or manually edit the extracted SPICE before running Netgen.

1. Extract the layout SPICE:

```bash
cd test/lvs
bash run.sh extract
```

This generates the raw extracted netlist in:

```bash
test/lvs/work/tt_um_analog_ota_v3_IEEE.spice
```

2. Run LVS:

```bash
cd test/lvs
bash run.sh run
```

This creates:

- a filtered LVS netlist in `test/lvs/work/*.lvs.spice`
- the Netgen report in `test/lvs/work/comp.out`

You can also run both steps together:

```bash
cd test/lvs
bash run.sh all
```

## Post-Layout Simulation

The post-layout simulation flow is located in `test/postlayout_sim`.

First extract the post-layout SPICE:

```bash
cd test/postlayout_sim
make extract
```

This step:

- reads the GDS with Magic
- performs extraction
- runs `extresist`
- writes the extracted SPICE into `test/postlayout_sim/work/`
- creates a temporary simulation netlist for ngspice

Then run the simulation:

```bash
cd test/postlayout_sim
make run
```

Useful output files:

- `test/postlayout_sim/work/magic.log`
- `test/postlayout_sim/work/tt_um_analog_ota_v3_IEEE.spice`
- `test/postlayout_sim/work/ngspice.log`
- `test/postlayout_sim/work/miller_ota_postLayout_test_trans_run.sp`

To remove generated files:

```bash
cd test/postlayout_sim
make clean
```
