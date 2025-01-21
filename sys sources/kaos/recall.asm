;IBM KAOS DRIVER. Command Editor Routines.

;RECALL.ASM

;Copyright (C) 1987,1988 Level 9 Computing

;-----

name recall

 public cursorcr
 public cursorup
 public cursordown
 public initrecall

code segment public 'code'
 assume cs:code

;These include files must be named in MAKE.TXT:
 include head.asm

;-----

bufferend dw 0
bufferptr dw 0
seenspace db 0

;-----

inputbuffersize = 80 ;Characters allowed in INPUTLINE

;-----

initrecall:
 mov ax,0 
 mov ds:[bufferend],ax
 mov ds:[bufferptr],ax
 ret

;-----

cursorcr:
 mov ax,cs:[MenuLrecall] ;Length of recall buffer
 cmp ax,0
 jnz short cc01
 ret  ;Not enough memory for recall buffer
cc01:

 push di
 push si
 push es
 mov es,cs:[MenuPrecall] ;Get paragraph address for recall buffer

;Copy input buffer 0[si] to end of keyboard buffer

findnonspace1:
 mov al,[si]
 cmp al,' '
 jnz short notspace1
 inc si
 jmp short findnonspace1
notspace1:
 cmp al,0
 jnz short notend
 jmp short shuntfinished ;No input
notend:
 mov al,0
 mov ds:[seenspace],al

 mov di,ds:[bufferend]
crcopy:
 mov al,[si]
 cmp al,0
 jz short foundnull
 cmp al,' '
 jnz short crcopynonspace
 mov ds:[seenspace],al
 inc si
 jmp short crcopy
crcopynonspace:
 mov al,ds:[seenspace]
 cmp al,0
 jz short nospace
 mov al,0
 mov ds:[seenspace],al
 mov al,' '
 mov es:[di],al ;(In recall buffer/paragraph)
 inc di
nospace:
 mov al,[si]
 mov es:[di],al ;(In recall buffer/paragraph)
 inc di
 inc si
 jmp short crcopy

foundnull:
 mov es:[di],al ;(In recall buffer/paragraph)
 cmp di,ds:[bufferend]
 jz short shuntbuffer ;Nothing entered
 inc di
 mov ds:[bufferend],di

;Ensure still 80 bytes free at end of keyboard buffer

shuntbuffer:

 mov ax,cs:[MenuLrecall] ;Length of recall buffer
 mov bx,ds:[bufferend]
 clc
 sbb ax,bx
 cmp ax,inputbuffersize+10
 jnc short shuntfinished

 mov si,1 ;First non-terminator in recall buffer
shuntsearch:
 mov al,es:[si] ;(In recall buffer/paragraph)
 cmp al,0
 jz short shuntstart
 inc si
 jmp short shuntsearch

shuntstart:
 mov di,0 ;Destination during 'shunt'

shunting:
 mov al,es:[si] ;(In recall buffer/paragraph)
 mov es:[di],al ;(In recall buffer/paragraph)
 cmp si,ds:[bufferend]
 jnc short shuntadjust
 inc si
 inc di
 jmp short shunting

shuntadjust:
 mov ds:[bufferend],di ;Number of characters now in recall buffer
 jmp short shuntbuffer

shuntfinished:
 mov ax,ds:[bufferend]
 mov ds:[bufferptr],ax

 pop es
 pop si
 pop di
 ret

;-----

cursorup:
 mov cx,bx
 cmp word ptr cs:[MenuLrecall],0 ;Length of recall buffer
 jnz short cu01
 ret  ;Not enough memory for recall buffer
cu01:
 push es
 mov es,cs:[MenuPrecall] ;(In RECALL paragraph)
 push si

 cmp ds:[bufferptr],0 
 jz short upend ;No more input to recall

 mov si,ds:[bufferptr]
 dec si

backsearch:
 cmp si,0 
 jz short up2 ;At start of recall buffer
 dec si
 mov al,0
 cmp es:[si],al
 jnz short backsearch
 inc si
up2:
 mov ds:[bufferptr],si
 pop si

 push si
 call replaceinput
upend:
 pop si
 pop es
 mov bx,cx
 ret

;-----

cursordown:
 mov cx,bx
 mov ax,cs:[MenuLrecall] ;Length of RECALL buffer
 cmp ax,0
 jnz short cd01
 ret  ;Not enough memory for recall buffer
cd01:
 push es
 mov es,cs:[MenuPrecall] ;(In recall paragraph)
 push si

 mov ax,ds:[bufferptr]
 cmp ax,ds:[bufferend]
 jz short downend ;Reached last command

 mov si,ax
forwardsearch:
 cmp si,ds:[bufferend]
 jz short down2
 mov al,es:[si]
 inc si
 cmp al,0
 jnz short forwardsearch
 cmp si,ds:[bufferend]
 jz short downend ;At last position, don't redisplay

down2:
 mov ds:[bufferptr],si
 pop si

 push si
 call replaceinput
downend:

 pop si
 pop es
 mov bx,cx
 ret

;-----
 
replaceinput: 
 push es
 mov es,cs:[MenuPrecall]
 
;Display input from current buffer recall position and store in input line 
 push si 
 mov ch,0 ;Cursor position
 mov di,ds:[bufferptr]
 
redisplay: 
;Don't need to redisplay here but need to set ch=cl=length of input line 
 mov cl,ch ;Return cursor column 
 mov bx,si 
 dec bx ;Return address within buffer 
 mov es,cs:[MenuPrecall] ;(In recall paragraph)
 mov al,es:[di] 
 cmp al,0 
 jz short displayed 
 mov [si],al 
 inc ch 
 inc si 
 inc di 
 jmp short redisplay
 
 mov cx,0 
 mov bx,0
 
displayed: 
 pop si 
 pop es
 ret

;-----

code ends

 end









