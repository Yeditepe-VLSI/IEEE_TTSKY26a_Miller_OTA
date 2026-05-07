filename: ex4-26.sp (3pF)
.options parser model_binning=true
*.lib /home/mert-cachy/.pdk/ciel/sky130/versions/7b70722e33c03fcb5dabcf4d479fb0822d9251c9/sky130A/libs.tech/ngspice/sky130.lib.spice tt
.lib /home/mert-cachy/.pdk/ciel/sky130/versions/7b70722e33c03fcb5dabcf4d479fb0822d9251c9/sky130A/libs.tech/ngspice/sky130.lib.spice tt


.option SCALE=1e-6
.option temp=25
.param sa=0 sb=0 sd=0 nf=1 m=1

.param w12=1.25 l12=0.5 m12=1
.param a12='w12 * 0.29' p12='2*(0.29 + w12)' nrd12='0.29 / w12'
.param w345=0.65 l345=2 m34=1 m5=30
.param a345='w345 * 0.29' p345='2*(0.29 + w345)' nrd345='0.29 / w345'
.param w67=5.3 l67=1 m6=1 m7=15
.param a7='w67 * 0.29' p7='2*(0.29 + w67)' nrd7='0.29 / w67'

***************ota subckt****fig.4.67(a)****************
.subckt ota 1 2 8
x1 4 2 3 3 sky130_fd_pr__pfet_01v8_lvt w=w12 l=l12
+ ad=a12 as=a12 pd=p12 ps=p12 nrd=nrd12 nrs=nrd12
+ sa=sa sb=sb sd=sd m=m12 nf=nf
x2 5 1 3 3 sky130_fd_pr__pfet_01v8_lvt w=w12 l=l12
+ ad=a12 as=a12 pd=p12 ps=p12 nrd=nrd12 nrs=nrd12
+ sa=sa sb=sb sd=sd m=m12 nf=nf
x3 4 4 0 0 sky130_fd_pr__nfet_01v8 w=w345 l=l345
+ ad=a345 as=a345 pd=p345 ps=p345 nrd=nrd345 nrs=nrd345
+ sa=sa sb=sb sd=sd nf=nf m=m34
x4 5 4 0 0 sky130_fd_pr__nfet_01v8 w=w345 l=l345
+ ad=a345 as=a345 pd=p345 ps=p345 nrd=nrd345 nrs=nrd345
+ sa=sa sb=sb sd=sd nf=nf m=m34
x5 8 5 0 0 sky130_fd_pr__nfet_01v8 w=w345 l=l345
+ ad=a345 as=a345 pd=p345 ps=p345 nrd=nrd345 nrs=nrd345
+ sa=sa sb=sb sd=sd nf=nf m=m5
x6 3 7 10 10 sky130_fd_pr__pfet_01v8 w=w67 l=l67
+ ad=a7 as=a7 pd=p7 ps=p7 nrd=nrd7 nrs=nrd7
+ sa=sa sb=sb sd=sd nf=nf m=m6
x7 8 7 10 10 sky130_fd_pr__pfet_01v8 w=w67 l=l67
+ ad=a7 as=a7 pd=p7 ps=p7 nrd=nrd7 nrs=nrd7
+ sa=sa sb=sb sd=sd nf=nf m=m7
x8 11 7 10 10 sky130_fd_pr__pfet_01v8 w=w67 l=l67
+ ad=a7 as=a7 pd=p7 ps=p7 nrd=nrd7 nrs=nrd7
+ sa=sa sb=sb sd=sd nf=nf m=m6
x9 11 11 12 0 sky130_fd_pr__nfet_01v8 w=w345 l=l345
+ ad=a345 as=a345 pd=p345 ps=p345 nrd=nrd345 nrs=nrd345
+ sa=sa sb=sb sd=sd nf=nf m=m34
x10 12 12 0 0 sky130_fd_pr__nfet_01v8 w=w345 l=l345
+ ad=a345 as=a345 pd=p345 ps=p345 nrd=nrd345 nrs=nrd345
+ sa=sa sb=sb sd=sd nf=nf m=m34
xc 9 11 5 0 sky130_fd_pr__nfet_01v8 w=w345 l=l345
+ ad=a345 as=a345 pd=p345 ps=p345 nrd=nrd345 nrs=nrd345
+ sa=sa sb=sb sd=sd nf=nf m=2
xr 7 7 10 10 sky130_fd_pr__pfet_01v8 w=w67 l=l67
+ ad=a7 as=a7 pd=p7 ps=p7 nrd=nrd7 nrs=nrd7
+ sa=sa sb=sb sd=sd nf=nf m=m6
iref 7 0 4.35u
cc 8 9 0.23p ; 0.23p
vdd 10 0 1.8
.ends ota
**************open-loop dc****fig.4.56(f)***************
x1 41 42 43 ota
vin1 42 0 0.7
vi1 40 0 dc
rs1 40 41 10k
cl1 43 0 3p

************loop gain****fig.4.56(h) and (i)************
x3 61 62 63 ota    ; for voltage return ratio
cla 62 0 3p        ; for voltage return ratio
via 60 0 dc 0.7    ; for voltage return ratio
rsa 60 61 10k      ; for voltage return ratio
vx 62 63 dc 0 ac 1 ; for voltage return ratio
x4 71 72 73 ota    ; for current return ratio
clb 72 0 3p        ; for current return ratio
vib 70 0 dc 0.7    ; for current return ratio
rsb 70 71 10k      ; for voltage return ratio
ix 0 74 dc 0 ac 1  ; for current return ratio
vs1 73 74 0        ; for current return ratio
vs2 74 72 0        ; for current return ratio
**************open-loop ac****fig.4.56(f)***************
x9 91 92 93 ota
vin9 92 0 0.7
vi9 90 0 dc 0.700057 ac 1
rs9 90 91 10k
cl9 93 0 3p
*************closed-loop ac****Fig.4.56(g)**************
x8 81 82 82 ota
vi8 80 0 dc 0.7 ac 1
rs8 80 81 10k
cl8 82 0 3p
**************transient****Fig.4.56(g)*****************
x2 51 52 52 ota
vi 50 0 pulse 0.6 1 10n 0.1n 0.1n 5000n 10000n 1
rs 50 51 10k
cl 52 0 3p
.save v(50) v(51) v(52) v(43) v(62) v(63) v(81) v(82) v(91) v(92) v(93) i(vs1) i(vs2)
+ @m.x2.x2.msky130_fd_pr__pfet_01v8_lvt[gm]
+ @m.x2.x2.msky130_fd_pr__pfet_01v8_lvt[id]
+ @m.x2.x2.msky130_fd_pr__pfet_01v8_lvt[gds]
+ @m.x2.x2.msky130_fd_pr__pfet_01v8_lvt[cds]
+ @m.x2.x2.msky130_fd_pr__pfet_01v8_lvt[cdg]
+ @m.x2.x4.msky130_fd_pr__nfet_01v8[cds]
+ @m.x2.x4.msky130_fd_pr__nfet_01v8[cdg]
+ @m.x2.x5.msky130_fd_pr__nfet_01v8[gm]
+ @m.x2.x5.msky130_fd_pr__nfet_01v8[id]
+ @m.x2.x5.msky130_fd_pr__nfet_01v8[gds]
+ @m.x2.x5.msky130_fd_pr__nfet_01v8[vdsat]
+ @m.x2.x5.msky130_fd_pr__nfet_01v8[cgd]
+ @m.x2.x5.msky130_fd_pr__nfet_01v8[cgs]
+ @m.x2.x5.msky130_fd_pr__nfet_01v8[cgb]
+ @m.x2.x5.msky130_fd_pr__nfet_01v8[cdb]
+ @m.x2.x5.msky130_fd_pr__nfet_01v8[cds]
+ @m.x2.x5.msky130_fd_pr__nfet_01v8[cgd]
+ @m.x2.x5.msky130_fd_pr__nfet_01v8[vdsat]
+ @m.x2.x7.msky130_fd_pr__pfet_01v8[id]
+ @m.x2.x7.msky130_fd_pr__pfet_01v8[gds]
+ @m.x2.x7.msky130_fd_pr__pfet_01v8[cdb]
+ @m.x2.x7.msky130_fd_pr__pfet_01v8[cds]
+ @m.x2.x7.msky130_fd_pr__pfet_01v8[cgd]
.control
set units = degrees
op
*show all
let va2=@m.x2.x2.msky130_fd_pr__pfet_01v8_lvt[id]/@m.x2.x2.msky130_fd_pr__pfet_01v8_lvt[gds]
let va4=@m.x2.x4.msky130_fd_pr__nfet_01v8[id]/@m.x2.x4.msky130_fd_pr__nfet_01v8[gds]
let va5=@m.x2.x5.msky130_fd_pr__nfet_01v8[id]/@m.x2.x5.msky130_fd_pr__nfet_01v8[gds]
let va7=@m.x2.x7.msky130_fd_pr__pfet_01v8[id]/@m.x2.x7.msky130_fd_pr__pfet_01v8[gds]
let gmeff2=@m.x2.x2.msky130_fd_pr__pfet_01v8_lvt[gm]/@m.x2.x2.msky130_fd_pr__pfet_01v8_lvt[id]
let gmeff5=@m.x2.x5.msky130_fd_pr__nfet_01v8[gm]/@m.x2.x5.msky130_fd_pr__nfet_01v8[id]
let c1 = abs(@m.x2.x2.msky130_fd_pr__pfet_01v8_lvt[cds])+abs(@m.x2.x2.msky130_fd_pr__pfet_01v8_lvt[cdg])+abs(@m.x2.x4.msky130_fd_pr__nfet_01v8[cds])+abs(@m.x2.x4.msky130_fd_pr__nfet_01v8[cdg])+abs(@m.x2.x5.msky130_fd_pr__nfet_01v8[cgs])+abs(@m.x2.x5.msky130_fd_pr__nfet_01v8[cgd])
print @m.x2.x5.msky130_fd_pr__nfet_01v8[vdsat]
print va2 va4 va5 va7 gmeff2 gmeff5
let cl= abs(@m.x2.x5.msky130_fd_pr__nfet_01v8[cgd])+abs(@m.x2.x5.msky130_fd_pr__nfet_01v8[cds])+abs(@m.x2.x5.msky130_fd_pr__nfet_01v8[cdb])+abs(@m.x2.x7.msky130_fd_pr__pfet_01v8[cgd])+abs(@m.x2.x7.msky130_fd_pr__pfet_01v8[cds])+abs(@m.x2.x7.msky130_fd_pr__pfet_01v8[cdb])
print c1
print cl
reset
tran 100p 10000n
plot v(50) v(52) 0.4003 0.9997 1.0003
reset
dc vi1 0.69 0.71 100u
plot v(43)
plot deriv(v(43))
plot deriv(v(43)) vs v(43)
plot db(deriv(v(43))) vs v(43)
let gain_db = db(deriv(v(43)))
*meas dc result find gain_db at vi1=0.7
meas dc peak_gain MAX gain_db
reset
set units = degrees
ac dec 100 1k 1g
let rv=-v(63)/v(62)
let ri=-i(vs1)/i(vs2)
plot db((rv*ri-1)/(2+rv+ri)) ph((rv*ri-1)/(2+rv+ri))
let magnitude=mag((rv*ri-1)/(2+rv+ri))
let phasedif=ph((rv*ri-1)/(2+rv+ri))+180
meas ac fu when magnitude=1
meas ac pm find phasedif at=fu
plot  vdb(82)
plot  vdb(93)
.endc
********************************************************
.end
