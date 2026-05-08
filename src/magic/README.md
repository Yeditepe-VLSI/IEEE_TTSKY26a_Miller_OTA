load TOP_CELL_NAME
select top cell
extract all

ext2spice lvs
ext2spice hierarchy off
ext2spice subcircuits off
ext2spice scale off
ext2spice -o TOP_flat.spice
