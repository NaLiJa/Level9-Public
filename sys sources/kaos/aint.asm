;Acode interpreted for IBM PC

;AINT.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

 name aint

 public aint
 public aintrestart

;In DRIVER.ASM:
 extrn driver:near

;In AINT.EXE:
 extrn ModuleName:byte

;These include files must be named in MAKE.TXT:
 include head.asm

;-----

code segment public 'code'
 assume ds:code,cs:code ;Make all jump/call instructions refer to code segment

;These include files must be named in MAKE.TXT:
 include header.asm

initialstack dw 0

romext dw 0
lsttbl dw 0 ;CmdTbl
       dw 0 ;List 1
list2  dw 0 ;List 2
list3  dw 0 ;List 3
       dw 0 ;List 4
       dw 0 ;List 5
       dw 0 ;List 6
       dw 0 ;List 7
       dw 0 ;List 8
list9  dw 0 ;List 9
prgstr dw 0

textmode db 0

obuff        db 33 dup(0) ;lower case input word
ibuff        db inputbuffersize dup(0) ;Ascii input buffer
wrapbuffer   db 33 dup(0) ;Can only SQUASH 32 chars per word
ibuffpointer dw 0 ;Pointer to start of word in IBUFF

prntblpointer     dw 0
wrapbufferpointer dw 0
list9pointer      dw 0 ;Pointer into LIST9

startmd dw 0 ;Address of start of Message Descriptors
endmd   dw 0 ;End address+1 of Message Descriptors
endwdp5 dw 0 ;Address+6 of end of Word Dictionary

var1         db 0
extst        db 0
rndsed       dw 0
currentflags db 0           ;Bit 5 and Bit 6 of current opcode

nchars db 0

mdtmode  db 0
startmsg dw 0               ;Also used for INPUT
wordtype db 0
keywordnumber dw 0
wordnumber    dw 0
abrevword     dw 0
wordaddress   dw 0
blockpointer  dw 0
headerpointer dw 0
unpack1 db 0
unpack2 db 0
unpack3 db 0
unpack4 db 0
unpack5 db 0
unpack6 db 0
unpack7 db 0
unpack8 db 0
threecharacters db 32 dup(0)
unpackpointer   db 0
lastchar        db 0
pendspace       db 0
screenwidth     db 0
lastheader      db 0
wordcase        db 0

; workspace and symbols for getnextobject
searchdepth db 0
hisearchpos db 0
searchpos   db 0
object      db 0
hlsave      dw 0
numobjectfound  db 0
inithisearchpos db 0
hipos db 0
hisearchposvar dw 0
searchposvar   dw 0
nonspecific equ 31
gnosp     dw 0
maxobject db 0

gnospbase db 60 dup(0) ; maxsp
gnomaxsp  equ this byte

gnoscratch db nonspecific dup(0)

numericbuffer db 3 dup(0)

driverbuffer db 7 dup(0)

hiresbuffer dw 0

;-----

;Constants likely to change:

lastcolumnwrap equ 0        ;Set to 1 if no CR needed

;-----

;Driver command codes:
initdcode      equ 0
checksumdcode  equ 1
oswrchdcode    equ 2
inputlinedcode equ 4
savedcode      equ 5
loaddcode      equ 6
settextdcode   equ 7
taskinitdcode  equ 8
stopdcode      equ 9
seeddcode      equ 12
clgdcode       equ 16
ramsavedcode   equ 22
ramloaddcode   equ 23

;-----

cret equ 13

vars equ startsavearea
numvar equ 256

listarea equ startsavearea+0200h

;-----

;Special short-codes:
longc equ 1Ah               ;Long escape code
header equ 1Ch              ;Header short-code
endseg equ 1Bh              ;Segment end marker

uppercasemark equ 10h

;----- 

aint:
 mov es,cs:MenuPgame        ;Save/Restore workspace.  

 mov ax,cs                  ;throughout interpreter cs=ds
 mov ds,ax
 assume ds:code

 mov ax,es ;Check initialised
 and ax,ax
 jnz startok

 mov dx,offset badstart
 mov ah,9 ;Display string
 int 21h ;Universal Function

 mov ah,4Ch ;Terminate process
 int 21h ;Universal Function
 jmp short aint

badstart:
 db "Bad parameter area"
 db '$'

startok:
 mov ds:initialstack,sp

;Now make data table at start of data into absolute addresses etc.

 mov si,offset ibuff
 mov al,initdcode
 call driver

 mov al,seeddcode
 call driver
 mov bx,ds:[si]
 mov ds:rndsed,bx

 mov al,1
 mov ds:textmode,al

 mov byte ptr 0[si],1
 mov al,11                  ;Chain
 call driver                ;(Chain resets stack)

;-----

;CHAIN always returns here:

aintrestart:
 mov es,cs:MenuPgame ;Gamedata & workspace segment
 mov sp,ds:initialstack
 mov si,offset IBUFF

 call checksum

;Get LIST pointers:

 mov bx,gamedata+18
 mov di,offset romext
 mov ch,0Ch
copy1:
;Read next ACODE instuction from GAMEDATA

 mov dx,es:[bx]
 add bx,2

 push bx
;Check if it was a workspace list reference
 mov bx,gamedata+0
 cmp ch,1                   ;Do not process PRGSTR
 je copy2
 mov al,dh
 cmp al,7Fh                 ;first 32K for permanent lists
                            ;then 32K for temporary tables.
 jb copy2
;>NICK 25/1/89 cmp al,8Fh
;>NICK 25/1/89 jnb copy2
 xchg dx,bx
 mov dx,8000h
 and al,al
 sbb bx,dx
;HL is now offset from start of LISTAREA
 mov dx,offset listarea
copy2:
 add bx,dx
 mov al,bl
 mov [di],al
 inc di
 mov al,bh
 mov [di],al
 inc di
 pop bx
 dec ch
 jz ain001
 jmp short copy1
ain001:

;Set up common values required from GAMEDATA file (in es:)
 mov bx,gamedata+0
 mov bx,es:[bx+2]           ;Offset to Message Descriptors
 mov cx,gamedata+0
 add bx,cx
 mov ds:startmd,bx
 mov di,gamedata+0
 mov cx,es:[di+4]           ;Length of Message Descriptors
 add bx,cx
 mov ds:endmd,bx
 mov bx,gamedata+0
 mov bx,es:[bx+8]           ;Length of 'Word Dictionary'
 mov dx,gamedata+5
 add bx,dx
 mov di,gamedata+0
 mov dx,es:[di+6]           ;Offset start Word Dictionary
 add bx,dx
 mov ds:endwdp5,bx

 mov bx,ds:prgstr           ;Cold start for program

 call wrapreset
 mov ds:ibuffpointer,0

 mov ax,cs
 mov ds,ax

start:
;*****
; push bx
; call prnthl
; mov al," "
; call printchar
; pop bx
;*****
 mov cx,offset start
 push cx
 mov al,es:[bx]             ;Get acode instruction from GAMEDATA

 mov ds:CurrentFlags,al     ;Save bit 6 (8-bit) and bit 5 (relative)

 and al,10011111b
 cmp al,35
 jb ain003
 cmp al,128
 jb ain002
 jmp list
ain002:
 jmp ilins
ain003:
 xchg dx,bx
 shl al,1
 mov bl,al
 sub bh,bh
 mov cx,word ptr jumpt[bx]
 xchg dx,bx
 inc bx
 push cx
 ret

;-----

jumpt:
 dw goto
 dw gosub
 dw return
 dw printn
 dw printv ;4
 dw printc
 dw function
 dw input
 dw varcon ;var=cons
 dw varvar
 dw add0
 dw sub0
 dw notimp ;12
 dw notimp
 dw jump
 dw exit
 dw ifeqvt ;16
 dw ifnevt
 dw ifltvt
 dw ifgtvt
 dw screen ;20
 dw cleartg
 dw picture
 dw getnextobject
 dw ifeqct ;24
 dw ifnect
 dw ifltct
 dw ifgtct
 dw printinput ;28
 dw notimp ;ifnecg
 dw notimp ;ifltcg
 dw notimp ;ifgtcg

;-----

;Set A to driver funtion. Returns A as driver return code
;(if produced) and 'Z' if return code = 0.

driverresult:
 call driver
 mov al,0[si]
 or al,al
 ret

;-----

checksum:
 mov bx,gamedata+0
 call setiy0hl              ;Start address for checksum
 mov di,gamedata+0
 mov cx,es:[di+0]           ;Offset to checksum in GAMEDATA
 add bx,cx
 call setiy2hl              ;End address for checksum
 mov al,checksumdcode
 call driverresult
 jnz ain004
 ret
ain004: ;Checksum ok

 mov al,'E'

error:
 push ax
 call oswrcr
 pop ax
 call oswrch
 mov al,'?'
 call oswrch
 mov al,inputlinedcode
 jmp driver

;-----

notimp:
 push bx
 call prnthl
 mov al," "
 call printchar
 pop bx

 mov al,'A'
 call error
 jmp aintrestart

;-----

gethlval: ;Given (HL) as var num, returns BC value, DE address
 mov al,es:[bx] ;Read variable number (0-255) from GAMEDATA
getval: ;Given A=Var num, returns BC=Current value and
;DE=address of variable
 xchg dx,bx

;This is not compatable with save/restore positions
;produced by previous interpreters...
 sub bh,bh
 mov bl,al
 add bx,bx
 add bx,offset vars
 mov cx,es:[bx]

 xchg dx,bx
 ret
;-----
goto:
 call getadr
 xchg dx,bx
 ret
;-----
gosub:
 pop cx
 call getadr
 push bx
 push cx
 xchg dx,bx
 ret
;-----
getadr:
 test ds:CurrentFlags,20h
 jnz getad1

 mov dx,es:[bx]
 add bx,2

push bx
 mov bx,ds:prgstr
 add bx,dx
 xchg dx,bx
 pop bx
 ret

getad1:                     ;8 bit address
 mov dl,es:[bx]
 sub dh,dh
 test dl,080h
 jz getad2
 mov dh,0FFh                ;Backwards relative jump
getad2:
 push bx
 add bx,dx
 xchg dx,bx
 pop bx
 inc bx
 ret
;-----
return:
 pop cx
 pop bx
 push cx
 ret
;-----

screen:                     ;Set text/Graphics mode
 mov al,es:[bx]             ;Get acode argument from GAMEDATA
 mov ds:textmode,al
 inc bx
 or al,al
 jz screent                 ;Set text screen

 inc bx
 jmp short clearg

screent:

 call stopgint

 mov al,settextdcode
 jmp short jpdriver

;-----

cleartg:                    ;Clear text or graphics screen
 mov al,es:[bx]             ;Get acode argument from GAMEDATA
 inc bx
 or al,al
 jz cleart

 mov al,ds:textmode
 or al,al
 jnz clearg
 ret                        ;Clear G not in pictures mode.

;CLEAR G or SCREEN G:

clearg:
 call stopgint
 mov al,clgdcode
jpdriver:
 jmp driver

;CLEAR T: 

cleart:
 mov al,12
 jmp oswrch

;-----

picture:
 call gethlval
;BC = Picture number
 inc bx
 mov al,ds:textmode
 or al,al
 jnz ain010
 ret
ain010:

startgint:
 push si
 mov si,offset hiresbuffer
 mov 0[si],cx
 mov al,32                  ;Draw hires picture dcode
 call driver
 pop si

 mov al,taskinitdcode
 jmp short jpdriver

stopgint:
 sub cx,cx
 jmp short startgint

;-----

function:
 mov al,es:[bx]             ;Get acode argument from GAMEDATA
 inc bx
 cmp al,1
 je stop
 cmp al,2
 jne ain013
 jmp random
ain013:
 cmp al,3
 jne ain014
 jmp save
ain014:
 cmp al,4
 jne ain015
 jmp restore
ain015:
 cmp al,5
 jne ain016
 jmp clear
ain016:
 cmp al,6
 jne ain017
 jmp stackfunction
ain017:
 cmp al,250
 jne ain017a
 jmp short prs
ain017a:
ilins:

 push bx
 call prnthl
 mov al," "
 call printchar
 pop bx

 mov al,'I'
 call error
 jmp aintrestart

;-----

;Really only required for debugging, but required for
;'CHEAT' modes in some games.

prs:
 mov al,es:[bx]            ;Get ascii code, stored in GAMEDATA file
 inc bx
 and al,al
 jz p2
 call printchar
 jmp short prs
p2:
 ret

;-----

;STOP instruction now calls most DRIVER functions.
; calls to STOP, RAMSAVE and RAMLOAD are treated differently.

stop:
 push si ;Aint's driver parameter call block
 push bx ;Next acode instruction (in GAMEDATA paragraph)

;List 9 contains arguments for driver call:
;   byte 0 - Driver call number
;   byte 1 - 1st argument
;   byte 2 - 2nd argument
;   byte 3 - 3rd argument
;   byte 4 - 4th argument
;   byte 5 - 5th argument
;   byte 6 - 6th argument
;list 9 is in the GAMEDATA/VARS paragraph (which driver cannot access)
;so this is copied to 'driverbuffer':

;Copy six bytes from LIST9, stored with variables below GAMEDATA
 mov si,ds:list9
 mov al,es:1[si]
 mov byte ptr ds:0[driverbuffer],al
 mov al,es:2[si]
 mov byte ptr ds:1[driverbuffer],al
 mov al,es:3[si]
 mov byte ptr ds:2[driverbuffer],al
 mov al,es:4[si]
 mov byte ptr ds:3[driverbuffer],al
 mov al,es:5[si]
 mov byte ptr ds:4[driverbuffer],al
 mov al,es:6[si]
 mov byte ptr ds:5[driverbuffer],al

 mov al,es:[si]             ;Get driver call number from LIST 9
 cmp al,32                  ;Displayhires driver code
 jne stop1
 mov ah,ds:textmode
 and ah,ah
 jnz stop1
 mov al,01                  ;Return code
 jmp short stop2

stop1:
 mov si,offset driverbuffer
 call driverrequest         ;Execute driver call

 mov ax,word ptr ds:0[driverbuffer] ;Return code
stop2:
;Store return code in LIST 9 below GAMEDATA
 mov si,ds:list9
 mov es:0[si],al            ;(Inherited bug fix)
 mov es:1[si],ax            ;Save return code (For driver call
                            ;34 returns 2-byte picture number)
 pop bx
 pop si
 ret

;-----

;Execute driver call 'AL' with up to three arguments
;in 'driverbuffer':

driverrequest:
 cmp al,stopdcode
 je quit

 cmp al,ramsavedcode
 jne ain018
 jmp short ramio
ain018:
 cmp al,ramloaddcode
 jne ain019
 jmp short ramio
ain019:
 jmp driver

;-----

quit:
 call checksum
 mov bx,0FFFFh
quit1:
 dec bx
 mov al,bh
 or al,bl
 jnz quit1
 mov al,stopdcode
 call driver
;Do hardware-reset:
 db 0EAh ;Dissassembles as "Jmp short 0FFFFh:0000"
 dw 00000h
 dw 0FFFFh

;-----

ramio:
 push ax

 mov cx,0[si]               ;Low word of position
 sub bx,bx                  ;Construct virtual ram address
 mov dx,offset workspacesize ;Length

commonoops1:
 mov al,ch
 or al,cl
 jz commonoops3
 dec cx
 add bx,dx
 jnb commonoops1

;Acode requested RAM position in excess of 64K

commonoops2:
 pop ax
 mov al,2 ;Return code
 jmp short commonoops4

commonoops3:
 mov 4[si],bl
 mov 5[si],bh
 mov byte ptr 6[si],0

 call setsaveaddresses
 pop ax
 call driverresult
;Result in A

commonoops4:
 mov bx,offset driverbuffer
 mov [bx],al

 ret

;-----

printn: ;code 3
 call gethlval
 inc bx
 push bx
 mov bx,cx
 call prnthl
 pop bx
 ret
;-----
prnthl:                     ;Print number HL in decimal
 mov al,bh
 or al,bl
 jz prnth3
 sub cl,cl                  ;Reset flag
 mov dx,offset prntbl
 mov ds:prntblpointer,dx
;Find current digit value
prnth1:
 push bx
 mov bx,ds:prntblpointer
 mov dl,[bx]
 inc bx
 mov dh,[bx]
 inc bx
 mov ds:prntblpointer,bx
 pop bx
;Check 5 digits found
 mov al,dh
 or al,dl
 jnz ain020
 ret
ain020:
;Find current digit
 mov ch,'0'
prnth2:
 sub bx,dx
 jb prnth4
 inc ch
 mov al,1
 mov cl,al
 jmp short prnth2

prnth4:
 add bx,dx
 mov al,cl
 or al,cl
 jz prnth1
 mov al,ch
 call printchar
 jmp short prnth1

prnth3:
 mov al,'0'
 jmp printchar
;-----
prntbl:
 dw 10000
 dw 1000
 dw 100
 dw 10
 dw 1
 dw 0 ;end
;-----
printc: ;code 5
 call getcon
 dec bx
 jmp short prin1
;-----
printv: ;code 4
 call gethlval
prin1:
 push bx
 mov bx,cx
 call displaymessage
 pop bx
 inc bx
 ret
;-----
varcon: ;var=cons (8)
 call getcon
 dec bx
 jmp short varv1
;-----
varvar: ;Var=Var (9)
 call gethlval
varv1:
 push cx
 inc bx
 call gethlval
 pop cx
 xchg dx,bx
 mov es:[bx],cl             ;Save to variable, below GAMEDATA
 inc bx
 mov es:[bx],ch
 xchg dx,bx
 inc bx
 ret
;-----
add0: ;var,var (10.)
 call gethlval
 push cx
 inc bx
 call gethlval
 mov bp,sp ;ex (sp),hl
 xchg bx,[bp]
 add bx,cx
add1:
 xchg dx,bx
 mov es:[bx],dl             ;Write to variable, below GAMEDATA
 inc bx
 mov es:[bx],dh
 pop bx
 inc bx
 ret
;-----
sub0: ;var,var (11.)
 call gethlval
 push cx
 inc bx
 call gethlval
 mov bp,sp
 xchg bx,[bp]
 and al,al
 push cx
 mov bp,sp
 xchg bx,[bp]
 pop cx
 sbb bx,cx
 jmp short add1
;-----
jump: ;Addr,Var
 mov dl,es:[bx]             ;Get acode argument from GAMEDATA
 inc bx
 mov dh,es:[bx]
 inc bx
 push dx
 call gethlval
 mov bx,cx ;bx=bx*2
 add bx,bx
 mov ch,bh
 mov cl,bl
 pop bx
 add bx,cx
 mov cx,ds:prgstr
 add bx,cx
 mov dx,es:[bx]
 mov bx,ds:prgstr
 add bx,dx
 ret
;-----
chkequ: ;Var1=Var2
;If Var1>Var2 ,carry
;If Var1<=Var2 ,nc
 call gethlval
 push cx
 inc bx
 call gethlval
 push cx
 pop dx ;var2
 inc bx
 jmp short chk1
;-----
ifeqvt: ;If V=V then
 call chkequ
 jz ain021
 ret
ain021:
 jmp short ifthen
;-----
ifnevt: ;If V<>V then
 call chkequ
 jnz ain022
 ret
ain022:
 jmp short ifthen
;-----
ifltvt: ;If V<V then
 call chkequ
 jnz ain023
 ret
ain023:
 jnb ain024
 ret
ain024:
 jmp short ifthen
;-----
ifgtvt: ;If V>V then
 call chkequ
 jb ain025
 ret
ain025:
 jmp short ifthen
;-----
chkeqv: ;var1=cons ?
 call gethlval
 push cx
 inc bx
 call getcon
 push cx
 pop dx
chk1:
 pop cx
 xchg dx,bx
 push bx
 and al,al
 sbb bx,cx ;cons-var1
 pop di
 xchg dx,bx
 lahf ;Save flags
 xchg al,ah
 push ax
 xchg al,ah
 call getadr
 pop ax
 xchg al,ah
 sahf ;Restore flags
 ret
;-----
ifeqct: ;if v=c then
 call chkeqv
 jz ain026
 ret
ain026:
 jmp short ifthen
;-----
ifnect: ;if v<>c then
 call chkeqv
 jnz ain027
 ret
ain027:
 jmp short ifthen
;-----
ifltct: ;if v<c then
 call chkeqv
 jnz ain028
 ret
ain028:
 jnb ain029
 ret
ain029:
 jmp short ifthen
;-----
ifgtct: ;if v>c then
 call chkeqv
 jb ain030
 ret
ain030:
 jmp short ifthen
;-----
ifthen:                     ;Handle GOTO for IF
 xchg dx,bx
 ret
;-----
printinput:
; Acode instruction with no arguments
; Print last input word processed - i.e. contents of OBUFF
 mov dx,offset obuff
printinput1:
 xchg si,dx
 mov al,[si]
 xchg si,dx
 cmp al,' '
 jne ain031
 ret
ain031:
 call printchar
 inc dx
 jmp short printinput1
;-----
input:
 push bx

;If last INPUT returned "end-of-line" then get
;more keyboard input

 mov bx,ds:ibuffpointer
 mov al,bh
 or al,bl
 jnz ip04

;Get keyboard input

 call flush
 call wrapreset
 mov bx,offset ibuff
 mov ds:ibuffpointer,bx
 mov al,inputlinedcode
 call driver

;(IBUFFPOINTER) is address of end of previous word.
;Copy next input word to OBUFF converting to lower case
;and removing transparent characters.

ip04:
 mov bx,ds:ibuffpointer
 mov di,offset obuff
ip05:
 mov al,[bx]                ;Find start of next word
 or al,al
 jnz ain032
 jmp ip20
ain032:                     ;End of input
 call partword
 jz ip06
 mov al,[bx]
 inc bx
 cmp al,' '
 je ip05
 mov ds:ibuffpointer,bx
 mov bx,ds:list9
 mov byte ptr es:[bx],0     ;LIST 9 below GAMEDATA
 inc bx
 mov es:[bx],al
 inc bx
 mov byte ptr [di],al       ;obuff
 mov byte ptr 1[di],' '     ;obuff+1
 mov cx,0FFFFh              ;Force PRINTINPUT to print OBUFF
 mov ds:keywordnumber,cx
 jmp ip19a

ip06:
 mov al,[bx]
 cmp al,'-'                 ;Transparent character
 je ip07
 call partword
 jnz ain033
 jmp short ip07
ain033:
ip06a:
 mov byte ptr [di],' '      ;Word terminator
 jmp short ip09
ip07:
 mov al,[bx]                ;Copy one character of word
 call lower
 mov [di],al
 inc di
 push bx
 push di
 pop bx
 mov cx,offset OBUFF+31
 sub bx,cx
 pop bx
 jnb ip06a                  ;Buffer full, simulate end-of-word
ip08:
 inc bx
 jmp short ip06
ip09:
 mov ds:ibuffpointer,bx

;Convert word in OBUFF to word-number

 mov bx,0FFFFh
 mov ds:abrevword,bx
 mov ds:keywordnumber,bx
 mov bx,ds:list9
 mov ds:list9pointer,bx
 call setindex
 mov al,byte ptr ds:obuff
 sub al,'a'
 jnb ip10

 mov bx,gamedata+0
 mov bx,es:[bx+6]           ;Start of Word Dictionary, from GAMEDATA
 mov ds:[wordaddress],bx
 sub cx,cx                  ;Non alpha keywords in first segment
 jmp short ip13a

ip10:
 cmp al,26
 jb ip11
 mov al,103
 jmp short ip13
ip11:
 add al,al
 add al,al
 mov ch,al
 mov al,byte ptr ds:obuff+1
 cmp al,' '
 jne ip12
 mov al,ch
 jmp short ip13
ip12:
 sub al,'a'
 shr al,1
 shr al,1
 shr al,1
 and al,03h                 ;4 minor segments per major segment
 add al,ch
ip13:
 sub ch,ch
 mov cl,al
 mov di,gamedata+0
 mov ax,es:[di+12]
 sub al,cl
 jnb ain034
 jmp ip22
ain034:                     ;No such segment
 add bx,cx
 add bx,cx
 add bx,cx
 add bx,cx
 mov cl,es:[bx]             ;Save address
 inc bx
 mov ch,es:[bx]
 mov ds:[wordaddress],cx
 inc bx
 mov cl,es:[bx]             ;Save word number
 inc bx
 mov ch,es:[bx]
ip13a:
 mov ds:wordnumber,cx
 mov bx,ds:[wordaddress]
 call initunpack
ip14:
 call unpackword
 jnb ain035
 jmp ip21b
ain035:                     ;End of dictionary
 mov bx,offset obuff
 mov dx,offset threecharacters
 sub cx,cx                  ;Number of characters that match
ip15:
 push cx
 mov al,[bx]
 mov ch,al
 xchg si,dx
 mov al,[si]
 xchg si,dx
 and al,01111111b
 call lower
 cmp al,ch
 pop cx
 jnz ip16
 inc dx
 inc cx
 inc bx
 jmp short ip15
ip16:
 mov al,[bx]                ;End of input word ?
 cmp al,' '
 je ain036
 jmp short ip17
ain036: ;No
 xchg si,dx
 mov al,[si]
 xchg si,dx
 or al,al
 jnz ain037
 jmp short ip18
ain037:
 mov bx,ds:abrevword
 mov al,bh
 and al,bl
 cmp al,0FFh
 je ip22m
 jmp short ip22
ip22m:
 mov al,cl
abrev equ 4                 ;Chars allowed as abreviation
 cmp al,abrev
 jb ain038
 jmp short ip18
ain038:
;Could be an abreviation
 mov bx,ds:wordnumber
 mov ds:abrevword,bx
 jmp short ip17b
ip17:
 mov bx,ds:abrevword
 mov al,bh
 and al,bl
 cmp al,0FFh
 jne ip18b
ip17b:
 mov cx,ds:wordnumber
 inc cx
 mov ds:wordnumber,cx
 jmp short ip14

;Fill LIST9 with a sequence of possible word-type/
;message-number possibilities terminated by 00h 00h.

ip18:
 mov bx,ds:wordnumber
ip18b:
 mov ds:keywordnumber,bx
 call findmsgequiv
 mov bx,0FFFFh
 mov ds:abrevword,bx
 mov bx,ds:list9pointer
 mov dx,ds:list9
 mov al,bh
 cmp al,dh
 jne ip19
 mov al,bl
 cmp al,dl
 je ip17b                   ;No words found. Garbage word.
ip19:
 mov bx,ds:list9pointer
ip19a:
 mov word ptr es:[bx],0     ;Write terminator to LIST 9, below GAMEDATA
 jmp short ip21
ip20:
 mov bx,ds:list9
 mov word ptr es:[bx],0     ;Write terminator to LIST 9, below GAMEDATA
 mov ds:ibuffpointer,0
ip21:
 pop bx

;Skip over arguments to INPUT

 inc bx
 inc bx
 inc bx
 inc bx
 ret

ip21b:
 mov bx,ds:abrevword
 mov al,bh
 and al,bl
 cmp al,0FFh
 jne ip18b

;Not a keyword, try it for a number

ip22:
 mov al,byte ptr ds:obuff   ;Start with digit ?
 cmp al,'0'
 jb ip22z
 cmp al,'9'+1
 jnb ip22z
 mov bx,offset numericbuffer
 mov byte ptr [bx],0        ;numericbuffer
 mov word ptr 1[bx],0       ;numericbuffer+1,2
 mov bx,offset obuff
ip22a:
 mov al,[bx]
 cmp al,' '
 je ip22b
 sub al,'0'
 jb ip22z                   ;Contains a non-digit
 cmp al,10
 jnb ip22z                  ;Character > '9'
 mov cl,al                  ;Current 'carry' value
 push bx
 mov bx,offset numericbuffer
 call mult10
 inc bx
 call mult10
 inc bx
 call mult10
 pop bx
 mov al,cl
 or al,al
 jnz ip22z                  ;Too big,Return as a garbage word
 inc bx
 jmp short ip22a

ip22b:                      ;Found a numeric value 0-FFFFFFh in NUMERICBUFFER
 mov bx,ds:list9
 mov byte ptr es:[bx],1     ;Set List 9 return flag as 'numeric'
 inc bx
 mov al,byte ptr ds:0[numericbuffer]
 mov es:0[bx],al
 inc bx
 mov al,byte ptr ds:1[numericbuffer]
 mov es:0[bx],al
 inc bx
 mov al,byte ptr ds:2[numericbuffer]
 mov es:0[bx],al
 inc bx
 jmp ip19a

;Garbage word, Return 00h 80h

ip22z:
 mov bx,ds:list9
 mov word ptr es:[bx],8000h ;Garbage word
 inc bx
 inc bx
 mov ds:list9pointer,bx
 jmp ip19

;-----

;Do one stage of V = (HL)*10 + C
; Return: (HL) = V MOD 256
;         C = V DIV 256
mult10:
 mov al,[bx]
 push bx
 mov bl,al
 sub bh,bh
 add bx,bx
 mov dl,bl
 mov dh,bh
 add bx,bx
 add bx,bx
 add bx,dx
 sub dh,dh
 mov dl,cl
 add bx,dx
 xchg dx,bx
 pop bx
 mov [bx],dl ;Return V MOD 256
 mov cl,dh ;Return carry
 ret

;-----
exit: ;From, Dir, Status, Newroom
 call gethlval
 mov al,cl
 mov ds:[var1],al
 inc bx
 call gethlval
 mov dh,cl
 inc bx
 push bx
 mov al,ds:[var1]

 mov dl,al
 call exit1
 mov ds:extst,al
 mov al,cl ;'to' room
 pop bx
 push ax
 call gethlval
 mov al,ds:extst
 and al,70h                 ;Reset bottom 4 bits + Top bit
 sar al,1
 sar al,1
 sar al,1
 sar al,1
 xchg si,dx
 mov es:[si],al
 inc si
 mov byte ptr es:[si],0
 xchg si,dx
 inc bx
 call gethlval
 pop ax
 xchg si,dx
 mov es:[si],al
 inc si
 mov byte ptr es:[si],0
 xchg si,dx ;0
 inc bx
 ret
;-----
exit1:                      ;Given D=Dir, E=From room
;Return status byte in A, 'to' room in C
 mov bx,ds:[romext]
;Find E'th entry on list
 mov ch,dl
 dec ch
 mov al,ch
 jz exit3
exit2:
 mov al,es:[bx]
 and al,al ;Short exit-table for KAOS 9/87
 jz notfn4
 test al,080h
 lahf                       ;required
 inc bx
 inc bx
 sahf                       ;required
 jz exit2 ;Not end of room list yet
 dec ch
 jz ain039
 jmp short exit2
ain039:
;Got room E
;Now find an entry direction D
exit3:
 mov al,es:[bx]
 and al,0Fh ;Separate out direction
 cmp al,dh
 jne exit4
 mov al,es:[bx]
 inc bx
 mov cl,es:[bx]
 ret

exit4:
 mov al,es:[bx]
 test al,080h
 jnz notfn4
 inc bx
 inc bx
 jmp short exit3

notfn4: ;First pass failed, so try reversible
;First invert direction
 mov cl,dh
 sub ch,ch
 mov bx,offset dorrev
 add bx,cx
 mov dh,[bx]                ;(In DORREV) New direction
;Find A to room=E, Dirction=D, reversible
 mov bx,ds:[romext]
 mov cl,1                   ;Current room number
exit5:
 mov al,es:[bx]
 test al,00010000b ;Reversible ?
 jz exit6
;It's reversible, but is it the right direction ?
 and al,0Fh ;Filter direction
 cmp al,dh
 jne exit6
;and does it go to the right place ?
 inc bx
 mov al,es:[bx]
 cmp al,dl
 lahf                       ;required
 dec bx
 sahf                       ;required
 jnz exit6
;C=Destination
 mov al,es:[bx]
 ret
;-----
exit6:                      ;Try another exit
 mov al,es:[bx]
 test al,080h
 jz exit7
 inc cl                     ;Current room number on list
exit7:
 mov al,es:[bx]
 inc bx
 inc bx
 or al,al
 jnz exit5
;Not found at all !
 sub cl,cl                  ;Destination (or lack of)
 ret
;-----
dorrev:
 db 0
 db 4
 db 6
 db 7
 db 1
 db 8
 db 2
 db 3
 db 5
 db 0Ah
 db 9
 db 0Ch
 db 0Bh
 db 0Dh ;Exit reversal table for KAOS 9/87
 db 0Eh
 db 0Fh ;Jump
;-----
list:
 mov al,es:[bx]
 inc bx
 cmp al,224
 jnb lstvv
 cmp al,192
 jnb lstvlc
 cmp al,160
 jnb lstvlv
;List N (Cons)=Var
 xchg dx,bx
 sub al,128
 call getind
 push cx
 pop bx
 xchg si,dx
 mov al,es:[si]
 xchg si,dx
 mov cl,al
 sub ch,ch
 jmp short lstvv1
;-----
getind:
 add al,al ;sla a
 mov cl,al
 sub ch,ch
 mov bx,offset lsttbl
 add bx,cx
 mov cl,[bx]
 inc bx
 mov ch,[bx]
 ret
;-----
lstvv:
;List N (var)=var
 xchg dx,bx
 sub al,224
 call getind
 push cx
 pop bx
 xchg si,dx
 mov al,es:[si]
 xchg si,dx
 push dx
 push bx
 call getval
 pop bx
 pop dx
lstvv1:
 add bx,cx
 inc dx
 push bx
 xchg dx,bx
 call gethlval
 xchg dx,bx
 pop bx
 mov es:[bx],cl
 xchg dx,bx
 inc bx
 ret
;-----
lstvlc: ;Var=List N(Cons)
 push bx
 pop di
 mov bx,offset lsttbl
 sub al,192
 call lstv2
 mov cl,al
 sub ch,ch
 jmp short lstvl1
;-----
lstvlv: ;var=listn(var)
 push bx
 pop di
 mov bx,offset lsttbl
 sub al,160
 call lstv2
 call getval
lstvl1:
 test cx,8000h ;>For Knight Orc
 jz listok ;>
 add bx,cx
 inc di
 mov al,es:[di] ;Destination variable
 call getval
 sub al,al ;>
 jmp short listwrite ;>
listok: ;>
 add bx,cx
 inc di
 mov al,es:[di] ;Destination variable
 call getval
 mov al,es:[bx] ;Read value from list
listwrite: ;>
 xchg si,dx
 mov es:[si],al
 inc si
 mov byte ptr es:[si],0
 xchg si,dx
 push di
 pop bx
 inc bx
 ret
;-----
lstv2:
 add al,al ;sla a
 mov cl,al
 sub ch,ch
 add bx,cx
 mov dl,[bx]
 inc bx
 mov dh,[bx]
 xchg dx,bx ;Start of list in HL
 mov al,es:[di] ;Next acode byte
 ret
;-----
random: ;Random V1
 call gethlval
 inc bx
 call randno ;Random number in A
 xchg si,dx
 mov es:[si],al
 inc si
 mov byte ptr es:[si],0
 xchg si,dx
 ret
;-----
randno: ;Returns 0-255 in A
 push bx
 mov bx,ds:rndsed
 push dx
 xchg dx,bx
 mov bh,dl
 mov bl,10
 or al,al
 sbb bx,dx
 add bx,bx
 add bx,bx
 add bx,dx
 inc bx
 mov ds:rndsed,bx
 mov al,bl
 pop dx
 pop bx
 ret
;-----
getcon:
 test ds:CurrentFlags,40h
 jnz getcn1
 mov cx,es:[bx]
 add bx,2
 ret
;-----
getcn1:
 mov cl,es:[bx]
 inc bx
 sub ch,ch
 ret
;-----
clear: ;Reset workspace
 push bx
 mov ax,numvar
 add ax,ax ;sla a
 mov cx,ax
 mov bx,offset vars
clear1:
 mov byte ptr es:[bx],0
 inc bx
 dec cx
 jcxz ain040
 jmp short clear1
ain040:
 pop bx
 ret
;-----
stackfunction: ;Reset stack
 pop dx

 mov sp,ds:initialstack

 push dx
 ret
;-----

restore:
 mov al,loaddcode
 call tapedriver
 jz ain041
 call clear
 jmp aintrestart
ain041:
 push si
 push cx
 mov si,offset ibuff
 mov cx,inputbuffersize+3
forceclear:
 mov byte ptr [si],0 ;Force INPUT buffer to all zeros
 inc si
 dec cx
 and cx,cx
 jnz forceclear
 mov si,offset obuff
 mov cx,32
forceclear2:
 mov byte ptr [si],'?' ;force PRINTINPUT buffer to all '?'
 inc si
 dec cx
 and cx,cx
 jnz forceclear2
 mov byte ptr [si],' ' ;Terminator for OBUFF
 pop cx
 pop si
 ret

save:
 mov al,savedcode

tapedriver:
 push bx
 call setsaveaddresses
 call driverresult
 pop bx
 ret

setsaveaddresses:
 mov bx,offset startsavearea
 call setiy0hl
 mov bx,offset startsavearea+workspacesize
 jmp short setiy2hl

setiy0hl:
 mov 0[si],bx
 ret

setiy2hl:
 mov 2[si],bx
 ret

;-----

;If message number 'HL' exists it is displayed.

displaymessage:
 xchg dx,bx
 mov bx,ds:startmd ;Start address of Message Descriptors

;Start of message ?

lm01:
 call checkmdt
 jb ain042
 ret
ain042: ;Message off end
 mov al,dh
 or al,dl
 jz lm04

 mov al,es:[bx] ;(Segment with GAMEDATA) Message header byte
 inc bx
 test al,080h ;JUMPH, Jump header ?
 jnz lm02

;Skip message

 dec bx
 call getmdlength
 add bx,cx

;End of message

 dec dx
 jmp short lm01

;Skip header

lm02:
 and al,7Fh ;Skip in message numbers
 mov ch,al
lm03:
 mov al,dh
 or al,dl
 jnz ain043
 ret
ain043:;No such message
 dec dx
 mov al,ch
 or al,al
 jz lm01
 dec ch
 jmp short lm03

;Found required message header

lm04:
 mov al,es:[bx]
 test al,080h ;JUMPH, Jump header ?
 je ain044
 ret
ain044:
 mov ds:startmsg,bx

 call getmdlength
lm05:
 mov al,ch
 or al,cl
 jnz ain045
 ret
ain045:
 mov dl,es:[bx]
 test dl,080h ;LONG, Long form ?
 jnz lm06

;Short form reference

 push bx
 push cx
 sub dh,dh
 mov bx,gamedata+0
 mov bx,es:[bx+14] ;Common Word Dictionary
 mov cx,gamedata+0
 add bx,cx
 add bx,dx
 add bx,dx
 mov dh,es:[bx]
 inc bx
 mov dl,es:[bx]
 pop cx
 pop bx
 jmp short lm07

;Long form reference

lm06:
 mov dh,es:[bx]
 inc bx
 dec cx
 mov dl,es:[bx]
lm07:
 inc bx
 dec cx

;Display word reference 'DE'

 mov al,dh
 cmp al,8Fh
 je ain046
 jmp short lm08
ain046:
 mov al,dl
 cmp al,80h
 jne lm08
 ret ;'|' terminator
lm08:
 push cx
 push bx
 call displaywordref
 pop bx
 pop cx
 jmp short lm05

;-----

;HL is the address in the Message Descriptors of a Message header
;Returns HL as the address of the first word-reference of that
;message and BC as the messages length (in bytes).
getmdlength:
 sub cx,cx
gl01:
 mov al,es:[bx]
 inc bx
 and al,03Fh
 or al,al
 jnz gl02
 push bx
 mov bx,003Fh
 add bx,cx
 mov ch,bh
 mov cl,bl
 pop bx
 jmp short gl01
gl02:
 dec al
 push bx
 sub bh,bh
 mov bl,al
 add bx,cx
 mov ch,bh
 mov cl,bl
 pop bx
 ret

;-----

checkmdt:
 push bx
 push dx
 mov dx,ds:endmd ;Start address of Message Descriptors
 sub bx,dx
 pop dx
 pop bx
 ret

;-----

;Display word reference 'DE'

displaywordref:
 mov al,dh
 shr al,1
 shr al,1
 shr al,1
 shr al,1
 and al,07h
 mov ds:wordtype,al

 mov al,dh
 and al,0Fh
 mov bh,al
 mov bl,dl
 mov cx,0F80h
 mov ds:wordcase,0
 sub bx,cx
 jb dn01

;Single character

 push bx
 mov al,ds:wordtype
 test al,00000010b
 mov al,' '
 jz ain048
 call printchar
ain048:
 mov al,2
 mov ds:mdtmode,al
 pop bx
 mov al,bl
 cmp al,"~"
 jz join
 call printchar
join:
 mov al,ds:wordtype
 test al,00000001b
 mov al,' '
 jz ain049
 call printchar
ain049:
 ret

;Word reference

dn01:
 mov al,ds:mdtmode
 cmp al,1
 mov al,' '
 jnz ain050
 call printchar
ain050:
 mov al,1
 mov ds:mdtmode,al

;Display word number DE

 mov al,dh
 and al,0Fh
 mov ch,al
 mov cl,dl
 call setindex
dn02:
;BC is word number to display
;HL is address of current index entry
;DE is number of index segments left
 mov al,dh
 or al,dl
 jz dn04
 push bx
 inc bx
 inc bx
 mov al,es:[bx]
 inc bx
 mov bh,es:[bx]
 mov bl,al
 sbb bx,cx
 pop bx
 jz dn03
 jnb dn04
dn03:
 push cx
 mov cl,es:[bx]
 inc bx
 mov ch,es:[bx]
 inc bx
 mov ds:[wordaddress],cx
 mov cl,es:[bx]
 inc bx
 mov ch,es:[bx]
 inc bx
 mov ds:wordnumber,cx
 pop cx
 dec dx
 jmp short dn02
dn04:

;Skip remaining words individually

 mov bx,cx
 mov cx,ds:wordnumber
 sub bx,cx
 push bx ;Word number offset

 mov bx,ds:[wordaddress]
 pop cx
 call initdict
 xchg dx,bx
 mov ch,cl ;Word number within this segment
 inc ch
 jmp short dn05

;Long code: Extract ascii code from next 10 bits

dn06a:
 push dx
 call getlongcode
 pop dx
 jmp short dn06b

;Not a header

dn06:
 cmp al,longc
 jnb dn06a

;Normal alpha

 add al,'a'

dn06b:
 xchg si,dx
 mov [si],al
 xchg si,dx
 inc dx

dn05:
 call getdictionarycode
 cmp al,header
 jb dn06

 and al,03h ;Get 'length'
 mov dl,al
 sub dh,dh
 mov bx,offset threecharacters
 add bx,dx
 xchg dx,bx
 dec ch
 jz ain051
 jmp short dn05
ain051:

 mov bx,offset threecharacters
dn09:
 or al,al
 jz dn10
 push ax
 mov al,[bx]
 call printautocase
 pop ax
 dec al
 inc bx
 jmp short dn09
dn10:
;Unpack dictionary word
 call getdictionarycode
 cmp al,endseg ;Header or end of segment ?
 jb ain052
 ret

ain052:
 call getdictionary
 call printautocase
 jmp short dn10

;-----

setindex:
 sub bx,bx ;Word number 0
 mov ds:wordnumber,bx
 mov bx,gamedata+0
 mov bx,es:[bx+6] ;Address of word number 0
 mov ds:[wordaddress],bx
 mov bx,gamedata+0
 mov bx,es:[bx+10] ;Word dictionary index
 mov dx,gamedata+0
 add bx,dx
 mov di,gamedata+0
 mov dx,es:[di+12]
 ret

;-----

;A is the current short-code.
;Returns A as the next unpacked ascii code.

getdictionary:
 cmp al,longc
 jnb getlongcode

;Normal alpha

 add al,'a'
 ret

;Long escape short code

getlongcode:
 call getdictionarycode
 cmp al,uppercasemark
 jne ga02

;Upper-case-only marker

 mov al,1
 mov ds:[wordcase],al
 call getdictionarycode
 jmp short getdictionary

ga02:
 rcl al,1
 rcl al,1
 rcl al,1
 rcl al,1
 rcl al,1
 and al,0E0h
 mov dl,al
 push dx
 call getdictionarycode
 and al,1Fh
 pop dx
 or al,dl
 or al,10000000b ;Flag character as a long-code
 ret

;-----

;Unpack and Return bytes from Word Dictionary

getdictionarycode:
;Preserves registers B and DE
 mov al,ds:[unpackpointer]
 cmp al,8
 jne ain053
 call unpackbytes
ain053:
 mov cl,al
 inc al
 mov ds:[unpackpointer],al
 mov al,ch
 sub ch,ch
 mov bx,offset unpack1
 add bx,cx
 mov ch,al
 mov al,[bx]
 ret

;-----

unpackbytes:
 mov bx,ds:[blockpointer]
 mov al,es:[bx] ;aaaaabbb
 ror al,1
 ror al,1
 ror al,1
 and al,1Fh
 mov ds:[unpack1],al ;000aaaaa
 mov al,es:[bx] ;aaaaabbb
 inc bx
 mov cl,es:[bx] ;bbcccccd
 rcl cl,1
 rcl al,1
 rcl cl,1
 rcl al,1
 and al,1Fh
 mov ds:[unpack2],al
 mov cl,es:[bx] ;bbcccccd
 rcr cl,1
 inc bx
 mov al,es:[bx] ;ddddeeee
 rcr al,1
 rcr al,1
 rcr al,1
 rcr al,1
 and al,1Fh
 mov ds:[unpack4],al
 mov al,cl
 and al,1Fh
 mov ds:[unpack3],al
 mov al,es:[bx] ;ddddeeee
 inc bx
 mov cl,es:[bx] ;efffffgg
 sal cl,1
 rcl al,1
 and al,1Fh
 mov ds:[unpack5],al
 mov al,es:[bx] ;efffffgg
 inc bx
 mov cl,es:[bx] ;ggghhhhh
 rcr al,1
 rcr cl,1
 rcr al,1
 rcr cl,1
 and al,1Fh
 mov ds:[unpack6],al
 mov al,cl
 rcr al,1
 rcr al,1
 rcr al,1
 and al,1Fh
 mov ds:[unpack7],al
 mov al,es:[bx] ;ggghhhhh
 and al,1Fh
 mov ds:[unpack8],al
 inc bx
 mov ds:[blockpointer],bx
 sub al,al ;Unpack pointer
 ret

;-----

;Convert A to upper-case.
;Returns 'A'. Flags corrupted.
upper: cmp al,'a'
 jnb ain054
 ret
ain054:
 cmp al,'z'+1
 jb ain055
 ret
ain055:
 sub al,20h
 ret

;-----

;Convert A to lower-case.
;Returns 'A'. Flags corrupted.
lower:
 cmp al,'A'
 jnb ain056
 ret
ain056:
 cmp al,'Z'+1
 jb ain057
 ret
ain057:
 add al,20h
 ret

;-----

;Print part of a word
printautocase:
 test al,10000000b ;Long code ?
 jne printchar
 push bx
 push ax
 mov al,ds:[wordcase]
 or al,al
 jnz dc02
 mov bx,offset wordtype
 mov al,[bx]
 cmp al,6
 jnb dc01
 pop ax
 jmp short dc03
dc01:
 mov byte ptr [bx],0
dc02:
 pop ax
 call upper
dc03:
 pop bx
printchar:
 push bx
 push dx
 push cx
 push ax
 test al,10000000b
 jz pc00
 and al,01111111b ;Remove escape-code flag
 jmp short pc02
pc00:
;Transparent characters: cr space " # $ % & ' ( )
 cmp al,' '
 je pc03
 cmp al,cret
 je pc03
 cmp al,'!'+1
 jb pc00a
 cmp al,')'+1
 jb pc03
pc00a:
;Sentance terminators: ! ? .
 mov al,ds:lastchar
 cmp al,'!'
 je pc01
 cmp al,'?'
 je pc01
 cmp al,'.'
 jne pc02
pc01:
 pop ax
 call upper
 push ax
pc02:
 pop ax
 and al,01111111b
 mov ds:lastchar,al
 push ax
pc03:
 cmp al,' '
 jne pc04
 call flush
 mov al,0FFh
 mov ds:pendspace,al
 jmp short pc06
pc04:
 cmp al,cret
 jne pc05
 call flush
 mov al,cret
 call wrapoutput
 jmp short pc06
pc05:
 mov bx,ds:[wrapbufferpointer]
 mov [bx],al
 inc bx
 mov ds:[wrapbufferpointer],bx

pc06:
 pop ax
 pop cx
 pop dx
 pop bx
 ret

;-----

wrapreset:
;(bx not corrupted)
 mov ds:mdtmode,0
 mov ds:nchars,0
 mov ds:lastchar,'.'
 push si
 mov al,13 ;widthdcode
 mov si,offset screenwidth
 call driver
 pop si
 dec ds:[screenwidth] ;OS can't display in last column
 dec ds:[screenwidth] ;Variable stores one less
 jmp short flush6

;-----

flush:
 mov al,ds:pendspace
 or al,al
 jz flush4
 mov al,ds:nchars
 mov ch,al
 mov bx,offset wrapbuffer
flush1:
 push bx
 mov dx,ds:[wrapbufferpointer]
 sub bx,dx
 pop bx
 jnb flush2
 inc bx
 inc ch
 jmp short flush1
flush2:
 mov al,ds:[screenwidth]
 cmp al,ch
 mov al,' '
 jnb flush3
 mov al,cret
flush3:
 call wrapoutput
flush4:
 mov bx,offset wrapbuffer
flush5:
 push bx
 mov dx,ds:[wrapbufferpointer]
 sub bx,dx
 pop bx
 jnb flush6
 mov al,[bx]
 call wrapoutput
 inc bx
 jmp short flush5
flush6:
 mov ds:[wrapbufferpointer],offset wrapbuffer
 mov ds:pendspace,0
 ret

;-----

wrapoutput:
 push bx
 push dx
 push cx
 cmp al,cret
 jne wrapoutput2
 mov al,ds:nchars
 or al,al
 jz wrapoutput3

 call oswrcr
wrapoutput1:
 mov ds:nchars,0
 jmp short wrapoutput3
wrapoutput2:
 call oswrch
 mov bx,offset nchars
 inc byte ptr [bx]
wrapoutput3:
 pop cx
 pop dx
 pop bx
 ret

;-----

unpackword:
 mov al,ds:lastheader ;Get similarity count
 cmp al,endseg ;Padder at end of segment ?
 stc
 jnz ain058
 ret
ain058:
 and al,3
 mov bx,offset threecharacters
 sub dh,dh
 mov dl,al
 add bx,dx
 mov ds:[headerpointer],bx

uw01:
 call getdictionarycode
 push ax
 mov bx,ds:endwdp5
 mov dx,ds:[blockpointer]
 mov al,bh
 cmp al,dh
 je ain059
 jmp short uw02
ain059:
 mov al,bl
 cmp al,dl
 je ain060
 jmp short uw02
ain060:
;End of dictionary
 pop ax
 stc
 ret

uw02:
 pop ax
 cmp al,endseg
 jnb uw03

;Not a header

 call getdictionary
 mov bx,ds:[headerpointer]
 mov [bx],al
 inc bx
 mov ds:[headerpointer],bx
 jmp short uw01

uw03:
 mov ds:lastheader,al
 mov bx,ds:[headerpointer]
 mov byte ptr [bx],0 ;Terminator
 ret

;-----

;HL is the offset from STARTFILE of start of
initdict:
 push cx
 mov cx,gamedata+0
 add bx,cx
 mov ds:[blockpointer],bx
 mov al,8
 mov ds:[unpackpointer],al
 mov bx,offset threecharacters
 mov ds:[headerpointer],bx
 pop cx
 ret

;-----

initunpack:
 call initdict
 mov al,header
 mov ds:lastheader,al
 jmp short unpackword

;-----

partword:
 call upper
 cmp al,"'"
 je pw02 ;Quote ok
 cmp al,'0'
 jb pw01 ;0-9 ok
 cmp al,'9'+1
 jb pw02
 cmp al,'A'
 jb pw01 ;A-Z ok
 cmp al,'Z'+1
 jb pw02
;Not part of a word
pw01:
 mov al,1
 or al,al
 ret ;Return 'NZ'
;Not part of a word
pw02:
 xor al,al
 ret ;Return 'Z'

;-----

findmsgequiv:
 mov ds:wordnumber,bx ;Save Word number
 sub bx,bx ;Message number
 mov ds:[startmsg],bx ;Message Number
 mov bx,ds:startmd ;Start address of Message Descriptors
 jmp short fe02

fe01:
 mov cx,ds:[startmsg] ;Message Number
 inc cx
 mov ds:[startmsg],cx ;Message Number

fe02:
 call checkmdt
 jb ain061
 ret
ain061: ;Searched all messages

 mov al,es:[bx] ;Message header byte
 inc bx
 test al,080h ;JUMPH, Jump header ?
 jnz fe03

;Found a message header

 test al,040h ;PARSE, Contains keywords ?
 jnz fe04 ;Yes (usually false)
 dec bx
 call getmdlength
 add bx,cx
 jmp short fe01

;Skip header

fe03:
 and al,7Fh ;Skip in message numbers
 push bx
 mov bx,ds:[startmsg] ;Message Number
 sub ch,ch
 mov cl,al
 add bx,cx
 inc bx
 mov ds:[startmsg],bx ;Message Number
 pop bx
 jmp short fe02

;Found a message header

fe04:
 dec bx
 call getmdlength
fe05:
 mov dx,ds:wordnumber
 jmp short fe08
fe06:
 inc bx
 dec cx
fe07:
 inc bx
 dec cx
fe08:
 mov al,ch
 or al,cl
 jz fe01
 mov al,es:[bx]
 test al,080h ;long
 jz fe07
;Compare long form reference
 cmp al,90h
 jb fe06 ;Garbage word
 inc bx
 dec cx
 and al,0Fh
 cmp al,dh
 jne fe07
 mov al,es:[bx]
 inc bx
 dec cx
 cmp al,dl
 jne fe08
;Hi byte of sequence is (HL-2)
 dec bx
 dec bx
 mov dh,es:[bx]
 inc bx
 inc bx

;Message found D contains word-type

 push bx
 mov al,dh
 add al,al
 and al,0E0h
 mov bx,ds:[startmsg] ;Message Number
 or al,bh
 mov bh,al
 xchg dx,bx
 mov bx,ds:list9pointer
 push bx
 push cx
 mov cx,ds:list9
 sub bx,cx
 mov al,bl                  ;Length of list
 cmp al,64
 pop cx
 pop bx
 jnb fe09 ;List has 32 Entries

 mov es:[bx],dh
 inc bx
 mov es:[bx],dl
 inc bx
 mov ds:list9pointer,bx
 pop bx
 jmp short fe05

fe09:

 pop bx
 ret

;-----

getnextobject:
; Given first VAR=HISEARCHPOS and second VAR=SEARCHPOS
; return third VAR=OBJECT and fourth VAR=NUMBER of object in this pass
; if HISEARCHPOS=0, then initialise tree search
; at end of search, return OBJECT=0

 call gethlval
 mov ds:maxobject,cl
 inc bx
 call gethlval
 mov ds:hisearchpos,cl      ; A one-byte value
 mov ds:hisearchposvar,dx
 inc bx
 call gethlval
 mov ds:searchpos,cl        ; A one-byte value
 mov ds:searchposvar,dx
 inc bx
 mov ds:[hlsave],bx
getnextobjectabs:

 mov bx,offset searchpos
 mov al,ds:hisearchpos
 or al,[bx]                 ; searchpos
 jnz ain062
 jmp initgetobjsp
ain062: ; set up,ret

 mov al,ds:numobjectfound
 or al,al
 jnz gnonext

 mov al,ds:hisearchpos
 mov ds:inithisearchpos,al
gnonext:
 inc ds:object
 mov dl,ds:object
 sub dh,dh
 mov bx,ds:list2            ; Current position of objects
 add bx,dx
 mov al,ds:searchpos
 cmp al,es:[bx]
 jne ain063
 jmp gnomaybefound
ain063:
 mov al,ds:maxobject
  cmp al,dl
 jnb gnonext
; Have reached end of current pass
 mov al,ds:inithisearchpos
 cmp al,nonspecific
 jne gnonewlevel
; Started off as non-specific search, so there
; may be unscanned directions to try
 mov bl,ds:hisearchpos
 sub bh,bh
;! mov dx,offset gnoscratch
;! add bx,dx
 add bx,offset gnoscratch ;!
 mov byte ptr [bx],0
 mov ds:hisearchpos,0
gnoloop:
 mov bl,ds:hisearchpos
 sub bh,bh
 mov dx,offset gnoscratch
 add bx,dx
 mov al,[bx]
 or al,al
 jz gnoloop1
 mov al,ds:searchpos
 call gnopush
 mov al,ds:hisearchpos
 call gnopush
gnoloop1:
 inc ds:hisearchpos
 mov al,ds:hisearchpos
 cmp al,nonspecific
 jb gnoloop
gnonewlevel:
 call gnopop
 mov ds:hisearchpos,al
 call gnopop
 mov ds:searchpos,al

 mov ds:numobjectfound,0
 mov al,ds:hisearchpos
 cmp al,nonspecific
 jne gnonewlevelcont
; Nonspecific HISEARCHPOS, so this is a real new level
 inc ds:searchdepth
gnonewlevelcont:
 call initgetobj
 mov al,ds:searchpos
 or al,al
 jz ain064
 jmp getnextobjectabs
ain064:
getnextfinish:

; That's all folks !
 sub bx,bx
 mov ds:object,bl
 mov ds:searchpos,bl
 mov ds:hisearchpos,bl
gnoreturnargs:
 mov bx,ds:hisearchposvar
 mov al,ds:hisearchpos
 mov es:[bx],al
; mov byte ptr es:1[bx],0
 mov bx,ds:searchposvar
 mov al,ds:searchpos
 mov es:[bx],al
; mov byte ptr es:1[bx],0

 mov bx,ds:[hlsave] ; PC
 call gethlval
 mov al,ds:object
 xchg si,dx
 mov es:[si],al
; mov byte ptr es:1[si],0
 xchg si,dx
 inc bx
 call gethlval
 mov al,ds:numobjectfound
 xchg si,dx
 mov es:[si],al
; mov byte ptr es:1[si],0
 xchg si,dx
 inc bx
 call gethlval
 mov al,ds:searchdepth
 xchg si,dx
 mov es:[si],al
; mov byte ptr es:1[si],0
 xchg si,dx
 inc bx
 ret

;-----

gnomaybefound:
; Quick check suggests we may have something here
 call gnogethiobjectpos
 mov al,ds:hipos
 cmp al,ds:hisearchpos
 je gnofound
 and al,al
 jnz ain065
 jmp gnonext
ain065:
 cmp ds:hisearchpos,0
 jne ain066
 jmp gnonext
ain066:
;Want same obj in different containment
 mov al,ds:hisearchpos
 cmp al,nonspecific
 je gnomf1
;Note it down for reference at end
 mov al,ds:hipos
 mov dl,al
 sub dh,dh
 mov bx,offset gnoscratch
 add bx,dx
 mov [bx],al
 jmp gnonext

gnomf1:
; Start looking for this type rather than nonspecific type
 mov al,ds:hipos
 mov byte ptr ds:hisearchpos,al
gnofound:
 inc ds:numobjectfound
 mov al,ds:object ;Want references to this object
 call gnopush
 mov al,nonspecific
 call gnopush
; Found object, so return it to calling prog
 jmp gnoreturnargs

;-----

initgetobjsp:
 mov bx,offset gnospbase
 mov ds:gnosp,bx
 mov ds:searchdepth,0
 call initgetobj
 jmp gnoreturnargs

;-----

initgetobj:
 mov ds:numobjectfound,0
 mov ds:object,0
 mov cx,nonspecific
 mov bx,offset gnoscratch
igo1:
 mov byte ptr [bx],0
 inc bx
 loop igo1
 ret

;-----

gnopush:
 mov bx,ds:gnosp
 mov [bx],al
 inc bx
 mov ds:gnosp,bx
 sub bx,offset gnomaxsp
 jz pusherror
 ret
pusherror:
 call gnopop
poperror:
 xor al,al
 ret

;-----

gnopop:
 mov bx,ds:gnosp
 sub bx,offset gnospbase
 jz poperror
 dec ds:gnosp ;!
 mov bx,ds:gnosp
;! dec bx
;! mov ds:gnosp,bx
 mov al,[bx]
 ret

;-----

gnogethiobjectpos:
; return HIPOS=Containment type
 mov dl,ds:object
 sub dh,dh
 mov bx,ds:list3            ; hicurrentpos list
 add bx,dx
 mov al,es:[bx]
 and al,1Fh
 mov ds:hipos,al
 ret

;-----

oswrcr:
 mov al,cret
oswrch:
 mov 0[si],al
 mov al,oswrchdcode
 jmp driver

;-----

code ends

 end




