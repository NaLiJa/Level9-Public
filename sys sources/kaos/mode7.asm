;Hercules. Video Subsystems page 38

;MODE7.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

NAME mode7

;-----

code SEGMENT public 'code'

 ASSUME cs:code,ds:code

;-----

 call HercGraphMode
 mov ah,76 ;Terminate
 int 21h ;Dos Service

;-----

HercGraphMode:
 push bp
 mov bp,sp
 push si
 push di

 push cs
 pop ds

;Update Video BIOS Data Area with reasonable values

 mov ax,40h
 mov es,ax
 mov di,49h ;es:di = 0040:0049 BIOS Data area

 mov si,offset BiosData
 mov cx,BIOSDataLen
 rep movsb ;Update BIOS data area

;Set Configuration switch

 mov dx,03BFh ;Configuratrion switch port
 mov al,1 ;Excludee 2nd 32k of video buffer

 out dx,al ;Allow graphics mode

;Blank the screen to avoid interference during CRTC programming

 mov dx,03B8h ;CRTC Mode Control register
 xor al,al ;Disable video dignal
 out dx,al

;Program the CRTC

 sub dl,4 ;CRTC address reg port 3B4h

 mov si,offset CRTCParams
 mov cx,CRTCParamsLen

L01:
 lodsw ;al=register number, ah=value

 out dx,ax
 loop L01

;Set graphics mode

 add dl,4 ;CRTC Mode Control
 mov al,byte ptr ds:CRTMode

 out dx,al ;Enable graphics mode, Enable video

 pop di
 pop si
 mov sp,bp
 pop bp
 ret

;-----

;These are the parameters recommended by hercules.
;They are bases on 16 pixels/character and
;4 scan lines per character.

CRTCParams:
 db 00h,35h ;Horizontal Total: 54 Characters
 db 01h,2Dh ;Horizontal Displayed: 45 Characters
 db 02h,2Eh ;Horizontal sync position: at 46th character
 db 03h,07h ;Horizontal Sync Width: 7 Character clocks

 db 04h,5Bh ;Vertical Total; 92 characters (368 lines)
 db 05h,02h ;Vertical adjust: 2 scan lines
 db 06h,57h ;Vertical displayed: 87 character rows (348 lines)
 db 07h,57h ;Vertical sync position: after 87th char row

 db 09h,03h ;Max scan line: 4 scan lines per char

CRTCParamsLen equ (this byte - CRTCParams)/2

;-----

BIOSData:
          db 7         ;CRT_MODE
          dw 80        ;CRT_COLS
          dw 8000h     ;CRT_LEN
          dw 0         ;CRT_START
          dw 8 dup(0)  ;CURSOR_POSN
          dw 0         ;CURSOR_MODE
          db 0         ;ACTIVE_PAGE
CRTCAddr: dw 03B4h     ;ADDR_6845
CRTMode:  db 0Ah       ;CRT_MODE_SET
          db 0         ;CRT_PALETTE

BIOSDataLen equ this byte - BIOSData

code ENDS

 END







