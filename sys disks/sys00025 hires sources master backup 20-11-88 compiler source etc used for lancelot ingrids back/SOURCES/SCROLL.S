; Test Scroll routine (byte-size jumps)

loop
; move.w #100,d7
;
;loop0
; move.l #$70000,a0
; move.l #$70000,a1
; move.w #400,d0
; bsr loop1
;
; move.w #-1,-(sp) ; keep resolution
; move.l #$f8000,-(sp) ; physical base
; move.l #$f8000,-(sp) ; logical base
; move.w #5,-(sp) ; set screen
; trap #14
; lea 12(sp),sp
;
;
; dbra d7,loop0
;
; dc.w $4afa



; first scroll it from screen 1 to 2
 move.l #$f8000,a0 ; address of screen on machine
 move.l #$77ffe,a1
 move.w #400-32,d0 ; lines to scroll
 bsr loop1
; and flip...
 move.w #-1,-(sp) ; keep resolution
 move.l #$78000,-(sp) ; physical base
 move.l #$78000,-(sp) ; logical base
 move.w #5,-(sp) ; set screen
 trap #14
 lea 12(sp),sp


; delay loop...
 move.l #$70000,a0 ; address of screen on machine
 move.l #$70000,a1
 move.w #400-32,d0 ; lines to scroll
 bsr loop1



; now scrol from screen 2 to 1
 move.l #$78000,a0 ; address of screen on a 1040
 move.l #$f7ffe,a1
 move.w #400,d0 ; lines to scroll
 bsr loop1
; and flip...
 move.w #-1,-(sp) ; keep resolution
 move.l #$f8000,-(sp) ; physical base
 move.l #$f8000,-(sp) ; logical base
 move.w #5,-(sp) ; set screen
 trap #14
 lea 12(sp),sp

; delay:
 move.l #$70000,a0 ; address of screen on machine
 move.l #$70000,a1
 move.w #400,d0 ; lines to scroll
 bsr loop1


 bra loop


loop1
; move 80 bytes... (a whole screen line)
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
;
;
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+

 move.b (a0)+,(a1)+
 move.b (a0)+,(a1)+
 addq.l #8,a0
 addq.l #8,a1
; move.b (a0)+,(a1)+
; move.b (a0)+,(a1)+
; move.b (a0)+,(a1)+

; move.b (a0)+,(a1)+
; move.b (a0)+,(a1)+
; move.b (a0)+,(a1)+
; move.b (a0)+,(a1)+
; move.b (a0)+,(a1)+

; and loop back for rest of screen
 dbra d0,loop1
 rts

