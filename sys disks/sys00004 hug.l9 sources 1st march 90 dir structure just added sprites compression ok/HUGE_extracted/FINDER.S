; FINDER.S
;
; Mike Austin 1 Mar 1990
;
; Copyright (C) 1990 Level 9 Computing (Partnership)
;
;
; We have a structure on the first disk of each game which
; essentially replaces the system directory for the game.
; This is a text file, and is of the following form:
;
;	DISK1:\SOUNDS\TUNE1.MUS
;	DISK1:\GAMEDATA.DAT
;	DISK1:\ACODE.ACD
;	DISK2:\SPRITES1.DAT	0 0 530
;	LASTDISK:\SPRITES2.DAT	50 500 800
;
; File/pathnames will be by default in MSDOS format, but
; I guess the local implementer can change these if required.
;
; The disk name/number is optional, but the colon is required.
; The colon does not imply root directory (c.f. Amiga), that
; is implied by the leading backslash.
;
; So, for hard disk you might get a structure like:
;
;	; This is a comment.
;	:SOUNDS\TUNE1.MUS
;	:GAMEDATA.DAT
;	:ACODE.ACD
;	:SPRITES1.DAT	0 0 530
;	:SPRITES2.DAT	50 500 800
;	*
;
; Any numbers after the filename will be passed back to the
; program calling in some form - probably the original text -
; to avoid unnecessary parsing by other callers which don't use them.

; For sprites files, the numbers refer to the sector number
; with which each sprites file starts, and the first and last cell numbers
; therein. If they are ommitted, the sprites files are presumed
; to be contiguous (i.e. no overlap) and the last sector header
; of each must be examined to find out how many cells are contained.




; Each line will be terminated by a 0D hex and maybe other control
; codes which should be ignored.
;
; Any line starting with a semi-colon should be ignored.
;
; The directory file will not be scanned after the asterix:
; this should be at the start of a line, anywhere before a colon
; or where a colon would be.

 ifnd Huge * Standalone?
  lea S(PC),a5
  lea SearchForString,a0
  bsr FindFile
  dc.w $4afa
 endc * Huge

;------------------
LoadDirectory:
 lea LoadDirectoryDriverBlock-S(A5),a6
 move.l FreeWorkspace-S(a5),(a6)
 bsr LoadFile
 move.l #0,d0
 move.l 4(a6),d1
 beq.s LDEnd
 move.l d1,FreeWorkSpace-S(A5)
 move.l (a6),d0 * start of directory

LDEnd
 move.l d0,DirectoryPtr-S(A5)
 rts

;--------
FindFile:
; find the file with filename A0.L: return
; the actual filename at A0.L and the disknumber in DiskNum
; (or the corresponding Amiga concept for use by DiskRequestor
; when the caller actually tries to open the file).
; and a1.l as the start of the text containing the parameters.

 move.l DirectoryPtr-S(A5),d0
 beq.s FFNoEntry
 move.l d0,a1

FindFileNewLine
 bsr FFParseLine
; parses a line of the directory structure, starting at a1.l
; It returns start of name at a3.l and the pathname starts at a2.l
; And returns a1.l as the start of the numbers.
; And a4.l as the start of the line containing the disk name.
; and d0.b as '*' for end of file
 cmp.b #'*',d0
 bne.s FF2
FFNoEntry
; haven't got an entry for that filename.
 rts


FF2
; compare filename (a3.l) with the one we're looking for (a0.l)
; our search filename terminates with 0
 movem.l a0/a3,-(sp)
FFCompareLoop
  move.b (a0)+,d0
  beq.s FFFound
  cmp.b #'a',d0
  bcs.s FFCL1
  cmp.b #'z'+1,d0
  bcc.s FFCL1
  and.b #$DF,d0 * make case-insensitive
FFCL1
  move.b (a3)+,d1
  cmp.b #'a',d1
  bcs.s FFCL2
  cmp.b #'z'+1,d1
  bcc.s FFCL2
  and.b #$DF,d1 * make case-insensitive
FFCL2
  cmp.b d1,d0
  beq.s FFCompareLoop
; not found
 movem.l (sp)+,a0/a3
 bra.s FindFileNewLine

FFFound
; have found the filename: pass back the disk and path/name to
; the caller.
 move.b #0,(a3) * make sure path/filename is terminated by zero
 movem.l (sp)+,a0/a3
 move.l a2,a0 * return path and name.
; what is the disk number?
; (don't need to check for end of line or file here.)
 clr.w d0
FFF1
 move.b (a4)+,d0
 cmp.b #':',d0
 beq.s FFNoDiskName * none specified - use current
 cmp.b #'A',d0
 bcs.s FFF1
 cmp.b #'Z'+1,d0
 bcc.s FFF1
 sub.b #'A'-1,d0 * 'A' becomes disk 1.
 move.w d0,DiskNum-S(A5)

FFNoDiskName:
; return to caller: a0.l is path/name, a1.l is parameters text
 rts
;----

;---
;------
FFPLToNextLine
 move.b (a1)+,d0
 cmp.b #'*',d0
 beq.s FFPLExit * shouldn't get this here, but just in case...
 cmp.b #$0d,d0
 bne.s FFPLToNextLine

FFParseLine
; parse a line of the directory structure, starting at a1.l
; It returns start of name at a3.l and the pathname starts at a2.l
; And returns a1.l as the start of the numbers. These are
; parsed later, if needed - for speed reasons.
; And d0.b as '*' if end of file encountered,
 move.l a1,a4 * save start of line (for disk name later)

FFLoop1
 move.b (a1)+,d0
 cmp.b #'*',d0
 beq.s FFPLExit
 cmp.b #$0d,d0 * a blank line - save new start of line, and carry on.
 beq FFParseLine * try another line
 cmp.b #';',d0 * a comment - ignore it.
 beq FFPLToNextLine
 cmp.b #':',d0
 bne.s FFLoop1

; we've got to the start of the pathname. Now
 move.l a1,a2 ; save the start of this pathname
 move.l a1,a3 ; and save the start of next segment, in case
; we go straight into the filename itself.
; And start scanning for the filename itself...
FFLoop2
 move.b (a1)+,d0
 cmp.b #'\',d0
 bne.s FFNotPathSeparator
 move.l a1,a3 * save the start of the next segment of the filename
FFNotPathSeparator
 cmp.b #' ',d0
 bgt.s FFLoop2 ; not a space or carriage return, both of which
; would terminate the filename.

; Ok, we have the end of the filename.
; It starts at a3.l and the pathname starts at a2.l
 subq.l #1,a1
 cmp.l a3,a1
 beq.s FFParseLine * null filename

FFPLExit
 rts
;------------------------------
;* parse the numbers which follow the name/path/filename.
; bsr readdecimal 
;* given a decimal number as an ascii string at a0, return 
;* its value in d0.l 
;* and a0.l = charcter after the number 


 even
LoadDirectoryDriverBlock
 dc.l 0
 dc.l 0
 dc.b 'dir.txt',0
 even

;-----------
* STUFF PURELY FOR STAND-ALONE VERSION.
 ifnd Huge * Stand-alone?
S
LoadFile rts

DirectoryPtr dc.l Directory

Directory
 dc.b ":ACODE.ACD",13
 dc.b "C:SPRITES3.DAT 500 300",13
 dc.b "D:\COMMON.L9\COMMAND.PRG",13
 dc.b "*",0

 even

SearchForString
 dc.b "cOmMAN.PRG",0
 even

DiskNum dc.w 0

FreeWorkSpace dc.l FWS1
FWS1

 endc * Huge: standalone?


