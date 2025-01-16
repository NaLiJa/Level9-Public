 move.l #5000000,d0
 lea Tloop,a6
Tloop
 and.l (a6),d2
 subq.l #1,d0
 bne.s TLoop
 dc.w $4afa
