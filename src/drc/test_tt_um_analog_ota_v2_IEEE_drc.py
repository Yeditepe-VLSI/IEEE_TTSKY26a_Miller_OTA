from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
GDS_PATH = REPO_ROOT / "gds" / "tt_um_analog_ota_v2_IEEE.gds"
MAGIC_RC = Path(__file__).with_name("sky130A.magicrc")
TOP_CELL = "tt_um_analog_ota_v2_IEEE"


def _find_pdk_root() -> Path | None:
    candidates: list[Path] = []
    for env_name in ("PDKPATH", "PDK_PATH"):
        env_value = os.environ.get(env_name)
        if env_value:
            candidates.append(Path(env_value))

    candidates.extend(
        [
            Path("/usr/local/share/pdk/sky130A"),
            Path("/usr/share/pdk/sky130A"),
            Path("/opt/pdk/sky130A"),
        ]
    )

    for candidate in candidates:
        if (candidate / "libs.tech/magic/sky130A.tech").is_file():
            return candidate
    return None


def _build_magic_drc_script(report_path: Path) -> str:
    return textwrap.dedent(
        f"""
        crashbackups stop
        drc euclidean on
        drc style drc(full)
        drc on
        snap internal
        gds flatglob *__example_*
        gds flatten true
        gds read {{{GDS_PATH}}}
        load {{{TOP_CELL}}}
        select top cell
        expand
        drc catchup
        set allerrors [drc listall why]
        set oscale [cif scale out]
        set ofile [open {{{report_path}}} w]
        puts $ofile "DRC errors for cell {TOP_CELL}"
        puts $ofile "--------------------------------------------"
        foreach {{whytext rectlist}} $allerrors {{
            puts $ofile ""
            puts $ofile $whytext
            foreach rect $rectlist {{
                set llx [format "%.3f" [expr $oscale * [lindex $rect 0]]]
                set lly [format "%.3f" [expr $oscale * [lindex $rect 1]]]
                set urx [format "%.3f" [expr $oscale * [lindex $rect 2]]]
                set ury [format "%.3f" [expr $oscale * [lindex $rect 3]]]
                puts $ofile "$llx $lly $urx $ury"
            }}
        }}
        close $ofile
        quit -noprompt
        """
    ).strip() + "\n"


def _report_has_drc_errors(report_text: str) -> bool:
    lines = report_text.splitlines()
    return any(line.strip() for line in lines[2:])


class TestAnalogOtaV2IeeeDrc(unittest.TestCase):
    def test_magic_drc_clean_for_gds(self) -> None:
        if not GDS_PATH.is_file():
            self.skipTest(f"GDS bulunamadi: {GDS_PATH}")

        if not MAGIC_RC.is_file():
            self.skipTest(f"Magic rc dosyasi bulunamadi: {MAGIC_RC}")

        magic_bin = shutil.which("magic")
        if magic_bin is None:
            self.skipTest("magic binary PATH icinde bulunamadi.")

        pdk_root = _find_pdk_root()
        if pdk_root is None:
            self.skipTest("Sky130A PDK yolu bulunamadi.")

        with tempfile.TemporaryDirectory(prefix="magic-drc-") as temp_dir:
            temp_path = Path(temp_dir)
            report_path = temp_path / f"{TOP_CELL}_drc.txt"
            script_path = temp_path / "run_magic_drc.tcl"
            script_path.write_text(_build_magic_drc_script(report_path))

            env = os.environ.copy()
            env.setdefault("PDK_PATH", str(pdk_root))
            env.setdefault("PDKPATH", str(pdk_root))
            env.setdefault("MAGTYPE", "mag")

            result = subprocess.run(
                [magic_bin, "-dnull", "-noconsole", "-rcfile", str(MAGIC_RC), str(script_path)],
                cwd=temp_path,
                env=env,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
            )

            if result.returncode != 0:
                self.fail(
                    "magic DRC komutu basarisiz oldu.\n"
                    f"Komut: {' '.join(result.args)}\n"
                    f"stdout:\n{result.stdout}\n"
                    f"stderr:\n{result.stderr}"
                )

            self.assertTrue(
                report_path.is_file(),
                f"DRC raporu uretilmedi.\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}",
            )

            report_text = report_path.read_text()
            self.assertFalse(
                _report_has_drc_errors(report_text),
                "Magic DRC ihlalleri bulundu.\n"
                f"Rapor:\n{report_text}\n"
                f"stdout:\n{result.stdout}\n"
                f"stderr:\n{result.stderr}",
            )


if __name__ == "__main__":
    unittest.main()
