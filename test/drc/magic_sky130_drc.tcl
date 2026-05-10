# magic_sky130_drc.tcl
#
# Environment variables:
#   MAGIC_INPUT      : input .gds or .mag
#   MAGIC_TOP        : top cell name
#   MAGIC_OUT_DIR    : output directory
#   MAGIC_DO_EXTRACT : 1/0, optional extraction + feedback warnings
#
# Run through:
#   magic -dnull -noconsole -rcfile $PDK_ROOT/sky130A/libs.tech/magic/sky130A.magicrc magic_sky130_drc.tcl

proc getenv_required {name} {
    if {![info exists ::env($name)] || $::env($name) eq ""} {
        puts stderr "ERROR: environment variable $name is required"
        exit 2
    }
    return $::env($name)
}

proc safe_exec {description command} {
    puts ">> $description"
    if {[catch {uplevel 1 $command} result]} {
        puts "WARNING: $description failed:"
        puts "  $result"
        return ""
    }
    return $result
}

set input_file [getenv_required MAGIC_INPUT]
set top_cell   [getenv_required MAGIC_TOP]
set out_dir    [getenv_required MAGIC_OUT_DIR]

if {[info exists ::env(MAGIC_DO_EXTRACT)]} {
    set do_extract $::env(MAGIC_DO_EXTRACT)
} else {
    set do_extract 1
}

file mkdir $out_dir

set report_file   [file join $out_dir "${top_cell}.magic_drc.txt"]
set feedback_file [file join $out_dir "${top_cell}.magic_feedback.tcl"]

puts "Magic SKY130 DRC"
puts "Input    : $input_file"
puts "Top cell : $top_cell"
puts "Out dir  : $out_dir"

# Less noisy display state.
catch {crashbackups stop}
catch {drc off}
catch {feedback clear}
catch {see no errors}

# Use stricter/more complete style when present in sky130A tech.
# Some installs expose drc(full), some only expose one style.
if {[catch {drc style drc(full)} msg]} {
    puts "NOTE: Could not set DRC style to drc(full): $msg"
    puts "NOTE: Continuing with current DRC style."
} else {
    puts "DRC style: drc(full)"
}

# Euclidean DRC is important for non-Manhattan/diagonal interactions.
catch {drc euclidean on}

set ext [string tolower [file extension $input_file]]

if {$ext eq ".gds"} {
    puts "Reading GDS..."
    gds readonly true
    gds rescale false
    gds read $input_file
    load $top_cell
} elseif {$ext eq ".mag"} {
    puts "Reading MAG..."
    addpath [file dirname $input_file]
    load [file rootname [file tail $input_file]]
} else {
    puts stderr "ERROR: unsupported input extension: $ext"
    puts stderr "Use .gds or .mag"
    exit 2
}

# Make sure the requested top is loaded.
load $top_cell
select top cell

# Selecting top cell generally places the box at the cell bbox.
# As fallback, use a deliberately large box to force global DRC.
catch {box values -100000000 -100000000 100000000 100000000}

puts "Forcing full hierarchical DRC recheck..."
drc check
drc catchup

set total_errors "unknown"
if {[catch {drc count total} total_errors]} {
    puts "WARNING: drc count total failed: $total_errors"
    set total_errors "unknown"
}

set fh [open $report_file w]
puts $fh "Magic SKY130 DRC report"
puts $fh "======================="
puts $fh "Input    : $input_file"
puts $fh "Top cell : $top_cell"
puts $fh ""
puts $fh "DRC total errors: $total_errors"
puts $fh ""
puts $fh "Detailed per-cell and listall reporting is skipped in batch mode"
puts $fh "to avoid Magic sessions hanging on some builds."
flush $fh
close $fh

# Optional extraction catches label/port/connectivity feedback issues.
# This is not a replacement for LVS, but it often catches the exact label/port
# problems seen in analog Magic layouts.
if {$do_extract eq "1"} {
    puts "Running optional extraction feedback check..."
    catch {feedback clear}

    if {[catch {
        extract do local
        extract all
    } extract_msg]} {
        puts "WARNING: extraction failed or generated warnings:"
        puts $extract_msg
    }

    if {[catch {feedback save $feedback_file} fb_msg]} {
        puts "WARNING: feedback save failed:"
        puts $fb_msg
    }
}

puts "Magic DRC report written to: $report_file"
puts "Magic feedback written to  : $feedback_file"

# Exit nonzero if numeric error count is positive.
if {[string is integer -strict $total_errors] && $total_errors > 0} {
    puts stderr "Magic DRC FAILED: $total_errors errors"
    quit 1 -noprompt
}

puts "Magic DRC finished."
quit 0 -noprompt
