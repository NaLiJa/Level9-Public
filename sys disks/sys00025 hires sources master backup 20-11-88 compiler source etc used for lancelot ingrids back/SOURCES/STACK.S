* program to display stack pointers
 bra displaystack
 include 'driver.s'

displaystack
 bsr prs
 dc.b "user sp=",0
 even
 move.l sp,a0
 bsr hexlonga0

 bsr prs
 dc.b cr,"system sp=",0
 even
 bsr setsupervisormode
 move.l sp,a0
 bsr hexlonga0

 bsr prs
 dc.b cr,"press a key to return to gem. ",0
 even
 bsr waitkey
 bra returntogem
*---
printchar
 bra driverprintchar
