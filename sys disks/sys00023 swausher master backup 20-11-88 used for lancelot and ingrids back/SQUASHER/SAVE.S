
SaveStatus
; lea SaveStatusDriverBlock,a6
; lea StartSquasher,a0
; move.l a0,(a6)
; move.l #$f8000,$4(a6)
; move.b #savedcode,d0
; bsr driver * save a LARGE area!
;createfile
 move.w #0,-(sp) * zero attributes for a normal file
; move.l a6,a0 * buffer address
; addq.l #8,a0
 lea SaveFileName(PC),a0
 move.l a0,-(sp)
 call_bdos f_create
 move.w d0,d4 * handle
 addq.l #8,sp
; rts
 tst.l d0
 bpl savestatus2
* file does not exist, so have to separately open it
; bsr openwrt
;openwrt
 move.w #1,-(sp) * open for write
; bra open1
;open1
; move.l a6,a0 * a6 is buffer address
; addq.l #8,a0 * a6 was still buffer address
 lea SaveFileName(PC),a0
 move.l a0,-(sp)
 call_bdos f_open
 move.w d0,d4 * handle
 addq.l #8,sp
; rts

 tst.l d0
 bmi writeerror
savestatus2
; bsr wrtfile
;wrtfile
 lea StartSquasher(PC),a0
 move.l a0,-(sp) * pea buffer(pc) * address of start of file
 move.l #$f8000,a1 * move.l $4(a6),a1 * end address
 sub.l a0,a1 * calc length
 move.l a1,-(sp) * length
 move.w d4,-(sp) * handle
 call_bdos f_write
 add.l #12,sp
; bsr closefile
;closefile
 move.w d4,-(sp) * handle(pc),-(sp)
 call_bdos f_close
 addq.l #4,sp
 rts
*------

RestoreStatus

*--------
;savefile
; bsr createfile
; tst.l d0
; bpl savefile2
;* file does not exist, so have to separately open it
; bsr openwrt
; tst.l d0
; bmi.s writeerror
;savefile2
; bsr wrtfile
; bsr closefile
; move.b #0,(a6) * signify save ok
; rts

readerror
 bsr prs
 dc.b "Can't find file on disk.",cr,0
 even
 move.b #1,(a6) * signify load error
 rts

writeerror
 bsr prs
 dc.b "Save error.",cr,0
 even
 move.b #1,(a6) * signify save error
 rts

openrd
 move.w #0,-(sp) * open for read
open1
 move.l a6,a0 * a6 is buffer address
 addq.l #8,a0 * a6 was still buffer address
 move.l a0,-(sp)
 call_bdos f_open
 move.w d0,d4 * handle
 addq.l #8,sp
 rts

createfile
 move.w #0,-(sp) * zero attributes for a normal file
 move.l a6,a0 * buffer address
 addq.l #8,a0
 move.l a0,-(sp)
 call_bdos f_create
 move.w d0,d4 * handle
 addq.l #8,sp
 rts

openwrt
 move.w #1,-(sp) * open for write
 bra open1

rdfile
 move.l (a6),-(sp) * address of where to put it
 move.l #$30000,-(sp) * max length to read
 move.w d4,-(sp) * handle(pc),-(sp)
 call_bdos f_read
 add.l #12,sp
 tst.l d0
 bmi readerror
* d0= number of bytes read
 add.l (a6),d0
 move.l d0,$4(a6) * save end address

 rts

wrtfile
 move.l (a6),-(sp) * pea buffer(pc) * address of start of file
 move.l $4(a6),a1 * end address
 sub.l (a6),a1 * calc length
 move.l a1,-(sp) * length
 move.w d4,-(sp) * handle
 call_bdos f_write
 add.l #12,sp
 rts

closefile
 move.w d4,-(sp) * handle(pc),-(sp)
 call_bdos f_close
 addq.l #4,sp
 rts

*---
