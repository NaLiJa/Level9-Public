; all timings for Amiga: 0.14 uS per cycle approx.

; Summary of findings:
; Fastest replacement for a multiply muls const. (8.0 us)
; is:
; 	lea MulTable,a0 ;  9.2/9.13 seconds for 1E6 -> 5.9 uS
; 	add.w d1,d1
; 	add.w d1,d1
; 	move.l 0(a0,d1),d2
; Which takes 5.9 uS, and uses d1.w, signed..
; A mulu const instruction is almost as fast, and simpler.

;    Therefore dbra which executes once takes 2.27 uS
;    dbra which executes twice takes 4.04uS (1.77 uS longer)
; bne takes 1.58 us, subq takes 0.66 us. Total=2.24 us
; for short (1/2) loops, prefer whichever takes less setting up.
; dbra is significantly faster for loops executed >twice.

S
 move.l #1000000,d0
 move.w #42,d3
 lea MulTable,a0
 lea MulTable,a1
 lea MulTable,a2
 lea MulTable,a3
 lea MulTable,a4
TLoop
; 3.3 seconds for loop overhead - 1E6
;----
; lea MulTable,a0 ; 9.17 seconds for 1E6 -> 5.9 uS
; asl.w #1,d1
; move.l 0(a0,d1),d2
;-----
; muls MulVar,d2 ; 12.61 seconds for 1E6 -> 9.3 uS
;-----
; mulu MulVar,d2  ; 11.66 seconds for 1E6 -> 8.4 uS
;----
; mulu d3,d2 ; 9.85 seconds for 1E6 -> 6.5 uS
;----
; mulu #42,d2   ; 10.44 seconds for 1E6 -> 7.1 uS
;-----
; muls #42,d2   ; 11.25 seconds for 1E6 -> 8 uS
;-----
; lea MulTable,a0 ;  8.6 seconds for 1E6 -> 5.3 uS
; add.w d1,d1
; move.l 0(a0,d1),d2
;-----
; lea MulTable,a0 ; 9.3 seconds for 1E6 -> 6 uS
; asl.w #2,d1
; move.l 0(a0,d1),d2
;-----
; lea MulTable,a0 ;  9.2/9.13 seconds for 1E6 -> 5.9 uS
; add.w d1,d1
; add.w d1,d1
; move.l 0(a0,d1),d2
;-----
; lea MulTable,a0 ;  8.1 seconds for 1E6 -> 4.8 uS
; add.w d1,d1
; add.w d1,d1
; add.l d1,a0
; move.l a0,d2
;-----
; lea MulTable,a0 ;  8.7 seconds for 1E6 -> 5.4 uS
; add.w d1,d1
; add.w d1,d1
; ext.l d1
; add.l d1,a0
; move.l a0,d2
;-----
; lea MulTable,a0 ;  9.98 seconds for 1E6 -> 6.7 uS
; add.w d1,d1
; add.w d1,d1
; ext.l d1
; add.l d1,a0
; move.l (a0),d2
;-----
; lea MulTable,a0 ;  9.21 seconds for 1E6 -> 5.9 uS
; add.w d1,d1
; add.w d1,d1
; add.l d1,a0
; move.l (a0),d2
;-----
; move.w (a0),d2 ; 8.2 seconds for 1E6 -> 4.9 uS
; or.w (a0),d2
; or.w (a0),d2
; or.w (a0),d2
;-----
; move.l (a0),d3 ; 10.7 seconds for 1E6 -> 7.3 uS
; move.w d3,d2
; swap d3
; or.w d3,d2
; move.l (a0),d3
; or.w d3,d2
; swap d3
; or.w d3,d2
;-----
; move.w #2-1,d1 ; 8.57 seconds -> 5.27 uS
;Tloop1
; dbra d1,Tloop1
;------
; move.w #2-1,d1 ; 4.53 seconds -> 1.23 uS
;-----
; move.w #1-1,d1 ; 6.80 seconds -> 3.5 uS
;Tloop1
; dbra d1,Tloop1
;    Therefore dbra which executes once takes 2.27 uS
;    dbra which executes twice takes 4.04uS (1.77 uS longer)
;----
; subq.w #1,d2 ; 5.54 seconds -> 2.24 us
; bne.s MM21
; nop
;
;MM21
;-------
; subq.w #1,d2 ; 3.96 seconds -> 0.66 us (approx 4 cycles)
;------
; move.w d0,(a0) ; 5.74 seconds-3.3 O/H -> 2.44uS i.e. 1.22uS each
; move.w d0,(a0)
;------
; move.l d0,(a0) ; 5.15 seconds-3.3 -> 1.85uS
;-----
; move.w (a1),d3 ; 15.45 seconds-3.3 -> 12.15uS
; and.w d3,d7
; swap d3
; move.w (a2),d3
; and.w d3,d7
; or.w d2,d3 * ensure that rh part is not affected
; move.l d3,(a4)
; move.l d3,(a4)
; move.l d3,(a4)
; move.l d3,(a4)
;-------
; and.w d3,d7 ; 3.95 seconds -> 0.65 uS
;------
; swap d3 ; 3.92 seconds -> 0.65 uS
;-------
; move.w (a1),d3 ; 17.2 seconds -> 13.9uS
; move.w (a2),d4
; and.w d3,d7
; and.w d4,d7
; or.w d2,d4
; move.w d2,(a4)
; move.w d3,(a4)
; move.w d2,(a4)
; move.w d3,(a4)
; move.w d2,(a4)
; move.w d3,(a4)
; move.w d2,(a4)
; move.w d3,(a4)
;---------
;* do jump table index into our mask builder, to only do the right amount
; clr.l d3 ;;;;;;; 13.05 seconds ->9.75 uS excluding jmp(a0)
; move.w hi_cnt-S(a5),d3 * height
;* multiply by $14
; add.w d3,d3
; add.w d3,d3
; move.w d3,d6 * keep times 4
; add.w d3,d3
; add.w d3,d3 * got times $10
; add.w d6,d3
; lea BDC1End,a0
; sub.l d3,a0
;; jmp (a0)
;
;BDC1End
;----------
; move.w #8-1,d1   18.12 seconds -> 14.82 uS for average loop (max 16)
;TT1
; dbra d1,TT1
;--------
;============================
; Which is faster, a set of move.l d0,Memory
; or lea Memory,a0 and several move.l d0,(a0)+?

; move.l d0,MulTable 6.30 seconds -> 3.0 uS
;----
; lea MulTable,a0     5.05 seconds -> 1.75 uS
;----
; move.l d0,(a0)       5.00 seconds -> 1.70 uS
;------
; subq.l #1,a0	4.45 seconds -> 1.15 uS
;-------
; move.l d0,(a0)+    6.20 seconds -4.45 for sub ->1.75 uS move.l d0,(a0)+
; subq.l #4,a0     Therefore postincrement adds just 0.05 uS
;----------
; Thus to write to two adjacent longs,
; two direct writes takes 6.0 uS
; two using an address reg takes 1.75+2*1.7 = 5.15 uS and is
; therefore always faster for more than one adjacent write.
;------------
; bset #1,d1 * 4.94 seconds -3.3  => 1.64 us
;------
; bset #1,(a0) * 5.70 seconds -3.3 => 2.4 uS
;-------
; asl.w #1,d1  * 4.56 seconds -3.3 => 1.26 uS
;----
; roxl.w #1,d1 * 4.49 seconds      => 1.26 uS
;----
; sub.w #4,d5 * 4.56 seconds -> 1.26 uS
;------
; subq.w #4,d5 * 3.88 seconds -> 0.58 uS
;-----
; roxr.b #1,d1 ; 4.48 seconds
; roxr.w #1,d1 ; 4.44 seconds
; ror.w #1,d1 ; 4.50 seconds
; asr.w #1,d1 ; 4.47 seconds
;-----
; InterLeave Code ===========
; move.b (a1),d1 * get a nybble * 13.84 sec => 10.54 uS
; roxr.b #1,d1 * bit for bp3
; roxl.w #1,d7
; roxr.b #1,d1 * bit for bp2
; roxl.w #1,d6
; roxr.b #1,d1 * bit for bp1
; roxl.w #1,d5
; roxr.b #1,d1 * bit for bp0
; roxl.w #1,d4
;----
; move.b (a1),d1	* 10.25 seconds => 6.95 uS
; add.w d1,d1
; add.w d1,d1
; or.l (a0,d1.w),d2
; asl.l #1,d2
;----
; move.b (a1),d1	* 9.03 seconds => 5.73 uS
; or.l (a0,d1.w),d2
; asl.l #1,d2
;----
; move.b (a1),d1	* 13.62 seconds => 10.32 uS
; or.l (a0,d1.w),d2
; asl.l #1,d2
; or.l (a2,d1.w),d3
; asl.l #1,d3

;----
 subq.l #1,d0
 bne.s TLoop
 dc.w $4afa

MulVar dc.w 42
Hi_Cnt dc.w 16

 even
MulTable


