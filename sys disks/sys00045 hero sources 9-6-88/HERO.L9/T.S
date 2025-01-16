;-------
SetMedResolution
* Now set medium resolution,
* so OS will print 80 column text correctly
 move.w #1,-(sp) ; medium resolution
 move.l #$f8000,-(sp) ; retain physical base
 move.l #$f8000,-(sp) ; retail logical base
* move.w #5,-(sp) ; set screen
 call_ebios _setscreen
 add.l #12,sp
 rts
;-------
