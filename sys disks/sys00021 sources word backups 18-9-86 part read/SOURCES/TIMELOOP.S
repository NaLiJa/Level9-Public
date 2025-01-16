* timing loop program for comparison with C language version
 bra loopstart
 include driver.s
printchar
 bra driverprintchar

loopstart

 lea driverbuffer,a6
 bsr prs
 dc.b "Press return to start loop ...",cr,0
 even

 bsr waitkey
 move.l #1000000,d0
loop
 subq.l #1,d0
 bne.s loop

 bsr prs
 dc.b "That's all folks ... ",cr,0
 even

 bsr waitkey
 bra returntogem
