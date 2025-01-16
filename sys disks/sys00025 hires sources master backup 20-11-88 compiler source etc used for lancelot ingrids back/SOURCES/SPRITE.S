* quick sprite handler experiment
*
* M.J.Austin 23/11/86
*
hpixels equ 16
hbytes equ 4 * for 2 bits per pixel
vpixels equ 16
totalbytes equ hbytes*vpixels

 lea $78000,a5 * start of screen
 lea spriteshape,a0
 move.b (a0)+,d0

 move.b #$40,d7 * plotting mask
spriteh1
 move.b d7,d6
 eor.b #$ff,d6 * complement to z
* roll out a pixel and shift it into the appropriate bits of screen
 rol.b #1,d0
 or.b d7,(a5)
 bcs.s colour1done
 and.b d6,(a5)
colour1done
 addq.l #2,a5
* and second colour
 rol.b #1,d0
 or.b #1,d0
 or.b d7,(a5)
 bcs.s colour2done
 and.b d6,(a5)
colour2done

* at end of plotting mask?
 ror.b #1,d6
 ror.b #1,d7
 bcc.s spriteh1

spriteshape
 dc.b $cc,$cc
 dc.b $cc,$cc