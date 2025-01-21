;IBM KAOS DRIVER

;GRAPHIC.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

 name graphic

 public backgroundcolour
 public Clearbottomhalf
 public cursorenable
 public cursortype
 public graphicdisplayall
 public redisplaytextbottomhalf
 public savedpictureheight
 public settextmode
 public scrolledlines

;In EDSQU.ASM
 extrn displaybackspace:near
 extrn pagefull:near
 extrn updatekeyboardbuffer:near

;In CGA.ASM:
 extrn cgaforceoff:near

;In DRIVER.ASM:
 extrn pagingoff:near
 extrn pagingonoff:byte
 extrn pagingset:near

;In ENTRY.ASM:
 extrn characterwidth:byte
 extrn screenmode:byte

;In HIRES.ASM:
 extrn picturelines:near

;-----

;           Either   Signed   Unsigned
;    <=              jle      jbe
;    <               jl       jb/jc
;    =      je/jz
;    <>     jnz/jne
;    >=              jge      jae/jnc
;    >               jg       ja

;-----

code SEGMENT public 'code'
 ASSUME cs:code,ds:code

;These include files must be named in MAKE.TXT:
 include head.asm

cursorenable db 0

savedpictureheight dw 0 ;Pixel height of Pegabuffer during WORDS.

scrolledlines db 0

backgroundcolour db 0

;-----

SETTEXTMODE:
 mov al,cs:[MenuFgraphicPossible]
 cmp al,0
 jz alwaystext
 call redisplaytexttophalf
alwaystext:
 mov byte ptr cs:[MenuFpicturetype],0
 ret

;-----

;Redraw text line dh

redisplaytextline:
 mov es,cs:[MenuPtextmap]
 push dx
 mov si,0 ;Offset into textmap
 mov bh,0
 mov bl,ds:[characterwidth]
rd01:
 cmp dh,0
 jz rd02
 add si,bx
 dec dh
 jmp short rd01
rd02:

 mov bh,0 ;Display page
 mov ah,3 ;Read cursor position
 INT 10h
 pop cx ;Row to redisplay
 push dx ;Current row and column

 mov dx,cx
 mov dl,0 ;Column
rd03:
 cmp si,cs:[MenuLtextmap] ;Beyond end of textmap
 jnc rd04
 push dx ;Row and column
 mov ah,2 ;Set cursor position
 mov bh,0 ;Page number
 int 10h
 mov bh,0 ;(Page number)
 mov bl,textcolour ;Logical colour for white in pictures
 mov al,es:[si] ;Character
 mov cx,1 ;Count
 mov ah,10 ;Write Character
 INT 10h ;Video Service
 pop dx ;Row and column
 inc dl
 inc si
 cmp dl,ds:[characterwidth]
 jc rd03 ;Reached right-hand column
rd04:

 pop dx ;Original cursor row and column
 mov bh,0 ;Page number
 mov ah,2 ;Set cursor position
 int 10h
 ret

;-----

redisplaytexttophalf:
 call picturelines
 mov dh,al
rt01:
 cmp dh,0
 jz rt02
 dec dh
 push dx
 call redisplaytextline
 pop dx
 jmp short rt01
rt02:
 ret

;-----

;dl=bottom row

redisplaytextbottomhalf:
 push dx
 call picturelines
 pop dx
 mov dh,al
rb01:
 cmp dh,dl
 ja rb02
 inc dh
 push dx
 call redisplaytextline
 pop dx
 jmp short rb01
rb02:
 ret

;-----

;dl=bottom row

Clearbottomhalf:
 push dx
 call picturelines
 pop dx
 mov dh,dl
rb03:
 cmp dh,al
 jbe rb04
 dec dh
 push ax
 push dx
 call redisplaytextline
 pop dx
 pop ax
 jmp short rb03
rb04:
 ret

;-----

cleartextandmap:
 call cleartextmap
notmode7cls:
 mov al,ds:[screenmode]
 cmp al,6 ;MGA mode
 jz cls0
 cmp al,16 ;Ega mode ?
 jnc cls0
 jmp short dontclear

cls0:
 call picturelines
 cmp al,24 ;(EGA mode) Loading screen means no text space available
 jnc dontclear
 mov ch,al ;Row number of top text line
 mov ah,6 ;Service 6 - Scroll Window Up
 mov al,0 ;Blank window (no scrolling)
 mov cl,0 ;Top left column number
 mov dh,24 ;Bottom right row number
 mov dl,ds:[characterwidth] ;Bottom right column number
 dec dl
 mov bh,ds:[backgroundcolour] ;Screen page (text mode only)
 int 10h ;ROM-BIOS Video Service
dontclear:

 mov ah,2  ;Service 2 - Set Cursor Position
 mov dl,0  ;Column
 mov dh,24 ;Row in WORDS mode
 mov bh,0  ;Display page
 int 10h   ;ROM-BIOS video service
 RET

;-----

graphicdisplayall:
 CMP AL,23h
 jnz displaychar
 mov al,60h

displaychar:
 push bx
 push dx
 push cx
 push si
 call dc01
 call updatekeyboardbuffer
 pop si
 pop cx
 pop dx
 pop bx
 ret

dc01:
 CMP AL,14 ;Paging on
 jnz dc02
 jmp pagingset
dc02:
 CMP AL,15 ;Paging off
 jnz dc03
 jmp pagingoff

dc03:
 call cgaforceoff ;Turn off CGA colour screen (precaution)

; cmp al,asciicls
; jnz dc04
; jmp cleartextandmap
;dc04:
 cmp al,asciibs
 jnz dc05

 call displaybackspace
 mov al,space
 call graphicdisplayall2
 jmp displaybackspace

dc05:
;If CR then may want to wait for input if screen if full
 cmp al,asciicr
 jz displaynewline
 jmp graphicdisplayall2

;-----

displaynewline:
 call graphicdisplayall2

 cmp ds:[pagingonoff],0
 jz dontwaitforshift

 inc ds:[scrolledlines]

 call picturelines
; cmp al,22 ;(EGA mode)
; jnc dw02 ;When loading screen displayed fudge page-size
 mov ah,22
 sub ah,al
 cmp ah,ds:[scrolledlines]
 jc dw01
dontwaitforshift:
 ret
dw01:

 call pagefull
dw02:
 ret

;-----

;For modes 0 thru 3

textDISPLAYALL:
 cmp al,asciicr
 jnz textnotcr

 mov ah,03 ;Service 3 - Read Cursor Position
 mov bh,0 ;Page number (text mode only)
 int 10h ;ROM-BIOS video service
 cmp dh,24
 jnz nottoscrollmap
 call scrolltextmap
nottoscrollmap:
 mov al,asciicr
 call td01
 mov al,asciilf
 jmp short td01

textnotcr:
 push ax ;Save character
 MOV AH,9 ;Service 9 (Write character and Attribute)
 mov bl,charactercolour ;Attribute (non blinking yellow)
 mov bh,0 ;Display page
 mov cx,1 ;repeat count
 INT 10H ;ROM-BIOS video service
 pop ax

td01:
 jmp notscroll ;Update the cursor position/scroll the real screen

;-----

checkcorner:
 push ax
 push bx
 push cx
 push dx

 mov ah,03 ;Service 3 - Read Cursor Position
 mov bh,0 ;Page number (text mode only)
 int 10h ;ROM-BIOS video service
 cmp dh,24
 jnz notatbottom
 mov al,ds:[characterwidth]
 inc dl
 inc dl
 inc dl
 cmp al,dl
 jnz notatbottom

;Can use DOS to move cursor down to next line
 call scrolltextmap
 call picturelines
 mov ch,al ;Row number of top text line
 mov ah,6 ;Service 6 - Scroll Window up
 mov al,1  ;Move by one line
 mov cl,0  ;Top left column number
 mov dh,24 ;Bottom right row number
 mov dl,ds:[characterwidth] ;bottom right column number
 dec dl
 mov bh,ds:[backgroundcolour] ;clear to background
 int 10h ;ROM-BIOS video service
;Now reset cursor to left column
 mov ah,03 ;Service 3 - Read Cursor Position
 mov bh,0 ;Page number (text mode only)
 int 10h ;ROM-BIOS video service
 dec dh ;Cursor up
 mov bh,0 ;Screen page number (text mode only)
 mov ah,2 ;Service 2 - Set Cursor Position
 int 10h ;ROM-BIOS video service

notatbottom:
 pop dx
 pop cx
 pop bx
 pop ax
 ret

;-----

cleartextmap:
 mov es,cs:[MenuPtextmap]
 mov di,cs:[MenuLtextmap]
ct01:
 cmp di,0
 jz ct02
 dec di
 mov byte ptr es:0[di],' '
 jmp short ct01
ct02:
 ret

;-----

scrolltextmap:
 push di
 mov es,cs:[MenuPtextmap]
 mov ah,0
 mov al,ds:[characterwidth]
 mov si,ax
 mov di,0
 mov cx,cs:[MenuLtextmap]
st01:
 cmp cx,0 ;Scrolled entire buffer
 jz st04
 cmp si,cs:[MenuLtextmap] ;Last line to be clear to all spaces
 jc st02
 mov al,' '
 jmp short st03
st02:
 mov al,es:[si]
st03:
 mov es:[di],al
 inc si
 inc di
 dec cx
 jmp short st01
st04:
 pop di
justreturn:
 ret

;-----

;Only CGA and EGA modes....

graphicdisplayall2:
 cmp al,asciicls
 jnz dn00a
 call cleartextmap
 jmp notmode7cls

dn00a:

;Only CGA and EGA modes...
cgadisplayall:
 call checkcorner
 cmp al,asciibs
 jnz displaynotbackspace
 jmp displaybackspace

displaynotbackspace:
 mov ah,ds:[screenmode]
 cmp ah,4
 jnc dn01
 jmp textdisplayall ;Modes 0 thru 3 are text
dn01:
; cmp ah,7
; jnz dn02
; jmp monodisplayall
;dn02:
 cmp al,asciicr
 jz moveonly
 cmp al,asciilf
 jz justreturn
 cmp al,asciicls
 jz moveonly

 push ax ;Save AL=Character
 MOV AH,09 ;Service 9 (Write character and Attribute)
 mov bl,textcolour ;Character attribute
 MOV BH,0  ;Page number (only essential in monochrome)
 MOV CX,1  ;Number of characters
 INT 10H ;ROM-BIOS video service
 pop ax ;Restore AL=character
moveonly:

 cmp al,asciicr
 jnz notscroll
 mov al,ds:[screenmode]
 cmp al,4
 jc notscroll
 cmp al,7
 jz notscroll

;Can use DOS to move cursor down to next line
 call scrolltextmap

 call picturelines
;al=Top line of scroll area
 mov ch,al ;Row number of top text line
 mov ah,6 ;Service 6 - Scroll Window up
 mov al,1  ;Move by one line
 mov cl,0  ;Top left column number
 mov dh,24 ;Bottom right row number
 mov dl,ds:[characterwidth] ;bottom right column number
 dec dl
 mov bh,ds:[backgroundcolour] ;clear to background
 int 10h ;ROM-BIOS video service
;Now reset cursor to left column
 mov ah,03 ;Service 3 - Read Cursor Position
 mov bh,0 ;Page number
 int 10h ;ROM-BIOS video service
 mov dl,0 ;Cursor column to start of line
 mov bh,0 ;Screen page number (text mode only)
 mov ah,2 ;Service 2 - Set Cursor Position
 int 10h ;ROM-BIOS video service
 ret

notscroll:
 push si
 push di
 push ax
 push bx
 push cx
 push dx

 mov es,cs:[MenuPtextmap]
 push ax
 mov ah,3 ;Read Cursor Position
 mov bh,0 ;Display page
 int 10h
 mov di,0
 mov ch,0
 mov cl,ds:[characterwidth]
cp01:
 cmp dh,0 ;Row
 jz cp02
 add di,cx
 dec dh
 jmp short cp01
cp02:
 mov dh,0
 add di,dx
 pop ax
 cmp di,cs:[MenuLtextmap]
 jnc cp03
 cmp al,' '
 jc cp03
 mov es:[di],al

cp03:
 pop dx
 pop cx
 pop bx
 pop ax
 pop di
 pop si

 mov bl,textcolour ;Colour white, set by loading picture
 mov ah,0Eh ;Service 14 (Write character as tty)
 mov bh,0 ;Display page
 int 10h ;ROM-BIOS video service
 ret

;-----

;All output in (and only in) mode 7.
;Allow control chars are CR and BS.

;displaymode7:
 cmp al,asciicls
 jz mode7cls
 push ax
 mov bl,mode7colour ;Colour white
 mov ah,0Eh ;Service 14 (Write character as tty)
 mov bh,0 ;Display page
 int 10h ;ROM-BIOS video service
 pop ax
 cmp al,asciicr
 mov al,asciilf
; jz displaymode7
 ret

;Mode 7 - Initialise and clear text

mode7cls:
 mov cx,50 ;Scroll off screen
mc01:
 push cx
 mov al,asciilf
 mov ah,mode7colour ;Service 14 (Write character as TTY)
 mov bh,0 ;Display page
 int 10h ;ROM-BIOS video service
 pop cx
 dec cx
 cmp cx,0
 jnz mc01

 mov al,7
 mov ah,0 ;Video service 0, Set Video Mode
 int 10h ;ROM-BIOS Video Service

 ret

;-----

cursortype:
 cmp ds:[cursorenable],0
 jz hardwarecursor
 mov al,ds:[screenmode]
 cmp al,4
 jc hardwarecursor
 cmp al,7
 jnz owncursor
hardwarecursor:
 mov al,0 ;Display mode has own cursor
 ret
owncursor:
 mov al,0FFh ;Display modes needs underline as cursor
 ret

;-----

code ENDS

 END




