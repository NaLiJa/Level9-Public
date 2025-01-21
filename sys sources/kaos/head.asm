;Shared data descriptions.

;HEAD.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

;MENU.EXE and AINT.EXE share a common 'configuration' data area at the
;start of the file AINT.EXE:

;MenuJump             = 0 AINT.EXE cold start vector
MenuPgame             = 3 ;Segment for start of complete.dat+vars+temp+lists
MenuPrecall           = 5 ;Segment for start of recall buffer
MenuLrecall           = 7 ;Length of recall buffer
MenuPoops             = 9 ;Segment for start of OOPS buffers
MenuLoops             = 11 ;Length of OOPS buffers
MenuPcache            = 14 ;Segment for picture cache
MenuLcache            = 16 ;Length of picture cache
MenuPtextmap          = 18 ;Segment for text screen
MenuLtextmap          = 20 ;Length of text screen
MenuPgraphicsBuffer   = 22 ;Segment for EGA/CGA/MGA picture buffer
MenuLgraphicsBuffer   = 24 ;Length of EGA/CGA/MGA picture buffer
MenuPautorun          = 26 ;Segment for auto-demo commands
MenuLautorun          = 28 ;Length of auto-demo commands
MenuFpalette          = 30 ;EGA palette fixes.
MenuFgraphicpossible  = 46 ;Screen mode allows graphics
MenuFsubmode          = 47 ;Illegal I/O & select compatible-mode(s)
MenuFseed             = 48 ;Random number seed
MenuFpicturetype      = 50 ;0=words, 1=pics, 2=Title picture
MenuFlogical          = 51 ;bit mask for Logical colours used in border
MenuFborder           = 53 ;Up to 30 pics which use border colours
MenuHeaderLength      = 83

;-----

;Gamedata segment contains:
;  0-2559 Vars and temp lists
;  2560+  Gamedata (includes acode and permanent tables)

;Newer games are smaller, but Knight Orc needs 2.5K bytes
workspacesize = 2560

;Copies of graphics screen memory:
CgaScreen    = 32000 ;320 by 136 pixels. (but only displays 160x100)
mode6Screen  = 21760 ;640 by 136 pixels.
Mode13Screen = 21760 ;320 x 200 pixels
Mode14Screen = 43520 ;640 x 200 pixels
Mode16Screen = 65280 ;640 x 202 pixels

;sub-modes for modes 16 (EGA)
ega_not_so       = 1
ega_okish        = 2
ega_ultra        = 3

;sub-modes for modes 1/3 (CGA)
cga_low_res      = 4

;sub-modes for modes 13/14 (EGA emulation CGA)
ega_cga_low_res  = 5
ega_full_low_res = 6

vga_illegal      = 7 ;As ega_ultra but option for VGA palette.

;-----

startsavearea equ 0             ;put at MenuPgame:0
gamedata      equ workspacesize ;put at MenuPgame:workspacesize

kbdbufsize = 64 ;Keyboard buffer during 'PRESS ANY KEY'
inputbuffersize = 160 ;Characters allowed in INPUTLINE

mode7colour = 7 ;Steady, Black background, Normal intensity, White.
textcolour = 7 ;Logical colour used for text
charactercolour = 7 ;White * 14 ;Non blinking yellow (for CGA display)

;Uncompressed picture file structure:
BitmapPicLength     = 0
BitmapPicWidth      = 2
BitmapPicHeight     = 4
BitmapPicColours    = 6
BitmapPicBackground = 22
BitmapPicData       = 23

; Offsets into compressed picture file header
;filelength   equ 0                    ; length of file - 1 (LSB FIRST)
filetype      equ 2                    ; identify file as comp. picture
palette       equ filetype+2           ; 16 words one for each colour
xsize         equ palette+32           ; width in pixels
ysize         equ xsize+2              ; height in pixels
firstpixel    equ ysize+2              ; colour of top left pixel (0-15)
nextbestpixel equ firstpixel+2         ; complicated 16x16 matrix
huffmantable  equ nextbestpixel+256
huffmanlength equ huffmantable         ; lookup table of lengths of codes
huffmandecode equ huffmantable+16      ; lookup table of codes
picturedata   equ huffmandecode+256

stfileid equ 0FFh ;third byte of picture file.
pcfileid equ 0FEh

;-----

cpnrst = 13 ;Reset disk system
cpnof  = 15 ;Open File
cpncf  = 16 ;Close File
cpndf  = 19 ;Delete File
cpnrs  = 20 ;Read Sequential
cpnws  = 21 ;Write Sequential
cpnmf  = 22 ;Make File

;-----

;Ascii control codes:
asciibs = 08h
asciilf = 0Ah
asciicls = 0Ch
asciicr = 0Dh
space = ' '

;-----
