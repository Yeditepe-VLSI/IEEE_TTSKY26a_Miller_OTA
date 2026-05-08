v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 50 -0 220 -0 {lab=out}
N 200 -130 200 -0 {lab=out}
N -130 -130 200 -130 {lab=out}
N -130 -130 -130 -20 {lab=out}
N -130 -20 -70 -20 {lab=out}
N 10 -100 10 -50 {lab=VDPWR}
N 10 -100 110 -100 {lab=VDPWR}
N 10 50 10 100 {lab=VGND}
N 10 100 110 100 {lab=VGND}
N 220 0 250 0 {lab=out}
N -180 20 -70 20 {lab=ua[0]}
C {miller_ota.sym} -50 0 0 0 {name=x1}
C {iopin.sym} 110 -100 0 0 {name=p1 lab=VDPWR}
C {iopin.sym} 110 100 0 0 {name=p2 lab=VGND}
C {ipin.sym} -180 20 0 0 {name=p3 lab=ua[0]}
C {opin.sym} 250 0 0 0 {name=p4 lab=ua[1]}
