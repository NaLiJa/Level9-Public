;IBM KAOS DRIVER

;DRIVER.ASM

;Copyright (C) 1987,1988 Level 9 Coputing

;-----

NAME DRIVER

 public chain
 public checksum
 public demoenable
 public displaybackspace
 public filenamebuffer
 public getcharacter
 public getseed
 public inputline
 public osload
 public osrdch
 public ossave
 public pagefull
 public pushreadkeyboard
 public readkeyboard
 public replacecursor
 public resetpagecount
 public SafeReplaceCursor
 public setoscursor
 public trydisk
 public updatekeyboardbuffer

;In GRAPHIC.ASM:
 extrn cursorenable:byte
 extrn cursortype:near
 extrn entrydisplayall:near
 extrn graphicdisplayall:near
 extrn redisplaytextbottomhalf:near
 extrn scrolledlines:byte

;In CGA.ASM:
 extrn cgacopytoscreen:near
 extrn cgaforceoff:near

;In EDSQU.ASM:
 extrn aintrestart:near
 extrn cursorcr:near
 extrn cursordown:near
 extrn cursorup:near

;In ENTRY.ASM:
 extrn calcpages:near
 extrn characterwidth:byte
 extrn close:near
 extrn diskbuffer:byte
 extrn fcbdrive:byte
 extrn kbdbuffer:byte
 extrn kbdbuflen:byte
 extrn pagingonoff:byte
 extrn screenmode:byte

;In HIRES.ASM:
 extrn ClearTitle:near
 extrn cgapictureshown:byte
 extrn picturelines:near
 extrn sp02:near

;In MENU.ASM:
 extrn LoadUpFile:near

;-----

;           Either   Signed   Unsigned
;    <=              jle      jbe
;    <               jl       jb/jc
;    =      je/jz
;    <>     jnz/jne
;    >=              jge      jae/jnc
;    >               jg       ja

;-----

;Constants likely to change:

;Ascii/BBC control codes:
asciibs  = 08h
asciilf  = 0Ah
asciicr  = 0Dh
space    = ' '
asciidel = 07Fh

;-----

code SEGMENT public 'code'
 ASSUME cs:code,ds:code

;These include files must be named in MAKE.TXT:
 include head.asm

;-----

filenamebuffer db inputbuffersize DUP (0)

lastkbdsize db 0

demoenable db 0
demoindex dw 0 ;Offset into DEMO.TXT

savedcursor dw 0 ;Cursor X,Y during OS calls.
savedcursor2 dw 0 ;Cursor X,Y during OS calls.

;During INPUTLINE, 'screenbuffer' and 'actualcursoroffset' reflect
;what the user can see on the screen - because of the length of time
;it takes to display in EGA this may lag behind the actual contents
;of 'inputbuffer'.

screenbuffer db inputbuffersize+2 DUP (' ')
actualcursor db 0 ;Where real cursor is now.

;-----

pagingoff:
 xor al,al
pagingon:
 mov ds:[pagingonoff],al
 ret

;-----

getseed:
 mov bx,cs:[MenuFseed]
 mov ds:0[si],bl
 mov ds:1[si],bh
 ret

;-----

returnwidth:
 mov al,ds:[characterwidth]
 mov ds:0[si],al
 ret

;-----

;Reset 'lines on this page' count.

resetpagecount:
 mov al,ds:[kbdbuflen]
 mov ds:[lastkbdsize],al
 mov ds:[scrolledlines],0
 ret

;-----

notnull:
 cmp al,0
 jnz nn01
 mov al,' '
nn01:
 ret

;-----

;Update screen is called repeatedly during inputline while there is
;no input to process. Because updating the screen is slow (esp. EGA)
;this outputs one character/moves the cursor one step to make the screen
;reflect what the user has typed.

updatescreen:
;[si] is the current input buffer, bh is its length.
;bl is the 'user-cursor' position (the point at which typed chars appear)

 mov di,offset screenbuffer 
 mov cx,0 ;ch='temp cursor' for location being compared, cl=index into buffer
compare:
 cmp ch,bl ;At cursor location?
 jnz cursoroff
 call cursortype
 cmp al,0
 jz cursoroff ;This screen mode does not require software cursor.

 mov al,05Fh ;Use '_' character as cursor.
 cmp [di],al
 jz cursorok ;Cursor is already displayed
 jmp short check4

cursorok: ;Skip underline character
 inc di 
 inc ch
cursoroff:
 cmp cl,inputbuffersize ;Done 80-character input line?
 jnz check

;B/W modes have a flashing h/w cursor which OS locates at its cursor
; position, so leave cursor at correct location.

 cmp bl,ds:actualcursor
 jz updatecomplete
 mov ch,bl
 jmp short movetoch

updatecomplete:
 mov al,0 ;Return 'UPDATE COMPLETE'
 ret

;Characters beyond the end of the current input line are treated as
;a space character; this is the same as initialised by 'newbuffer'
;so these locations never need to be refreshed except when the command-
;recall editor makes the input line shorter.

check:
 cmp cl,bh ;Over end of input buffer
 jb check2
 mov al,' '
 jmp short check3
check2:
 push bx
 mov bh,0
 mov bl,cl
 mov al,ds:[si+bx]
 call notnull
 pop bx
check3:
 cmp ds:[di],al
 jnz check4

;Screen characters 1..ch, input buffer 1..cl, and screenbuffer..di
;are the same, so try the next character in left-to-right order.
 inc cl
 inc ch
 inc di
 jmp short compare

;The screen and input buffer differ: 
;al is an ascii character to display, [di] is the character currently on
;the screen in 'screenbuffer'.ch the index into screenbuffer, cl the index
;into the input buffer.

check4:
 cmp ch,ds:actualcursor
 jz writeal

;The OS cursor is not at the screen address that needs to be updated:

movetoch: ;
 cmp ch,ds:actualcursor
 jnc moveforward
 call displaybackspace
 dec ds:actualcursor
 mov al,1 ;Signal 'MORE TO DO'
 ret

;(The OS cursor is not at the screen address that needs to be updated)
;Even though the character on the screen at the OS cursor position is
;known to be correct the easiest way to perform cursor-right is to 
;re-write this character; This works in all screen modes and handles
;the right-hand edge of the screen and scolling correctly.

moveforward:
 mov di,offset screenbuffer
 mov al,ds:actualcursor
 mov ah,0
 add di,ax
 mov al,ds:[di] ;Read the character already on the screen

;Write the character al to the screen. di is offset into screenbuffer,

writeal:
 call notnull
 mov ds:[di],al

 cmp al,' ' ;Ensure not going to print a control character
 jb invalid
 cmp al,080h
 jb valid
invalid:
 mov al,'?'
valid:

 call graphicdisplayall
 inc ds:actualcursor
 mov al,1 ;Signal 'MORE TO DO'
 ret

;-----

;screen buffer represents the screen display during input line, which may
;lag behind the actual contents of inputbuffer. Clearing this buffer will
;force a complete re-fresh of the current inputline display.

newbuffer:
 push bx
 mov bx,offset screenbuffer
 mov cx,inputbuffersize
nb01:
 jcxz nb02
 mov byte ptr [bx],' '
 inc bx
 dec cx
 jmp short nb01
nb02:
 pop bx
 mov ds:[screenbuffer],asciibs ;
 ret

;-----

;-----

;Request a line of input stored at an 81-byte buffer at [si] with
;full line- and command-editor in ALL screen modes.

inputline:
 cmp ds:[cgapictureshown],0 ;No CGA picture drawn yet
 jz ip00
 mov ds:[cgapictureshown],1 ;Flag picture to be re-shown.
ip00:

 mov ds:cursorenable,1
 call newbuffer
 mov ds:actualcursor,0
 call resetpagecount
 mov bx,0 ;bh=Number of chars, bl=Cursor position
ip01:
 push bx

ip02:
 call getcharacter
 cmp al,0
 jnz ip03
 push si
 push bx
 call updatescreen
 pop bx
 pop si
 jmp short ip02

ip03:
 cmp al,'*' ;In demo mode '*' causes a delay
 jnz notdelay
 cmp ds:[demoenable],0
 jz notdelay

 mov ah,0 ;Read Current Clock Count
 int 26 ;Time-of-Day Service
 add dx,18 ;Low order of clock count, add 1 second

ip03a:
 push si
 push bx
 push dx
 call updatescreen ;continue processing line-editor
 pop dx
 pop bx
 pop si

 push dx ;End-of-Delay-Time
 mov ah,0 ;Read Current Clock Count
 int 26 ;Time-of-Day Service
 mov ax,dx
 pop dx
 cmp ax,dx
 jb ip03a ;If Time-now < End-of-delay-Time ?

 jmp short ip02

notdelay:
 pop bx

 cmp al,19 ;Alt-R
 jnz notdemo
;Cannot read alt-R from file so auto-demo must be off
 cmp word ptr cs:[MenuLautorun],0
 jnz setautorunon
 push si
 push bx
 mov di,offset autorunerror
 jmp short ip04
setautorunon:
 mov ds:[demoenable],1
 push si
 push bx
 mov di,offset democontinue
ip04:
 call prs
 pop bx
 pop si
 jmp short redisplayinput

notdemo:
 cmp al,3 ;Break?
 jnz notbreak

;If 'getcharacter' returns ^C then driver will have displayed option to
;quit adventure system, so screen has now scrolled to be a blank line
;with the cursor at column 1.
redisplayinput:
 call newbuffer
 mov ds:actualcursor,0 ;Real cursor reset
 mov bl,0 ;reset final position of 'underline' cursor
 jmp short ip01

notbreak:
 cmp al,6 ;Cursor forward
 jnz notforward
 jmp inputforward
notforward:

 cmp al,2 ;Cursor left
 jnz ip05
 jmp inputbackward
ip05:

 cmp al,21 ;Cursor up
 jnz notup1
 call cursorup
 jmp ip01
notup1:

 cmp al,4 ;Cursor down
 jnz notdown1
 call cursordown
 jmp ip01
notdown1:

 cmp al,asciibs
 jz jmpdelete
 cmp al,asciidel
 jnz notdelete
 jmp inputdelete
jmpdelete:
 jmp inputbackspace

notdelete:
 cmp al,asciicr
 jnz dbi024
 jmp short inputreturn

dbi024:
 cmp al,9 ;Tab - Switches to view picture
 jnz nottab
 push si
 push bx
 call cgacopytoscreen
 pop bx
 pop si
 jmp ip01

nottab:
 cmp al,space
 jnc inpl8a
 jmp ip01 ;Control code ignored

inpl8a:
 cmp al,'a' ;Convert lower case to upper case
 jb notlower
 cmp al,'z'+1
 jae notlower
 and al,0DFh
notlower:
 cmp bh,inputbuffersize
 jnz inpl9
 jmp ip01
inpl9:
 push ax ;Character to insert
 push bx
 mov bh,0
inpl9b:
 cmp bl,inputbuffersize
 jnc inpl9a
 mov ah,cs:[si+bx]
 mov cs:[si+bx],al
 mov al,ah
 inc bl
 jmp short inpl9b
inpl9a:
 pop bx
 pop ax
 inc bh
 inc bl
 jmp ip01

inputreturn:
 mov bl,bh ;Move cursor to end of line so scrolling works
 mov ds:cursorenable,0
removecursor:
 push si
 push bx
 call updatescreen
 pop bx
 pop si
 cmp al,0
 jnz removecursor

 push bx
 mov bl,bh
 mov bh,0
 mov byte ptr cs:[si+bx],0
 pop bx

 mov al,asciicr
 call entrydisplayall
 jmp cursorcr

inputforward:
 cmp bl,inputbuffersize
 jc if01
 jmp ip01 ;At limit of line length
if01:
 cmp bl,bh
 jc if02 ;Within current line
 push bx
 mov bh,0
 mov byte ptr cs:[si+bx],' '
 pop bx
 inc bh
if02:
 inc bl
 jmp ip01

inputbackward:
 cmp bl,0
 jnz ib01
 jmp ip01 ;At start of line
ib01:
 dec bl
 jmp ip01

inputdelete:
 cmp bl,bh
 jc id02
 jmp ip01 ;At end of current line

inputbackspace:
 cmp bh,0
 jnz id01
id00:
 jmp ip01 ;Nothing to delete
id01:
 cmp bl,0 ;Delete at start of line
 jz id00
;Delete character behind cursor
 dec bl
id02:
 push bx
 mov bh,0
id03:
 cmp bl,inputbuffersize
 jz id04
 inc bl
 mov al,cs:[si+bx]
 dec bl
 mov cs:[si+bx],al
 inc bl
 jmp short id03
id04:
 mov bx,bx
 mov byte ptr cs:[si+bx],' '
 pop bx
 dec bh
 jmp ip01

;-----

;Alt-R messages:
autorunerror:
 db "!R"
 db asciicr
 db 0

democontinue:
 db "!R"
 db asciicr
 db asciicr
 db "Demo resumed."
 db asciicr
 db asciicr
 db 0

;If a key has been pressed then no need to display message, just read
;keyboard characters no more or driver buffer is full then remember this
;as new (LASTKBDLEN).
;Otherwise display message and wait for a key.

anykey:
 db "(Press any key to continue)"
anykeyend:
 db 0

erasemessage:
 db anykeyend-anykey dup ( asciibs," ",asciibs )
 db 0

;-----

pagefull:
 cmp ds:[demoenable],0
 jz pf03 ;Only wait for key when not in demo-mode.

;In DEMO mode do a fixed 10-second delay

 push ax
 push cx
 push dx

 mov ah,0 ;Read Current Clock Count
 int 26 ;Time-of-Day Service
 add dx,10*18 ;Low order of clock count, add 10 seconds

pf02:
 push dx ;End-of-Delay-Time
 mov ah,0 ;Read Current Clock Count
 int 26 ;Time-of-Day Service
 mov ax,dx
 pop dx
 cmp ax,dx
 jb pf02 ;If Time-now < End-of-delay-Time ?

 pop dx
 pop cx
 pop ax

 jmp resetpagecount

pf03:
 cmp ds:[kbdbuflen],0
 jz pf04
 mov al,ds:[kbdbuflen]
 cmp al,ds:[lastkbdsize]
 jnz pf07 ;Keys have been pressed since last INPUTLINE of PAGEFULL

;Display message and wait for either a SHIFT or SPACE

pf04:
 mov di,offset anykey
 call prs

pf05:
 mov ah,2 ;Keyboard Service 2 - Get Shift Status
 int 16h ;ROM-BIOS Keyboard Service
 and al,0Fh ;Mask to give alt shift, ctrl shift, left shift, right shift
 cmp al,0
 jnz pf06 ;No-code generating key

 call readkeyboard
 cmp al,0
 jz pf05

pf06:
 mov di,offset erasemessage
 call prs

pf07:
 jmp resetpagecount

;-----

updatekeyboardbuffer:
 cmp ds:[demoenable],0
 jz uk00
 ret ;Keyboard buffer is not needed during demo, don't swallow alt-r

uk00:
 cmp ds:[kbdbuflen],kbdbufsize
 jnz dbi022
 ret ;Buffer full

dbi022:
 call readkeyboard
 or al,al
 jnz update1
 ret ;No (more) characters

update1:
 call update2
 jmp short updatekeyboardbuffer

update2:
 mov bl,ds:[kbdbuflen]
 mov bh,0
 add bx,offset kbdbuffer
 mov [bx],al
 mov bx,offset kbdbuflen
 inc byte ptr [bx]
 ret

pushreadkeyboard:
 cmp ds:[kbdbuflen],kbdbufsize
 jnz update2
 ret ;Buffer full

;-----

getcharacter:
 call gc01
 cmp al,3 ;^C
 jnz notterminate

 push bx
 push cx
 mov di,offset askquit
 call prs

askagain:
 call gc01
 or al,020h
 cmp al,'y'
 jz terminate
 cmp al,'n'
 jnz askagain
 mov di,offset no
 call prs
 pop cx
 pop bx
 mov ax,3 ;return ^c so caller can reset cursor
 jmp short notterminate

terminate:
 mov di,offset yes
 call prs

 mov ah,76 ;Terminate
 int 21h ;Dos Service

notterminate:
 ret

;-----

;    1234567890123456789012345678901234567890

askquit:
 db 13
 db "Do you really want to leave the game? "
 db 0

no:
 db 'N',13,0

yes:
 db 'Y',13,0

;-----

gc01:
 push si
 push bx
 push cx
 push dx
 call gc02
 pop dx
 pop cx
 pop bx
 pop si
 ret

gc02:
 cmp ds:[demoenable],0
 jnz getdemocharacter

 cmp ds:[kbdbuflen],0
 jz readkeyboard

 mov al,ds:[kbdbuffer]
 mov si,offset kbdbuffer+1
 mov cx,kbdbufsize-1
 push ax
 mov di,offset kbdbuffer
ldirds:
 cmp cx,0
 jz ldirdsend
 mov al,ds:0[si]
 mov ds:0[di],al
 inc di
 inc si
 dec cx
 jmp short ldirds
ldirdsend:
 pop ax
 dec ds:[kbdbuflen]

 ret

getdemocharacter:
 call checkdemoexit ;alt-R turns off auto-demo.
 cmp ds:[demoenable],0
 jnz gd01 
 mov al,0
 ret

gd01:
 mov bx,ds:[demoindex]
 inc ds:[demoindex]
 mov es,cs:[MenuPautorun]
 mov al,es:[bx]
 cmp al,asciilf
 jz getdemocharacter
 cmp al,asciicr
 jz gotdemo
 cmp al,' '
 jnc gotdemo
 mov ds:[demoindex],0 ;EOF character, reset demo file
 jmp short getdemocharacter
gotdemo:
 cmp al,80h
 jnc getdemocharacter
 ret

readkeyboard:
 mov ah,01 ;Service 1 (Report keyboard)
 int 16h ;ROM-BIOS keyboard service
 jnz getch2
 mov al,0
 ret
getch2:
 mov ah,00h ;Service 0 (Read Next Keyboard Character)
 int 16h ;ROM-BIOS keyboard service
 cmp ax,01300h ;Alt-R
 jnz notaltr
 mov ax,19
 ret
notaltr:
 cmp ax,04800h ;Cursor up
 jnz notup2
 mov ax,21
 ret
notup2:
 cmp ax,04b00h ;Cursor left
 jnz notleft
 mov ax,2
 ret
notleft:
 cmp ax,04d00h ;Cursor right
 jnz notright
 mov ax,6
 ret
notright:
 cmp ax,05000h ;Cursor down
 jnz notdown2
 mov ax,4
 ret
notdown2:
 cmp ax,05300h ;DEL
 jnz notdel
 mov ax,asciidel
 ret
notdel:
 cmp ax,04700h ;Home
 jz keypad
 cmp ax,04900h ;PgUp
 jz keypad
 cmp ax,04F00h ;End
 jz keypad
 cmp ax,05100h ;PgDn
 jz keypad
 cmp ax,00F00h ;Reverse TAB
 jnz justreturn
keypad:
 mov ax,9

justreturn:
 RET

;-----

checkdemoexit:
 call readkeyboard
 cmp al,19
 jz gotkey
 cmp al,0
 jnz checkdemoexit
 ret

gotkey:
 mov di,offset demointerrupt
 call prs
 mov word ptr cs:[demoenable],0
 ret

demointerrupt:
 db "!R"
 db asciicr
 db asciicr
 db "Demo off. (!R to resume.)"
 db asciicr
 db asciicr
 db 0

;-----

displaybackspace:
 mov ah,03 ;Service 3 - Read Cursor Position
 mov bh,0 ;Page number (text mode only)
 int 10h ;ROM-BIOS video service
 cmp dl,0 ;Cursor column
 mov al,asciibs
 jnz dosbackspace ;Can use DOS backspace routine
 dec dh ;Cursor row, go up one line
 mov al,ds:[characterwidth]
 dec al
 mov dl,al ;Cursor column to end of line
 mov bh,0 ;Screen page (text mode only)
 mov ah,2 ;Service 2 - Set Cursor Position
 int 10h ;ROM-BIOS video service
 ret
dosbackspace:
 mov ah,0Eh ;Service 14 (Write character as tty)
 int 10H ;ROM-BIOS video service
 ret

;-----

osrdch:
 cmp ds:[demoenable],0
 jnz allowgoaldirected
 call getcharacter
 cmp al,3 ;^C only allowed in input-line
 jz osrdch
 cmp al,19 ;Alt-R only allowed from input-line and in auto-demo
 jz osrdch
 jmp short returncode
allowgoaldirected:
 mov al,0
returncode:
 mov ds:0[si],al
 ret

;-----

checksum:
 mov bl,ds:2[si] ;End address
 mov bh,ds:3[SI]
 mov dl,ds:0[SI] ;Start address
 mov dh,ds:1[SI]
 sub bx,dx
 mov cx,bx
 xchg dx,bx ;hl=sTART ADDRESS

 inc cx
 mov dl,0
checksum1:
 cmp cx,0
 jz checksum2
 add dl,es:[bx]
 inc bx
 dec cx
 jmp short checksum1
checksum2:
 mov ds:0[si],dl ;Result
 ret

;-----

checkdisk:
 call trydisk
 jnc cd01
 pushf
 mov di,offset missing
 call prs
 popf
cd01:
 ret

missing:
 db "Disk missing."
 db 13,0

;-----

;Remembers current cursor position for recall by REPLACECURSOR
;then sets cursor just below picture/ top line of text.
;This is NOT recursive.
;Preserves AX (Page count) and BX (address)

setoscursor:
 push ax
 push bx
 mov ah,03 ;Service 3 - Read Cursor Position
 mov bh,0 ;Page number (text mode only)
 int 10h ;ROM-BIOS video service
 mov word ptr ds:[savedcursor],dx ; dh=row, dl=column.

 push dx ;Cursor position
 call cgaforceoff
 pop dx
 cmp ds:[screenmode],4 ;Modes 0 thru 3 are text-only and CGA colour-graphics.
 jc so01

;dh=row, dl=column.
 mov dl,19 ;Set column other than column 1
 mov ds:[savedcursor2],dx
 mov ah,2  ;Service 2 - Set Cursor Position
 int 10h   ;ROM-BIOS video service

so01:
 pop bx
 pop ax
 ret

;-----

;Resets cursor position to that of the last SETOSCURSOR call.
;Preserves ax (return code) and flags (return status).

replacecursor:
 pushf
 push ax
 push bx
 push cx
 push dx
 push ds
 push es
 push si
 push di

 mov ah,03 ;Service 3 - Read Cursor Position
 mov bh,0 ;Page number (text mode only)
 int 10h ;ROM-BIOS video service
 cmp word ptr ds:[savedcursor2],dx ; dh=row, dl=column.
 jz cursornotmoved

 cmp byte ptr cs:MenuFgraphicpossible,0
 jz cursornotmoved ;WORDS mode

 mov dx,ds:savedcursor2 ;Get previous bottom screen line
 mov dl,dh
 call redisplaytextbottomhalf
 cmp byte ptr cs:MenuFpicturetype,0
 jz cursornotmoved ;Was in WORDS before
 mov byte ptr cs:MenuFpicturetype,0
 call sp02

cursornotmoved:
 mov ah,2 ;Service 2 - Set Cursor Position
 mov dx,word ptr ds:[savedcursor] ;dh=row, dl=column.
 mov bh,0 ;(Page number)
 int 10h  ;ROM-BIOS video service
 mov word ptr ds:[savedcursor],0

 pop di
 pop si
 pop es
 pop ds
 pop dx
 pop cx
 pop bx
 pop ax
 popf
 ret

;-----

;Resets cursor position to that of the last SETOSCURSOR call.
;Preserves ax (return code) and flags (return status).

SafeReplaceCursor:
 pushf
 push ax

 mov ah,2 ;Service 2 - Set Cursor Position
 mov dx,word ptr ds:[savedcursor] ;dh=row, dl=column.
 mov bh,0 ;(Page number)
 int 10h  ;ROM-BIOS video service

 pop ax
 popf
 ret

;-----

ossave:
 mov byte ptr ds:[si],0 ;success return code.

 mov es,cs:MenuPgame ;Gamedata & workspace segment
 push es
 call getnam
 pop es

;Try to guess which disk file name refers to, and
;check that the disk can be read.

 mov cs:fcbdrive,0 ;default to current log-in drive.
 cmp cs:1[filenamebuffer],':'
 jnz ossave3
 mov al,cs:0[filenamebuffer]
 sub al,'A'-1
 mov cs:fcbdrive,al
ossave3:
 call checkdisk
 jnc ossave3a
 ret ;Disk missing (non-fatal)

ossave3a:
 mov es,cs:MenuPgame ;Gamedata & workspace segment
 mov cx,workspacesize
 mov dx,offset filenamebuffer
 call writefile
 cmp al,0
 jz ossave5
 cmp al,1
 jnz ossave4

;File nof found...

 mov di,offset notsaved
 jmp prs

;Read error....

ossave4:
 mov di,offset notsaved
 jmp prs

;Got a file loaded, so check its length. I can check if the file
;was shorter than expected, but not if it is longer (the ACODE
;has to resolve this)

ossave5:
 cmp cx,workspacesize
 jnz ossave4 ;Not correct length, so give read error
 ret

;-----

;Save a file, length CX, name in DX, to address ES:0
;Returns AL=0 if OK (cx=bytes loaded)
;        AL=1 if file not found
;        AL=3 if file can't load

writefile:
 push cx   ;Length

 push dx   ;filename
 mov ah,65 ;Delete file
 int 21h   ;extended DOS function
 pop dx    ;filename

 mov cx,0  ;non-archive, non-system, non-hidden, writeable.
 mov ah,60 ;Create file
 int 21h   ;extended DOS function

 pop cx ;Length

 jnc le01
 mov al,1  ;can't create
 ret

le01:
 push ax   ;File handle
 push cx   ;length
 mov bx,ax
 mov al,0  ;relative to start of file
 mov cx,0  ;relative position (high)
 mov dx,0  ;relative position (low)
 mov ah,66 ;move file pointer
 int 21h   ;extended DOS function
 pop cx    ;length
 pop ax    ;file handle

 push ax   ;File handle
 push ds

 mov bx,ax ;file handle
; cx=length
 mov ax,es
 mov ds,ax
 mov dx,0  ;address DS:DX = ES:0
 mov ah,64 ;Write to file
 int 21h   ;extended DOS function
 jnc le02

;Error
 pop ds
 pop bx    ;File handle
 mov ah,62 ;Close file handle
 int 21h   ;extended DOS function

 mov al,3  ;Can't write file
 ret

le02:
 mov cx,ax ;Number of bytes loaded
 pop ds
 pop bx    ;File handle

 mov ah,62 ;Close file handle
 int 21h   ;extended DOS function

 mov al,0  ;File written
 ret

;-----

notsaved:
 db "Position not saved."
 db 13,0

;-----

message2:
 db "Filename? "
 db 0

getnam:
 mov di,offset message2
 call prs

 mov si,offset filenamebuffer
 call inputline
 ret

;-----

osload:
 mov byte ptr ds:[si],0 ;success return code. Failures are handled internally

osload1:
 mov es,cs:MenuPgame ;Gamedata & workspace segment
 push es
 call getnam
 pop es
 cmp cs:filenamebuffer,0
 jnz osload2

;The only way to escape RESTORE without loading a position is to
;enter a null filename.

 jmp aintrestart ;Only way to es

;Try to guess which disk file name refers to, and
;check that the disk can be read.

osload2:
 mov cs:fcbdrive,0 ;default to current log-in drive.
 cmp cs:1[filenamebuffer],':'
 jnz osload3
 mov al,cs:0[filenamebuffer]
 sub al,'A'-1
 mov cs:fcbdrive,al
osload3:
 call checkdisk
 jc osload1 ;Disk missing (non-fatal)

 mov es,cs:MenuPgame ;Gamedata & workspace segment
 mov cx,workspacesize
 mov dx,offset filenamebuffer
 mov si,0 ;Load address
 call LoadUpFile
 cmp al,0
 jz osload5
 cmp al,1
 jnz osload4

;File nof found...

 mov si,offset filenamebuffer
 mov cx,inputbuffersize-4
osload3b:
 cmp byte ptr cs:[si],0
 jz osload3a
 inc si
 loop osload3b
 jmp short osload1 ;File not found (non-fatal)

osload3a:
 mov byte ptr cs:0[si],'.'
 mov byte ptr cs:1[si],'A'
 mov byte ptr cs:2[si],'D'
 mov byte ptr cs:3[si],'V'

 mov es,cs:MenuPgame ;Gamedata & workspace segment
 mov cx,workspacesize
 mov dx,offset filenamebuffer
 mov si,0 ;Load address
 call LoadUpFile
 cmp al,0
 jz osload5
 cmp al,1
 jnz osload4

;File not found...

osload3dc:
 mov di,offset notfound
 call prs
 jmp osload1 ;File not found (non-fatal)

;Read error....

osload4:
 mov di,offset readerror
 call prs
 jmp osload1

;Got a file loaded, so check its length. I can check if the file
;was shorter than expected, but not if it is longer (the ACODE
;has to resolve this)

osload5:
 cmp cx,workspacesize
 jnz osload4 ;Not correct length, so give read error
 ret

;-----

readerror:
 db "Read error."
 db 13,0

notfound:
 db "Saved position not found."
newline:
 db 13,0

;-----

ldir:
 cmp cx,0
 jz ldirend
 mov al,ds:0[si]
 mov ds:0[di],al
 inc di
 inc si
 dec cx
 jmp short ldir
ldirend:
 ret

;-----

lenscalibrate:
 call getcharacter
 cmp al," "
 jne lenscalibrate
 ret

;-----

lensdisplay:
 mov al,'['
 call graphicdisplayall
 mov al,ds:0[si]
 call graphicdisplayall
 mov al,ds:1[si]
 call graphicdisplayall
 mov al,']'
 jmp graphicdisplayall

;-----

trydisk:
 mov al,ds:[fcbdrive]
 cmp al,0
 jnz driveset
 mov ah,19h ;Report current drive
 int 21h ;Dos service
 inc al
driveset:
 dec al
 push ax ;Save drive number

 cmp al,2 ;Only check A: (drive 0) and B: (drive 1)
 jnc diskok

 mov dl,al ;Drive number
 mov dh,0 ;Side
 mov cx,0101h ;Track, Sector
 push es
 mov ax,cs
 mov es,ax
 mov ax,0201h ;Read diskette sectore, number of sectors
 mov bx,offset diskbuffer ;Dummy 512 bytes
 int 13h ;Diskette Service
 pop es
;'C' set if error
 jnc diskok

 mov ah,0 ;Reset diskette System
 int 13h ;Diskette Service

 pop ax ;Restore drive number
 push ax

 mov dl,al ;Drive number
 mov dh,0 ;Side
 mov cx,0101h ;Track, Sector
 push es
 mov ax,cs
 mov es,ax
 mov ax,0201h ;Read diskette sectore, number of sectors
 mov bx,offset diskbuffer ;Dummy 512 bytes
 int 13h ;Diskette Service
 pop es
;'C' set if error
 jnc diskok
 test ah,080h ;Ignore all but timeout errors
 clc ;Clear carry
 jz diskok
 stc ;Set carry

diskok:
 pop ax
 ret

;-----

complename:
 db "GAMEDAT1.DAT",0

chain:
 mov al,0[si]
 add al,'0'
 mov byte ptr 7[complename],al

chain1:
 mov ds:fcbdrive,0 ;Default drive
 call checkdisk
 jc short chain3 ;Disk missing

 mov es,cs:MenuPGame
 mov cx,65535-gamedata ;Max length
 mov si,gamedata ;Start address
 mov dx,offset complename
 call LoadUpFile
 cmp al,0
 jz chain2

 mov di,offset chainnotfound ;File not found
 call prs
 jmp short chain3

chain2:
;If I read the entire file this always gives an EOF error, so
;get the first sector to establish the file is correct, then load
;it. The Checksum code will spot loading errors.

 mov ds:[pagingonoff],1
 call ClearTitle

 jmp aintrestart

oserror:
 mov ds:[pagingonoff],0
 push si
 mov di,offset fataloserror
 call prs

chain3:
 mov ds:[pagingonoff],0
 push si
 mov di,offset chainpressspace
 call prs
chain4:
 call getcharacter
 cmp al," "
 jnz short chain4
 mov di,offset chainnewline
 call prs
 pop si
 jmp short chain1

chainnotfound:
 db asciicr
 db "Game not found."
chainnewline:
 db asciicr,0

fataloserror:
 db asciicr
 db "EOF error."
 db asciicr,0

chainpressspace:
 db asciicr
 db "Insert game disk then press space: "
 db 0

;-----

prs:
 push si
prs1:
 mov al,cs:[di]
 cmp al,0
 jz short prs2
 call entrydisplayall
 inc di
 jmp short prs1
prs2:
 pop si
 ret

;-----

code ends

 end





