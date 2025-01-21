;IBM KAOS DRIVER, last byte of code file

;FREE.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

name free

code segment public 'code'
 assume cs:code

;'lastcodebyte' is the last value loaded into memory
;To change this sequence (e.g. to add an ID string)
;   PCTOOLS
;   press SPACE
;   position cursor on MENU.EXE
;   press E
;   press 1/END  (go to EOF)
;   press 9/PgUp (Back 1 sector)
;   press 9/PgUp (Back 1 sector)
;This should now display the code-sector containing the code
;assembled from this file.
;   press E      (Edit)
;Change the bytes from "Internal error$" onwards. I recommend the four-00
;bytes.
;   press F5     (Update)
;   press ESC    (quit)
   

 db "Internal Error$" ;Identify string
 db 0EAh ;far-jump
 db 000h ;Patch-area for ID string
 db 000h
 db 000h
 db 000h
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
 db 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh

code ends

 end






