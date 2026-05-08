v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N -190 20 -150 20 {lab=#net1}
N -90 20 -60 20 {lab=#net2}
N 60 0 240 0 {lab=out}
N 240 0 240 40 {lab=out}
N 240 100 240 140 {lab=0}
N 240 0 330 -0 {lab=out}
N -370 -90 -370 -0 {lab=vdd}
N -370 60 -370 140 {lab=0}
N 20 60 20 140 {lab=0}
N 20 50 20 60 {lab=0}
N 20 -160 20 -50 {lab=vdd}
N -370 -130 -370 -90 {lab=vdd}
N -370 -140 -370 -130 {lab=vdd}
N -370 -150 -370 -140 {lab=vdd}
N -120 -20 -60 -20 {lab=out}
N -120 -230 -120 -20 {lab=out}
N -120 -230 180 -230 {lab=out}
N 180 -230 180 -0 {lab=out}
N -250 100 -250 140 {lab=0}
N -250 20 -190 20 {lab=#net1}
N -250 20 -250 40 {lab=#net1}
C {miller_ota.sym} -40 0 0 0 {name=x1}
C {gnd.sym} -250 140 0 0 {name=l1 lab=0}
C {vsource.sym} -250 70 0 0 {name=V2 value="pulse(0.4 1 10n 0.1n 0.1n 5000n 10000n 1)" savecurrent=false}
C {res.sym} -120 20 1 0 {name=R1
value=10k
footprint=1206
device=resistor
m=1}
C {capa.sym} 240 70 0 0 {name=C1
m=1
value=3p
footprint=1206
device="ceramic capacitor"}
C {gnd.sym} 240 140 0 0 {name=l3 lab=0}
C {lab_pin.sym} 330 0 2 0 {name=p1 sig_type=std_logic lab=out}
C {code_shown.sym} 300 50 0 0 {name=SPICE only_toplevel=false value=".tran 100p 10000n
.save all
.control
run
plot  v(out)
.endc

.end"}
C {vsource.sym} -370 30 0 0 {name=V3 value=1.8 savecurrent=false}
C {gnd.sym} -370 140 0 0 {name=l4 lab=0}
C {gnd.sym} 20 140 0 0 {name=l5 lab=0}
C {lab_pin.sym} 20 -160 1 0 {name=p2 sig_type=std_logic lab=vdd}
C {lab_pin.sym} -370 -150 1 0 {name=p3 sig_type=std_logic lab=vdd}
C {sky130_fd_pr/corner.sym} -300 -210 0 0 {name=CORNER only_toplevel=false corner=tt}
