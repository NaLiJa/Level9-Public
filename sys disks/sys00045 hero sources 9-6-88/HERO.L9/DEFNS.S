* 'DEFNS.S' - essentially a mini driver for ST
*
* Changes from standard driver...
* LOadfile/SaveFile now return 0/1 result code in 8(a6), not (a6)


*
* call the BIOS - requires 1 parameter:
* the function number
call_bios       macro
                move.w #\1,-(sp)
                trap #13
                endm

* call the extended BIOS - requires 1 parameter:
* the function number
call_ebios      macro
                move.w  #\1,-(sp)
                trap    #14
                endm


* call the BDOS - requires 1 parameter:
* the function number
call_bdos       macro
                move.w #\1,-(sp)
                trap #1
              endm


absgetcharfrombdos
* get character from keyboard in d0
* without waiting or echo (not easy in Gem !)
 call_bdos c_conis ; check if key pending
 addq.l #2,sp
 tst.l d0
 bmi.s osrdchgetkey
* no key waiting, so return 0
 move.b #0,d0
 rts
osrdchgetkey
 call_bdos c_rawcin ; get key from buffer without echo
 addq.l #2,sp
*
;* if d0.b=0, the lower byte of the upper word may
;* contain a keyboard code for the cursor keys etc.
; tst.b d0
; bne.s ogkret
; lsr.l #8,d0
; lsr.l #8,d0
; cmp.b #$48,d0
; bne.s ogk1
; move.b #cursorup,d0
; rts
;ogk1
; cmp.b #$4b,d0
; bne.s ogk2
; move.b #cursorleft,d0
; rts
;ogk2
; cmp.b #$4d,d0
; bne.s ogk3
; move.b #cursorright,d0
; rts
;ogk3
; cmp.b #$50,d0
; bne.s ogk4
; move.b #cursordown,d0
; rts
;ogk4
; cmp.b #$62,d0
; bne.s ogk5
; move.b #helpkey,d0
; rts
;ogk5
; cmp.b #$61,d0
; bne.s ogk6 ; undo key
; move.b #undokey,d0
; rts
;ogk6
; cmp.b #$10,d0
; bne.s ogk7 ; alt-Q
; move.b #quitkey,d0
; rts
;ogk7
; cmp.b #$13,d0
; bne.s ogk8 ; alt-R
; move.b #autorunkey,d0
; rts

;ogk8
; cmp.b #$26,d0
; bne.s ogk9 ; alt-L
; move.b #logkey,d0
; rts
;
;ogk9
;* $3b = f1
;* $3c = f2
;* $3d - f3 ... etc
; clr.b d0
ogkret
 rts

returntogem
 call_bdos p_term

;------
* equates for BDOS calls (ie Trap #1)

P_TERM_OLD      EQU 0           (should use $4C really)
C_CONIN EQU 1
C_CONOUT        EQU 2
C_AUXIN EQU 3
C_AUXOUT        EQU 4
C_PRNOUT        EQU 5
C_RAWIO EQU 6
C_RAWCIN        EQU 7
C_NECIN EQU 8
C_CONWS EQU 9
C_CONRS EQU $0A
C_CONIS EQU $0B
D_SETDRV        EQU $0E
C_CONOS EQU $10
C_PRNOS EQU $11
C_AUXIS EQU $12
C_AUXOS EQU $13
D_GETDRV        EQU $19
F_SETDTA        EQU $1A
_SUPER          EQU $20
T_GETDATE       EQU $2A
T_SETDATE       EQU $2B
T_GETTIME       EQU $2C
T_SETTIME       EQU $2D
F_GETDTA        EQU $2F
S_VERSION       EQU $30
P_TERMRES       EQU $31
D_FREE          EQU $36
D_CREATE        EQU $39
D_DELETE        EQU $3A
D_SETPATH       EQU $3B
F_CREATE        EQU $3C
F_OPEN          EQU $3D
F_CLOSE EQU $3E
F_READ          EQU $3F
F_WRITE EQU $40
F_DELETE        EQU $41
F_SEEK          EQU $42
F_ATTRIB        EQU $43
F_DUP           EQU $45
F_FORCE EQU $46
D_GETPATH       EQU $47
M_ALLOC EQU $48
M_FREE          EQU $49
M_SHRINK        EQU $4A
P_EXEC          EQU $4B
P_TERM          EQU $4C
F_SFIRST        EQU $4E
F_SNEXT EQU $4F
F_RENAME        EQU $56
F_DATIME        EQU $57

* Base Page Offsets
P_LOWTPA        EQU 0
P_HITPA EQU 4
P_TBASE EQU 8
P_TLEN          EQU $0C
P_DBASE EQU $10
P_DLEN          EQU $14
P_BBASE EQU $18
P_BLEN          EQU $1C
P_ENV           EQU $2C
P_CMDLIN        EQU $80

* Error codes
E_OK            EQU 0
ERROR           EQU -1
EDRVNR          EQU -2
EUNCMD          EQU -3
E_CRC           EQU -4
EBADRQ          EQU -5
E_SEEK          EQU -6
EMEDIA          EQU -7
ESECNF          EQU -8
EPAPER          EQU -9
EWRITF          EQU -10
EREADF          EQU -11
EGENRL          EQU -12
EWRPRO          EQU -13
E_CHNG          EQU -14
EUNDEV          EQU -15
EBADSF          EQU -16
EOTHER          EQU -17

EINVFN          EQU -32
EFILNF          EQU -33
EPTHNF          EQU -34
ENHNDL          EQU -35
EACCDN          EQU -36
EIHNDL          EQU -37
ENSMEM          EQU -39
EIMBA           EQU -40
EDRIVE          EQU -46
ENMFIL          EQU -49
ERANGE          EQU -64
EINTRN          EQU -65
EPLFMT          EQU -66
EGSBF           EQU -67

* BIOS calls (Trap #13) - Atari names are lower case
getmpb          equ 0
bconstat        equ 1
bconin          equ 2
bconout equ 3
rwabs           equ 4
setexc          equ 5
tickcal equ 6
getbpb          equ 7
bcostat equ 8
mediach equ 9
drvmap          equ 10
kbshift equ 11

* Extended BIOS calls (Trap #14)
initmous        equ 0
ssbrk           equ 1
_physbase       equ 2
_logbase        equ 3
_getRez equ 4
_setScreen      equ 5
_setPalette     equ 6
_setColor       equ 7
_floprd equ 8
_flopwr equ 9
_flopfmt        equ 10
midiws          equ 12
_mfprint        equ 13
iorec           equ 14
rsconf          equ 15
keytbl          equ 16
_random equ 17
_protobt        equ 18
_flopver        equ 19
scrdmp          equ 20
cursconf        equ 21
settime equ 22
gettime equ 23
bioskeys        equ 24
ikbdws          equ 25
jdisint equ 26
jenabint        equ 27
giaccess        equ 28
offgibit        equ 29
ongibit equ 30
xbtimer equ 31
dosound equ 32
setprt          equ 33
kbdvbase        equ 34
kbrate          equ 35
_prtblk equ 36
vsync           equ 37
supexec equ 38
puntaes equ 39


* System Variables
proc_lives      equ $380
proc_dregs      equ $384
proc_aregs      equ $3a4
proc_enum       equ $3c4
proc_usp        equ $3c8
proc_stk        equ $3cc
etv_timer       equ $400
etv_critic      equ $404
etv_term        equ $408
etv_xtra        equ $40c
memvalid        equ $420
memcntlr        equ $424
resvalid        equ $426
resvector       equ $42a
phystop equ $42e
_membot equ $432
_memtop equ $436
memval2 equ $43a
flock           equ $43e
seekrate        equ $440
_timr_ms        equ $442
_fverify        equ $444
_bootdev        equ $446
palmode equ $448
defshiftmd      equ $44a
sshiftmd        equ $44c
_v_bas_ad       equ $44e
vblsem          equ $452
nvbls           equ $454
_vblqueue       equ $456
colorptr        equ $45a
screenpt        equ $45e
_vbclock        equ $462
_frclock        equ $466
hdv_init        equ $46a
swv_vec equ $46e
hdv_bpb equ $472
hdv_rw          equ $476
hdv_boot        equ $47a
hdv_mediach     equ $47e
_cmdload        equ $482
conterm equ $484
themd           equ $48e
savptr          equ $4a2
_nflops equ $4a6
sav_context     equ $4ae
_bufl           equ $4b4
_hz_200 equ $4bc
the_env equ $4be
_drvbits        equ $4c4
_dskbufp        equ $4c6
_prt_cnt        equ $4ee
_sysbase        equ $4f2
_shell_p        equ $4f6
end_os          equ $4fa
exec_os equ $4fe



;getfilename
; cmp.b #0,$8(a6) * check if filename was supplied
; bne gfret
; bsr prs
; dc.b cr,"Filename ? ",0
; even
;
; addq.l #8,a6 * put filename at address expected file handling
; bsr inputline
; subq.l #8,a6 * restore a6
;gfret
; rts

;driverloadfile
; bsr.s getfilename
* fall through to loadfile
loadfile
 bsr openrd
 tst.l d0
 bmi.s readerror
 bsr rdfile
 bsr closefile
 move.b #0,$8(a6) * signify load ok
 rts

;driversavefile
; bsr.s getfilename
;* fall through to savefile
savefile
 bsr createfile
 tst.l d0
 bpl savefile2
* file does not exist, so have to separately open it
 bsr openwrt
 tst.l d0
 bmi.s writeerror
savefile2
 bsr wrtfile
 bsr closefile
 move.b #0,$8(a6) * signify save ok
 rts

readerror
; bsr prs
; dc.b "Can't find file on disk.",cr,0
; even
 move.b #1,$8(a6) * signify load error
 rts

writeerror
; bsr prs
; dc.b "Save error.",cr,0
; even
 move.b #1,$8(a6) * signify save error
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
;-------
GetRandom
        move.w  randomseed,d0
        move.w  d0,d1
        asl.w   #8,d1
        move.b  #10,d1
        sub.w   d0,d1
        asl.w   #2,d1
        add.w   d0,d1
        addq.w  #1,d1
        lea     randomseed,a0
        move.w  d1,(a0)
	move.w	d1,d0
        rts
;-------

*----


