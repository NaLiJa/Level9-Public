 bra SetMedResolution
 include 'defns.s'
;-------
SetMedResolution
* Now set low resolution,
 move.w #-1,-(sp) ; retain resolution
 move.l #$78000,-(sp) ; retain physical base
 move.l #$78000,-(sp) ; retail logical base
* move.w #5,-(sp) ; set screen
 call_ebios _setscreen
 add.l #12,sp
 bra ReturnToGem
 rts
;-------
randomseed ds.l 1
