**.subckt miller_ota_postLayout_test_trans
V2 pulseSource 0 pulse(0.4 1 10n 0.1n 0.1n 5000n 10000n 1)
R1 pulseSource otaIn 10k
C1 out 0 3p
V3 vdd 0 1.8
x1 0 0 0 otaIn out 0 0 0 0 0 0
+ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
+ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
+ vdd 0
+ $gds_out$

**** begin user architecture code

.include $gds_out$.spice
.tran 100p 10000n
.save all
.control
run
plot  v(out)
.endc

.end

.lib /usr/local/share/pdk/sky130A/libs.tech/combined/sky130.lib.spice tt
**** end user architecture code
**.ends
.end
