;IBM KAOS adventure system. memory allocator/loader

;MENU.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

 name run

 public LoadUpFile
 public ModuleName

;In ENTRY.ASM:
 extrn entrydisplayall:near
 extrn driver:near

;In DCACHE.ASM:
 extrn clearcache:near

;In IDENTIFY.ASM:
 extrn VideoId:near
 extrn Video0Type:byte
 extrn Display0Type:byte
 extrn Video1Type:byte
 extrn Display1Type:byte

;In AINT.ASM:
 extrn aint:near

;-----

code segment public 'code'
 assume cs:code,ds:code

;These include files must be named in MAKE.TXT:
 include head.asm

;-----

exeheader=512 ;Header added to EXE files by LINK
maxcache = 65280
recallsize = 1024
demosize=2048

;Ascii/BBC control codes:
asciibs = 08h
asciitab= 09h
asciilf = 0Ah
asciicr = 0Dh
asciiesc= 1Bh

;Lines in MENU.TXT:
dollarcomment  = '1'
dollareof      = '2'
dollarmenu     = '4'
dollarforward  = '5'
dollarsuggmode = '8'
dollarsecond   = '9'
dollardot      = '.'

;-----

aintrestart:
csoffsetzero:
 jmp start

paramaterarea:
 db (MenuHeaderLength-(paramaterarea-csoffsetzero)) dup (0)

;-----

fcbextension db 7 dup(0) ;Extended area
fcbdrive = this byte
sysfcb  db 1  dup(0)
fcbname db 8  dup(' ') ;name
        db 3  dup(' ') ;type
fcbex   db 20 dup(0)
fcbcr   db 4  dup(0)

;-----

;Conditions on entry/startup:
demoenable         db 0 ;Enable keyboard
ModuleName         db 1 ;Module name. 0=AINT, 1=MENU. Select 1.5 times expansion
savedpictureheight dw 0 ;Indicate start in WORDS.

;Options set by menu:
autorun     db 0 ;non-zero if !R
backgroundcolour db 0 ;Colour for attributes
driverseed  dw 0 ;random value
graphics    db 0 ;non-zero if a graphics mode selected
illegalmode db 0 ;non-zero if a non-portable mode selected
titlenumber db 0 ;Picture number of title screen
asciimode   db 0 ;Screen mode selected (or space)
screenmode  db 0 ;MS-DOS mode selected

;Parameter build area for AINT.EXE code segment
aheadPtextmap        dw 0
aheadLtextmap        dw 0
aheadPgame           dw 0
aheadPrecall         dw 0
aheadLrecall         dw 0
aheadPoops           dw 0
aheadLoops           dw 0
aheadPcache          dw 0
aheadLcache          dw 0
aheadPgraphicsbuffer dw 0
aheadLgraphicsbuffer dw 0
aheadPautorun        dw 0
aheadLautorun        dw 0

;Memory management:
allocatebase      dw 0
allocatelength    dw 0
allocateparagraph dw 0
allocatesize      dw 0

;Segment paragraph to load AINT.EXE:
codeparagraph dw 0

gamesize dw 0 ;Size of largest GAMEDAT?.DAT

;Disk DMA buffer
diskbuffer db 128 dup(0) ;Disk I/O buffer

hiresbuffer db 7 dup (0)

startupmode  db 0
startupchars db 0
pagenumber db 0

;Info derived from PALETTE.PIC:

DefaultPalette db 0  ;Black
               db 99 ;1
               db 99 ;2
               db 99 ;3
               db 99 ;4
               db 99 ;5
               db 99 ;6
               db 7  ;white
               db 99 ;8
               db 99 ;9
               db 99 ;10
               db 99 ;11
               db 99 ;12
               db 99 ;13
               db 99 ;14
               db 99 ;15

DefaultLogical dw 0 ;Logical colour 'map'

DefaultBorder db 1 ;Pictures which set border colours
 db 2,3,4,5,6,7,8,9,10
 db 11,12,13,14,15,16,17,18,19,20
 db 21,22,23,24,25,26,27,28,29,30

;-----

start:
 push cs
 pop ds

 mov bx,0FFFFh ;Request 0FFFF0h bytes of memory
 mov ah,048h ;Allocate memory
 int 21h ;Universal DOS function
 cmp ax,8 ;Check that DOS has refused to allocate
 jnz allocationerror

;bx is now the actual number of free memory paragraphs

 mov ds:[allocatesize],bx
 mov ah,048h ;Allocate memory
 int 21h ;Universal DOS function
 cmp ax,8 ;Check for DOS errors
 jz allocationerror
 cmp ax,7
 jnz allocatedall

allocationerror:
 mov di,offset memoryerror
 call directprs

 jmp terminate

memoryerror:
 db "Insufficient memory"
 db asciicr,10,0

allocatedall:
 mov ds:[allocatebase],ax

 mov ah,0Fh ;Get current Video Mode
 int 10h ;ROM-BIOS Video Service
 mov ds:[startupmode],al
 mov ds:[startupchars],ah ;^^

restart:
 mov ax,ds:[allocatebase]
 mov ds:[allocateparagraph],ax
 mov bx,ds:[allocatesize]
 mov ds:[allocatelength],bx

;Tempararily allocate the unused memory as a picture cache
;for the driver to load the title picture. Once the game
;is loaded CS is changed to the start of AINT so this
;allocation is forgotten.

 cmp bx,Mode16Screen/16 ;Enough space?
 jb st02
 mov cs:[MenuPgraphicsBuffer],ax
 mov cx,Mode16Screen
 mov cs:[MenuLgraphicsBuffer],cx

 add ax,Mode16Screen/16 ;Skip EGA buffer
 sub bx,Mode16Screen/16
st02:

 mov cs:[MenuPcache],ax
 cmp bx,maxcache/16 ;Maximum paragraphs cache can hold
 ja st03
 add bx,bx ;Convert paragraphs to bytes
 add bx,bx
 add bx,bx
 add bx,bx
 jmp short st04
st03:
 mov bx,maxcache
st04:
 mov cs:[MenuLcache],bx

 mov word ptr cs:[MenuLrecall],0 ;Flag as no recall buffer
 mov word ptr cs:[MenuLtextmap],0 ;Flag as no TEXTMAP
 mov byte ptr cs:[MenuFgraphicPossible],0 ;Default to text-only

 mov dx,offset diskbuffer
 mov ah,01Ah ;Set Disk Transfer Area
 int 21h ;ROM-BIOS DOS Functions

 call VideoId

 call selectmode

;Some versions of MS-DOS (but not IBMs) ignore screen-mode changes if
;the machine is impossible to upgrade to the hardware necessary

 mov al,ds:[asciimode]
 cmp al,' '
 jnz setupnewmode
 jmp modeok

setupnewmode:
 mov ah,0 ;Video Service - Set Video Mode
 mov al,ds:[screenmode]
 int 10h ;ROM-BIOS Video Service
 mov ah,0Fh ;Get current Video Mode
 int 10h ;ROM-BIOS Video Service
 cmp al,ds:[screenmode]
 jnz st05 ;OS is not in mode requested by user
 jmp modeok

st05:
 mov di,offset wrongmode ;Ask for ESC or CR.
 call directprs

st06:
 call directosrdch
 cmp al,asciicr
 jnz st07
 jmp modeok ;Pressing CR assumes user is right, OS is wrong.
st07:
 cmp al,asciiesc
 jnz st06
 jmp restart ;Pressing ESC assumes user is wrong, OS is right.

;-----

;    1234567890123456789012345678901234567890
wrongmode:
 db asciicr,asciilf
 db asciicr,asciilf
 db "I don't think that format will work."
 db asciicr,asciilf
 db "Press RETURN to try it anyway or press"
 db asciicr,asciilf
 db "ESC to select a different format: "
 db 0

;-----

selectmode:
;Find size of largest gamedata file

 mov word ptr ds:[gamesize],0
 mov al,'1'
sm01:
 push ax
 call setfcbgame
 pop ax
 mov byte ptr ds:7[fcbname],al
 push ax

 mov al,1 ;Load first sector
 call loadstart ;Get first sector of GAMEDATA
 cmp al,0
 jnz sm02 ;gamedata file missing
 mov ax,word ptr ds:[diskbuffer]
 cmp ax,ds:[gamesize]
 jc sm02 ;this gamedata file smaller than others
 mov ds:[gamesize],ax
sm02:

 pop ax
 add al,1
 cmp al,'9'+1 ;Scanned all GAMEDATA files?
 jc sm01

;Load configuration file PALETTE.PIC

 mov es,ds:[allocatebase]
 mov cx,2*1024 ;Max length
 mov dx,offset palettefilename
 mov si,0 ;load address
 call LoadUpFile

 cmp al,2
 jz paletteloaded
 cmp al,0
 jnz paletteloaded

 cmp cx,0 ;If zero-length then mis-loaded.
 jz paletteloaded

 mov si,0 ;Skip first line of PALETTE.PIC, which contains copyright
 call skipeoln
 inc si ;Skip line feed

 mov cx,16 ;Read the second line which contains a 16-bit binary value
sm03:
 lods byte ptr es:[si] ;mov al,es:[si]:inc si
 sub al,'0'
 rcr al,1 ;Rotate bit-info into carry
 rcl bx,1 ;Store bit
 loop sm03
 mov cs:DefaultLogical,bx

 call skipeoln

 mov di,offset DefaultBorder
 mov cx,30 ;Number of pictures in MenuFborder list
sm04:
 mov byte ptr cs:[di],0
 inc di
 loop sm04

 mov di,offset DefaultBorder ;Read third line, picture files which set border
sm05:
 cmp byte ptr es:[si+1],' '
 jz sm06 
 call parsesmalldecimal
 inc si ;skip last digit of number
 mov cs:[di],al ;Save picture number
 inc di
 jmp short sm05

sm06:
 call skipeoln

 mov cx,16 ;Read fourth line, palette info
 mov di,offset DefaultPalette
sm07:
 push cx
 call parsesmalldecimal
 mov ds:[di],al
 pop cx
 inc si
 inc di
 dec cx
 cmp cx,0
 jnz sm07

 jmp short paletteloaded

skipeoln:
 lods byte ptr es:[si] ;mov al,es:[si]:inc si
 cmp al,asciicr
 jnz skipeoln
 ret

;Load configuration file MENU.TXT

paletteloaded:
 mov es,ds:[allocatebase]

 mov cx,0FFFFh ;Max length
 mov dx,offset menufilename
 mov si,0 ;Load address
 call LoadUpFile

 cmp al,2
 jz sm09
 cmp al,0
 jnz sm08

 cmp cx,0 ;Zero-length file is also error
 jz sm09
 jmp short menuloaded

sm08:
 mov di,offset cantopenmenu
 call directprs
 jmp terminate

cantopenmenu:
 db asciicr,asciilf
 db "MENU.TXT missing."
 db asciicr,asciilf
 db 0

sm09:
 mov di,offset menuerror
 call directprs
 jmp terminate

menuerror:
 db asciicr,asciilf
 db "can't read MENU.TXT."
 db asciicr,asciilf
 db 0

menuloaded:
;Now checked code file, checked gamedata files and checked menu/config file
 mov ah,0 ;Video Service - Set Video Mode
 mov al,ds:[startupmode]
 int 10h ;ROM-BIOS Video Service

 mov si,0
 mov al,dollareof ;Check file has a terminator.
 call dollarsearch
 cmp al,0
 jnz menuok

 mov di,offset menumissingerror
 call directprs
 jmp terminate

menuok:
 call findsuggestmode
onlyonepage:
 mov al,dollarmenu ;Find next menu string
 sub ah,ah
 mov ds:pagenumber,ah   ;clear page number

askfornewmode:
 call displayfrommenu

 mov al,0FFh
 mov ds:[screenmode],al
 mov ds:[illegalmode],0

 cmp ds:[autorun],0
 jz askagain
 jmp short autoagain

askagain:
 call directosrdch
 cmp al,19 ;Alt-R
 jnz notautorun

;In AUTO-DEMO mode commands are read from DEMO.TXT into memory, since
;all memory allocation is done before the title screen/code/gamedata is
;loaded this feature has to be enabled here if this feature required.

 mov ds:[autorun],1
autoagain:
 mov al,asciimode ;Redisplay line with extra message
 call directoutput
 mov di,offset autorunselected
 call directprs
 jmp short askagain

;    123456789
autorunselected:
 db " !R" ;Only room for ABOUT 3 chars on 40-column machines
 db 4 dup (asciibs)
 db 0

notautorun:
 cmp al,' ' ;Use mode set already set up by MODE command.
 jz sm10
 cmp al,asciitab
 jz sm11
 cmp al,asciicr
 jz sm12
 and al,0DFh
 call searchformode
 jnz short askagain

sm10:
 mov ds:[asciimode],al
 call directoutput
 mov al,asciibs
 call directoutput

 jmp short askagain

sm11:
;;;;;
 mov si,0
 mov al,dollarsecond ;Page 2 of displayed menu
 call dollarsearch
 cmp al,0
 jz askagain ;* onlyonepage
;;;;;

 mov al,asciicls
 call graphicdisplayall

 mov al,ds:pagenumber
 xor al,0FFh
 mov ds:pagenumber,al
 jz setpage2

 mov al,dollarsecond
 jmp short askfornewmode

setpage2:
 mov al,dollarmenu
 jmp short askfornewmode

sm12:
 mov al,ds:[asciimode]
 cmp al,' ' ;Use mode set up by previous MODE command
 jz sm13
 call searchformode
 jnz askagain

;MS-DOS screen mode number:
 inc si
 call parsesmalldecimal
 mov ds:[screenmode],al

;0 - Graphics not allowed
;1 - Normal pictures allowed
;2 - Normal and Title pictures allowed
 inc si
 inc si ;Skip second space
 mov al,es:[si]
 sub al,'0'
 mov ds:[graphics],al
 mov cs:[MenuFgraphicPossible],al
 mov cs:[MenuFpicturetype],al

;0 =                  ;All modes legal
;1 = ega_not_so       ;EGA not-so-fast & MGA fast
;2 = ega_okish        ;EGA normal
;3 = ega_ultra        ;EGA fast
;4 = cga_low_res      ;CGA low-res
;5 = ega_cga_low_res  ;EGA low-res 40
;6 = ega_full_low_res ;EGA low-res 80
 inc si
 inc si ;Skip third space
 mov al,es:[si]
 sub al,'0'
 mov ds:[illegalmode],al
 mov cs:[MenuFsubmode],al

;Loading/Title picture number
 inc si
 call parsesmalldecimal
 mov ds:[titlenumber],al

sm13:
 mov di,offset newline
 jmp directprs

;-----

;scans through the file to find suggested mode for present display

findsuggestmode:

 mov si,0
findsuggested:
 mov al,dollarsuggmode ;Find mode equivalent to current hardware
 call dollarsearch
 cmp al,0
 jnz foundsuggdollar

 mov ds:[asciimode],020h ;No suggestions in menu!
 ret

foundsuggdollar:
 inc si

 lods word ptr es:[si] ;check if correct board found
 sub al,030h
 cmp al,ds:Video0type
 jnz findsuggested

 lods word ptr es:[si] ;check for specific / non-specific monitor
 sub al,030h
 jz notspecialmonitor

 cmp al,ds:Display0type
 jnz findsuggested

notspecialmonitor:

 lods word ptr es:[si] ;check for specifically forty column mode
 sub al,030h
 jz notfortymode

 mov al,40
 cmp al,ds:StartupChars
 jnz findsuggested

notfortymode:
 mov al,es:[si]         ;get suggested ascii screen mode
 mov ds:[asciimode],al
 call searchformode
 ret

;-----

board1:
 db "1st Board = "
 db 0

display1:
 db " 1st Display = "
 db 0

board2:
 db 13,10
 db "2nd Board = "
 db 0

display2:
 db " 2nd Display = "
 db 0

;-----

;Display all lines from MENU.TXT which start '$X' (X=al)

displayfrommenu:

 push ax
 mov si,0
 mov al,dollardot
 call dollarsearch
 cmp al,0
 jz nodollardot ;If "$." sequence is in MENU.TXT then display board types

 mov di,offset board1
 call directprs
 mov al,ds:video0type
 add al,030h
 call directoutput
 mov di,offset display1
 call directprs
 mov al,ds:display0type
 add al,030h
 call directoutput
 mov di,offset board2
 call directprs
 mov al,ds:video1type
 add al,030h
 call directoutput
 mov di,offset display2
 call directprs
 mov al,ds:display1type
 add al,030h
 call directoutput

nodollardot:
 pop ax

 mov si,0
df01:
 push ax
 call dollarsearch
 cmp al,0
 jz df04
 push si
 mov di,offset newline
 call directprs
 pop si
df02:
 inc si
 mov al,es:[si]
 cmp al,asciicr
 jz df03
 call directoutput
 jmp short df02
df03:
 pop ax
 jmp short df01
df04:
 mov al,ds:[asciimode]
 call directoutput
 mov al,asciibs
 call directoutput
 pop ax
 ret

;-----

modeok:
;Allocate memory. Provided there is enough space for all code, gamedata,
;and copy of screens, space is allocated equally between the picture 
;cache and oops buffers. If oops falls below 15K then priority is
;given to the picture cache (the user can always select a non-graphic
;mode to get more memory for the other features.)

 mov bx,63*64 ;Picture cache 63K
mo01:
 push bx
 mov ax,bx
 call tryallocate
 pop bx
 jnc goodallocation
 dec bx ;Ran out of memory, so reduce size of cache and oops.
 cmp bx,15 ;Below 15K give priority to pictures
 jnc mo01

mo02:
 push bx
 mov ax,bx
 mov bx,0 ;(no oops)
 call tryallocate
 pop bx
 jnc goodallocation
 dec bx
 cmp bx,0FFFFh
 jnz mo02
 jmp outofmemory

goodallocation:

;Got a valid screen mode and enough memory to run game, so
;get driver running, display a message temporarily while
;title screen loads then use driver to load title picture.

 mov al,15 ;Initialise
 call driver
 mov al,7 ;Set text mode
 call driver

 call resetwhite

;Remind user of the screen mode selected. If no mode was entered then
;display the mode (0..19) that the OS is still using.

 cmp ds:[asciimode],' '
 jz defaultmode

 mov ah,2 ;Service 2 - Set Cursor Position
 mov bh,0
 mov dl,0 ;Column
 mov dh,0 ;Row in WORDS mode
 int 10h  ;ROM-BIOS video service

 mov di,offset confirm_wait
 call directprs
 mov al,ds:[asciimode]
 call directoutput
 jmp short displaywait

defaultmode:
 mov di,offset default
 call directprs
 mov ah,0Fh ;Get Current Video Mode
 int 10h
 mov ds:[screenmode],al
 mov ah,0
 call displaysmalldecimal

displaywait:
 mov di,offset newline
 call directprs
 call clearcache

 mov al,cs:[MenuFgraphicPossible]
 mov cs:[MenuFpicturetype],al
;0 Text mode
;1 Pictures, no title
;2 Pictures, with title
 cmp al,2
 jnz noloadingpic

;Copy current palette into to current cs:MenuFpalette for border picture
 mov si,offset DefaultPalette
 mov di,offset MenuFpalette
 mov cx,16
titlepalette:
 mov al,[si]
 mov cs:[di],al
 inc si
 inc di
 dec cx
 cmp cx,0
 jnz titlepalette

 push es ;Clear display area for loading pictures (currently contains MENU)
 mov cx,cs:[MenuLgraphicsBuffer]
 mov es,cs:[MenuPgraphicsBuffer]
 mov di,0
ce01:
 jcxz ce02
 mov byte ptr es:[di],0
 inc di
 dec cx
 jmp short ce01

ce02:
 pop es

 mov al,ds:[titlenumber]
 mov si,offset hiresbuffer
 mov byte ptr 0[si],0  ;Picture number (Hi)
 mov byte ptr 1[si],al ;Picture number (Lo)
 mov byte ptr 2[si],0  ;X (Hi)
 mov byte ptr 3[si],0  ;X (Lo)
 mov byte ptr 4[si],0  ;Y (Hi)
 mov byte ptr 5[si],0  ;Y (Lo)

 mov cs:ModuleName,1 ;Set to draw title screen

 mov al,32 ;Draw loading picture
 call driver
 cmp byte ptr 0[si],0 ;Get return code
 jz titleok
 mov byte ptr cs:[MenuFpicturetype],1

noloadingpic:
 call resetwhite ;Set up dummy colours for white text
 jmp short notitle
titleok:
 mov byte ptr cs:[MenuFpicturetype],2 ;Reset it back again
notitle:

 mov cs:ModuleName,0 ;Set to draw normal pictures

 mov dx,offset diskbuffer
 mov ah,01Ah ;Set Disk Transfer Area
 int 21h ;ROM-BIOS DOS Functions

;If auto-demo has been enabled by now load up file into it's segment

 cmp ds:[autorun],0
 jnz lm01
 jmp retrycode

lm01:
 push es
 mov es,ds:[aheadPautorun]

 mov cx,demosize ;number of bytes
 mov dx,offset demofilename
 mov si,0 ;Load address
 call LoadUpFile

 pop es
 cmp al,2
 jz lm03
 cmp al,0
 jnz lm02

 cmp cx,0 ;Zero-length also acts as error
 jz lm03
 jmp retrycode

lm02:
 mov di,offset cantopendemo
 call directprs
 jmp short lm04 

lm03:
 mov di,offset demoerror
 call directprs

lm04:
 call directosrdch
 cmp al,' '
 jnz lm04
 mov di,offset newline
 call directprs
 jmp short lm01

;Name of file containing auto-run commands

demofilename:
 db "DEMO.TXT",0

;    1234567890123456789012345678901234567890
demoerror:
 db asciicr,asciilf
 db "Error reading demo file."
 db asciicr,asciilf
 db "Ctrl-C to abort, SPACE to continue:"
 db asciicr,asciilf
 db 0

;    1234567890123456789012345678901234567890
cantopendemo:
 db asciicr,asciilf
 db "Demo file missing."
 db asciicr,asciilf
 db "Ctrl-C to abort, SPACE to continue:"
 db asciicr,asciilf
 db 0

;-----

;BX is number of paragraphs to allocate
;Returns AX=Paragraph address (or ax=0)

allocatememory:
 cmp bx,ds:[allocatelength]
 ja short am01
 mov ax,ds:[allocateparagraph]
 push ax
 add ax,bx
 mov ds:[allocateparagraph],ax
 mov ax,ds:[allocatelength]
 sub ax,bx
 mov ds:[allocatelength],ax
 pop ax
 ret
am01:
 mov ax,0
 ret

;-----

tryallocate:
 push ax ;Size of picture cache
 push bx ;Size of OOPS

 add ax,ax
 add ax,ax
 add ax,ax
 add ax,ax
 mov ds:[aheadLcache],ax
 add bx,bx
 add bx,bx
 add bx,bx
 add bx,bx
 mov ds:[aheadLoops],bx

 mov ax,ds:[allocatebase]
 mov ds:[allocateparagraph],ax
 mov ax,ds:[allocatesize]
 mov ds:[allocatelength],ax

 cmp ds:[autorun],0
 jz noautorunbuffer
 mov ds:[aheadLautorun],demosize
 mov bx,demosize/16
 call allocatememory
 cmp ax,0
 jnz na01
 jmp allocatefail
na01:
 mov ds:[aheadPautorun],ax

noautorunbuffer:

;Graphics modes need two buffers, for character screen so WORDS can refresh
;area hidden by window, and pixel screen to store border and allow fast
;entry to PICTURES mode.

 cmp ds:[graphics],0
 jz notgraphics
 mov al,ds:[screenmode]
 cmp al,6
 jz mode6map ;MGA b/w graphics
 cmp al,13
 jnc egamap ;EGA-emulation/EGA graphics

;CGA colour graphics

 mov ds:[aheadLgraphicsbuffer],CgaScreen
 mov bx,CgaScreen/16
 call allocatememory
 cmp ax,0
 jnz na02
 jmp allocatefail
na02:
 mov ds:[aheadPgraphicsbuffer],ax

 cmp ds:screenmode,2
 jnc textmapnot1k ;CGA colour graphics with 80 column text

 mov bx,25*40 ;CGA colour graphics with 40 column text
 mov ds:[aheadLtextmap],bx
 mov bx,((25*40)+15)/16
 jmp short textmapnot2k

egamap:
 mov ds:[aheadLgraphicsbuffer],Mode16Screen
 mov bx,Mode16Screen/16
 jmp short setmap

mode6map: ;
 mov ds:[aheadLgraphicsbuffer],mode6Screen
 mov bx,mode6Screen/16
setmap:
 call allocatememory
 cmp ax,0
 jnz na03
 jmp short allocatefail

na03:
 mov ds:[aheadPgraphicsbuffer],ax

textmapnot1k:
 mov bx,25*80
 mov ds:[aheadLtextmap],bx
 mov bx,((25*80)+15)/16
textmapnot2k:
 call allocatememory
 cmp ax,0
 je allocatefail
 mov ds:[aheadPtextmap],ax

notgraphics:

;Allocate up to 64K segment for GAMEDATA, LISTS, Machine-code tables

 mov bx,ds:[gamesize] ;Get max gamedata size
 add bx,workspacesize+128 ;Add vars,lists,spare sector

 shr bx,1 ;Convert bytes to paragraph
 shr bx,1
 shr bx,1
 shr bx,1
 call allocatememory
 cmp ax,0
 je allocatefail

 mov ds:[aheadPgame],ax

;Allocate 1024 byte paragraph for keyboard recall buffer:

 mov bx,((recallsize)/16)+1
 call allocatememory
 cmp ax,0
 je allocatefail
 mov ds:[aheadPrecall],ax
 mov ds:[aheadLrecall],recallsize

;Allocate OOPS buffers:

 pop bx ;Size of OOPS

 call allocatememory
 cmp ax,0
 je allocatefail1 ;(1 item on stack)
 mov ds:[aheadPoops],ax

;Allocate picture cache:

 pop bx ;Size of CACHE

 call allocatememory
 cmp ax,0
 je allocatefail2 ;(0 items on stack)
 mov ds:[aheadPcache],ax

 clc ;Success
 ret

allocatefail:
 pop bx
allocatefail1:
 pop ax
allocatefail2:
 mov ax,0
 mov ds:[aheadPgame],ax
 mov ds:[aheadPtextmap],ax
 mov ds:[aheadLtextmap],ax
 mov ds:[aheadPrecall],ax
 mov ds:[aheadLrecall],ax
 mov ds:[aheadPoops],ax
 mov ds:[aheadLoops],ax
 mov ds:[aheadPcache],ax
 mov ds:[aheadLcache],ax
 mov ds:[aheadPgraphicsbuffer],ax
 mov ds:[aheadLgraphicsbuffer],ax
 mov ds:[aheadPautorun],ax
 mov ds:[aheadLautorun],ax

 mov ax,ds:[allocatebase]
 mov ds:[allocateparagraph],ax
 mov ax,ds:[allocatesize]
 mov ds:[allocatelength],ax

 stc ;Failed
 ret

;-----

;If EGA title picture fails to load, set up a default
;palette so text is visible.

resetwhite:
 cmp cs:screenmode,19
 je NoCorruptDac
 push es
 mov ah,10h
 mov al,2
 push cs
 pop es
 mov dx,offset palettetable
 int 10h
 pop es
NoCorruptDac:
 ret

palettetable:
 db 0 ;0
 db 07h ;1
 db 07h ;2
 db 07h ;3
 db 07h ;4
 db 07h ;5
 db 07h ;6
 db 07h ;7
 db 07h ;8
 db 07h ;9
 db 07h ;10
 db 07h ;11
 db 07h ;12
 db 07h ;13
 db 07h ;14
 db 07h ;15
 db 0 ;Border colour

;-----

setfcbgame:
 call fcbinit
 mov si,offset gamefilename
 mov di,offset sysfcb
 mov bx,offset lengthfilename
 call copycsds
 ret

;-----

;Load code file AINT.EXE

retrycode:
 jmp compleloaded

;-----

;When run under SYMDEB there is insufficient memory so allocate the
;remainder of the current CS as the new segment.

outofmemory:
 mov di,offset warning
 call directprs

pa01:
 call directosrdch
 cmp al,' '
 jnz pa01
 mov di,offset newline
 call directprs
 jmp restart

terminate:
 mov ah,04Ch ;Terminate process
 int 21h
 jmp quit

;    1234567890123456789012345678901234567890
confirm_wait:
 db "Screen format selected = "
 db 0

default:
 db 13,10
 db 13,10
 db "Screen mode unchanged = "
 db 0

warning:
 db asciicr,asciilf
 db "You don't have enough memory for"
 db asciicr,asciilf
 db "that screen format."
 db asciicr,asciilf
 db asciicr,asciilf
 db "Press SPACE BAR to continue:"
 db 0

;-----

compleloaded:
;Code file starts with constants set in header.asm,
;jump to first byte following header:

;Set graphics mode
 mov al,ds:[graphics]
 mov cs:[MenuFgraphicPossible],al

;Set legal/illegal mode
 mov al,ds:[illegalmode]
 mov cs:[MenuFsubmode],al

;Set initial random seed
 mov bx,cs:[driverseed]
 mov cs:[MenuFseed],bx

 mov ax,ds:[aheadPgame]
 mov cs:[MenuPgame],ax
 mov ax,ds:[aheadPtextmap]
 mov cs:[MenuPtextmap],ax
 mov ax,ds:[aheadLtextmap]
 mov cs:[MenuLtextmap],ax
 mov ax,ds:[aheadPrecall]
 mov cs:[MenuPrecall],ax ;Save paragraph start address...
 mov ax,ds:[aheadLrecall]
 mov cs:[MenuLrecall],ax ;and length
 mov ax,ds:[aheadPoops]
 mov cs:[MenuPoops],ax ;Save paragraph start address...
 mov ax,ds:[aheadLoops]
 mov cs:[MenuLoops],ax ;...and length
 mov byte ptr cs:[MenuLoops+2],0 ;Hi byte of length
 mov ax,ds:[aheadPcache]
 mov cs:[MenuPcache],ax ;Save paragraph start address...
 mov ax,ds:[aheadLcache]
 mov cs:[MenuLcache],ax ;...and length
 mov ax,ds:[aheadPautorun]
 mov cs:[MenuPautorun],ax ;Save paragraph start address...
 mov ax,ds:[aheadLautorun]
 mov cs:[MenuLautorun],ax ;...and length

 mov ax,ds:[aheadPgraphicsbuffer]
 mov cs:[MenuPgraphicsBuffer],ax ;Save paragraph start address...
 mov ax,ds:[aheadLgraphicsbuffer]
 mov cs:[MenuLgraphicsBuffer],ax ;...and length

 call ClearCache

;Copy current palette into to maine code 'MenuFpalette'
 mov si,offset DefaultPalette
 mov di,offset MenuFpalette
 mov cx,16
copytable:
 mov al,ds:[si]
 mov cs:[di],al
 inc si
 inc di
 dec cx
 cmp cx,0
 jnz copytable

 mov ax,cs:DefaultLogical ;Copy 16-bit logical colour mask
 mov cs:MenuFlogical,ax

 mov si,offset DefaultBorder
 mov di,offset MenuFborder
 mov cx,30 ;Number of pictures in MenuFborder list
CopyTable2:
 mov al,ds:[si]
 mov cs:[di],al
 inc si
 inc di
 dec cx
 cmp cx,0
 jnz CopyTable2

;First time up clear workspace, so program always cold-starts
;(This allows acode to spot a cold-start, a restart after a disk-error,
;and a chain back from parts 2/3.)
 mov es,cs:aheadPgame ;Gamedata segment
 mov ax,0 ;Must fill workspace with zero for Knight-Orc compatability
 sub di,di
 mov cx,workspacesize/2-1
 rep stosw

 jmp aint

;-----

;Display al (0..19) in decimal

displaysmalldecimal:
 cmp al,20
 jae sd02 ;OS returned a mode outside 0..19
 cmp al,10
 jb sd01
 sub al,10
 push ax
 mov al,'1'
 call directoutput
 pop ax
sd01:
 add al,'0'
 call directoutput
sd02:
  ret

;-----

;Load a file, maximum length CX, name in DX, to address ES:0
;Returns AL=0 if OK (cx=bytes loaded)
;        AL=1 if file not found
;        AL=3 if file can't load

LoadUpFile:
 push cx ;Length
 push si ;Load address

 mov al,0 ;non-private/compatable/read-only
 mov ah,61 ;Open file
 int 21h   ;extended DOS function

 pop si ;Load address
 pop cx ;Length

 jnc le01
 mov al,1  ;File not found
 ret

le01:
 push ax   ;File handle
 push cx   ;length
 push si   ;Load address
 mov bx,ax
 mov al,0  ;relative to start of file
 mov cx,0  ;relative position (high)
 mov dx,0  ;relative position (low)
 mov ah,66 ;move file pointer
 int 21h   ;extended DOS function
 pop si    ;Load address
 pop cx    ;length
 pop ax    ;file handle

 push ax   ;File handle
 push ds

 mov bx,ax ;file handle
; cx=length
 mov ax,es
 mov ds,ax
 mov dx,si ;address DS:DX = ES:SI
 mov ah,63 ;Read from file
 int 21h   ;extended DOS function
 jnc le02

;Error
 pop ds
 pop bx    ;File handle
 mov ah,62 ;Close file handle
 int 21h   ;extended DOS function

 mov al,3  ;File can't load
 ret

le02:
 mov cx,ax ;Number of bytes loaded
 pop ds
 pop bx    ;File handle
 push cx

 mov ah,62 ;Close file handle
 int 21h   ;extended DOS function

 pop cx    ;number of bytes read
 mov al,0  ;File can't load
 ret

;-----

;Load the ax'th sector of a file, name in SYSFCB, to diskbuffer.
;Returns AL=0 if OK

loadstart:
 push ax ;Number of sectors
 mov dx,offset sysfcb
 mov ah,cpnof ;Open file
 int 21h ;CP/M emulation
 cmp al,0
 jz short ls01

 pop ax
 mov al,1 ;Error code 1 - File not found
 ret

ls01:
 pop ax
 cmp al,0
 jz ls02 ;exit with ax=0
 dec ax
 push ax

 mov dx,offset sysfcb
 mov ah,cpnrs
 int 21h

 push ax ;Save return code
 mov dx,offset sysfcb
 mov ah,cpncf
 int 21h
 pop ax ;get return code
 cmp al,0
 jz ls01 ;loaded ok

;error, exit with ax<>0
 pop bx

ls02:
 ret

;-----

;Copies a block of data from cs to ds
;from 0[si] to 0[di] length bx.

copycsds:
 cmp bx,0
 jnz short copy1
 ret
copy1:
 mov al,cs:[si]
 mov ds:[di],al
 inc si
 inc di
 dec bx
 jmp short copycsds

;-----

;Copies a block of data with ds
;from 0[si] to 0[di] length bx.

copydsds:
 cmp bx,0
 jnz short copy3
 ret
copy3:
 mov al,ds:[si]
 mov ds:[di],al
 inc si
 inc di
 dec bx
 jmp short copydsds

;-----

dollarsearch:
 cmp byte ptr es:[si],'$'
 jz founddollar
 inc si
 jmp short dollarsearch
founddollar:
 inc si
 cmp es:[si],al
 jz foundcorrectdollar
 cmp byte ptr es:[si],dollareof ;Found eof
 jz foundeof
;Skip until end-of-line
ds01:
 cmp byte ptr es:[si],asciicr
 jz dollarsearch
 inc si
 jmp short ds01
foundeof:
 mov al,0
 ret
foundcorrectdollar:
 inc si
 mov al,1
 ret

;-----

searchformode:
 mov si,0
aa01:
 push ax
 mov al,dollarforward
 call dollarsearch
 cmp al,0
 jz nosuchmode
 pop ax
 inc si ;Skip first space on line
 cmp al,es:[si]
 jnz aa01
 ret ;Return "Z"

nosuchmode:
 pop ax
 mov al,1 ;Error
 cmp al,0 ;Return "NZ"
 ret

;-----

menumissingerror:
 db asciicr,asciilf
 db "MENU.TXT bad format."
 db asciicr,asciilf
 db 0

palettefilename:
 db "PALETTE.PIC",0

menufilename:
 db "MENU.TXT",0

;-----

;Read a decimal number from MENU.TXT buffer, 0..99
parsesmalldecimal:
 inc si ;Skip first space
 mov al,es:[si] ;Read 0..2, hi byte of mode
 sub al,'0'
 mov ah,0
 push bx
 mov bx,10
 mul bx
 pop bx
 inc si
 mov ah,es:[si] ;Read 0..9, lo byte of mode
 sub ah,'0'
 add al,ah
 ret

;-----

;Print string at [di]
directprs:
 mov al,cs:[di]
 cmp al,0
 jz short directprs1 
 mov al,cs:0[di]
 call directoutput
 inc di
 jmp short directprs
directprs1:
 ret

;-----

newline:
 db asciicr,asciilf
 db 0

;-----

directosrdch:
 mov ah,11 ;Check keyboard Input Status
 int 21h ;ROM-BIOS Universal Function
 cmp al,0
 jnz gotkey
 inc cs:[driverseed]
 jmp short directosrdch

gotkey:
 mov ah,7 ;Universal Function 7 - Keyboard Input
 int 21h ;Universal Function
 cmp al,3 ;^C or ^break
 jnz notbreak
 mov di,offset userabort
 call directosrdch
 jmp terminate

userabort:
 db "USER ABORT"
 db 0

notbreak:
 cmp al,19 ;(Ignore ^R)
 jz directosrdch
 cmp al,0 ;Special key?
 jnz notspecial
 mov ah,7 ;Universal Function 7 - Keyboard Input
 int 21h ;Universal Function
 cmp al,19 ;Alt-R
 jnz directosrdch ;Only accept ALT-R special key
notspecial:
 ret

;-----

graphicdisplayall:
 cmp al,asciicls
 jz menucls
directoutput:
 mov dl,al
 mov ah,2 ;Universal Function 2 - Display Output
 int 21h ;Universial Function
 ret
menucls:
 mov ah,0Fh ;Get current Video Mode
 int 10h ;ROM-BIOS Video Service
 mov ah,0 ;Video Service - Set Video Mode
 int 10h ;ROM-BIOS Video Service
 ret

;-----

;Name of file containing gamedata.

gamefilename:
 db 0 ;Any drive
 db "GAMEDAT."
 db "DAT"
endgamefilename:
lengthfilename=endgamefilename-gamefilename

;-----

;Fatal error during loading.

quit:
 mov di,offset reboot
 call directprs
hang:
 jmp short hang

;    1234567890123456789012345678901234567890
reboot:
 db asciicr,asciilf
 db "Re-boot and try again."
 db asciicr,asciilf
 db 0

;-----

;Prepare system FCB for a new file. Set drive
;to current login drive.

fcbinit:
 mov byte ptr ds:[fcbextension],0
 mov ah,cpnrst
 int 21h
 mov al,0
 mov byte ptr ds:[fcbdrive],al
 mov byte ptr ds:[fcbex],al
 mov byte ptr ds:[fcbcr],al
 ret

;-----

trydisk:
 mov al,0
 cmp al,0 ;Reset carry
 ret

;-----

;Subroutines required by driver subroutines but which have no
;effect during MENU:

cgacopytoscreen:
cgatransferrow:
chain:
checksum:
cleartextmap:
displayall:
DoCompressedCgaPalette:
drawcgaline:
getcharacter:
getseed:
initrecall:
inputline:
oswrch:
osload:
osrdch:
ossave:
ramload:
ramsave:
replacecursor:
resetpagecount:
SafeReplaceCursor:
setoscursor:
settextmode:
 ret

;-----

code ends

;-----

;Folowing way of defining stack is recognised by linker and generates
;a code file which auto sets-up stack:

stacks segment stack 'stack'
 assume ss:stacks

 db 512 dup (0) ;Stack for menu/aint

stacks ends

;-----

 end





