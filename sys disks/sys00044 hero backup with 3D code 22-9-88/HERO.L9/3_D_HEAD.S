


	opt	c+
	opt	d+
	opt	s-

*	nolist

main:
	clr.b	d0
	clr.b	d1
	clr.b	d2
	move.w	#100,d3

	jmp	make_pic0


	include	3_d_data.s
	include	3_d.s
	include	drw_obj.s
	include	objects.s


*	list

