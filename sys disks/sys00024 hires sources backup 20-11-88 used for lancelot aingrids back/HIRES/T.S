	move.l	#colormap,-(sp)
	 move.w	#6,-(sp)
	 trap	#14
	 addq.l	#6,sp
iloop
 dc.w $4afa
 bra iloop

colormap
 dc.w 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
