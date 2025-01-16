
SaveStatus
 lea SaveStatusDriverBlock,a6
 lea StartSquasher,a0
 move.l a0,(a6)
 move.l #$f8000,$4(a6)
 move.b #savedcode,d0
 bsr driver * save a LARGE area!

RestoreStatus

