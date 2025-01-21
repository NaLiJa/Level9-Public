;IBM KAOS DRIVER, picture/disk cache handler

;CACHE.ASM

;Copyright (C) 1988 Level 9 Computing

;-----

name driver

 public cachetablefull
 public clearcache
 public incache
 public junkoldest
 public loadintocache

;In DRIVER.ASM:
 extrn filenamebuffer:byte
 extrn trydisk:near

;In ENTRY.ASM:
 extrn calcpages:near
 extrn diskbuffer:byte
 extrn fcbdrive:byte
 extrn LoadUpFile:near

;In HIRES.ASM:
 extrn lastpicdrawn:word
 extrn picnumber:word
 extrn storedecimal:near
 extrn taskaddress:word

;In DECOMP.ASM:
 extrn checkrightkindoffile:near

;These include files must be named in MAKE.TXT:
 include head.asm

;-----

code segment public 'code'
 assume cs:code,ds:code

;-----

cachenumber dw 0

;Cache handler:

currentcacheage db 0

cache1picnum dw 0  ;Picture number
cache1age db 0     ;0 = Not used, otherwise higher numbers are youngest
cache1address dw 0 ;Address with Pcache segment of start of picture data

cache2picnum dw 0
cache2age db 0
cache2address dw 0

cache3picnum dw 0
cache3age db 0
cache3address dw 0

cache4picnum dw 0
cache4age db 0
cache4address dw 0

cache5picnum dw 0
cache5age db 0
cache5address dw 0

;-----

clearcache:
 mov al,0
 mov ds:[cache1age],al
 mov ds:[cache2age],al
 mov ds:[cache3age],al
 mov ds:[cache4age],al
 mov ds:[cache5age],al
 mov ds:[currentcacheage],1
 mov ds:[taskaddress],0 ;(Title screen is always first picture) 
 mov ds:[lastpicdrawn],0
 ret

;-----

;Returns 'Z' if cache empty

cacheinuse:
 mov al,ds:[cache1age]
 or al,ds:[cache2age]
 or al,ds:[cache3age]
 or al,ds:[cache4age]
 or al,ds:[cache5age]
 cmp al,0
 ret

;-----

;Returns 'NZ' if cache table full

cachetablefull:
 mov al,ds:[cache1age]
 cmp al,0
 jz notfull
 mov al,ds:[cache2age]
 cmp al,0
 jz notfull
 mov al,ds:[cache3age]
 cmp al,0
 jz notfull
 mov al,ds:[cache4age]
 cmp al,0
 jz notfull
 mov al,ds:[cache5age]
 cmp al,0
notfull:
 ret

;-----

cachefreespace:
 call cacheinuse
 jz allfree

;Not find highest start address of any cached picture
 mov bx,0

 cmp ds:[cache1age],0
 jz cf01
 cmp bx,ds:[cache1address]
 jnc cf01
 mov bx,ds:[cache1address]
cf01:

 cmp ds:[cache2age],0
 jz cf02
 cmp bx,ds:[cache2address]
 jnc cf02
 mov bx,ds:[cache2address]
cf02:

 cmp ds:[cache3age],0
 jz cf03
 cmp bx,ds:[cache3address]
 jnc cf03
 mov bx,ds:[cache3address]
cf03:

 cmp ds:[cache4age],0
 jz cf04
 cmp bx,ds:[cache4address]
 jnc cf04
 mov bx,ds:[cache4address]
cf04:

 cmp ds:[cache5age],0
 jz cf05
 cmp bx,ds:[cache5address]
 jnc cf05
 mov bx,ds:[cache5address]
cf05:

;Now add on length of last picture to start address of last picture
 mov es,cs:[MenuPcache]
 mov ax,es:BitmapPicLength[bx]
 add ax,bx

 mov bx,cs:[MenuLcache] ;Convert to bytes free
 sub bx,ax
 mov ax,bx
 ret

allfree:
 mov ax,cs:[MenuLcache]
 ret

;-----

junkoldest:
 call cachelastpicture
;ah is entry number, al is its age, bx is the picture address
 cmp ah,0
 jnz jo00
 mov al,1 ;Failed
 jmp jo41

jo00:
 cmp ah,1
 jnz jo11
 mov ds:[cache1age],0

jo11:
 cmp ah,2
 jnz jo12
 mov ds:[cache2age],0

jo12:
 cmp ah,3
 jnz jo13
 mov ds:[cache3age],0

jo13:
 cmp ah,4
 jnz jo14
 mov ds:[cache4age],0

jo14:
 cmp ah,5
 jnz jo15
 mov ds:[cache5age],0

jo15:
;Now shunt cache (bx is the picture address)

 mov es,cs:[MenuPcache]
 mov cx,es:BitmapPicLength[bx] ;Length of deleted picture

 cmp ds:[cache1age],0
 jz jo20
 cmp ds:[cache1address],bx
 jc jo20
 sub ds:[cache1address],cx
jo20:

 cmp ds:[cache2age],0
 jz jo21
 cmp ds:[cache2address],bx
 jc jo21
 sub ds:[cache2address],cx
jo21:

 cmp ds:[cache3age],0
 jz jo22
 cmp ds:[cache3address],bx
 jc jo22
 sub ds:[cache3address],cx
jo22:

 cmp ds:[cache4age],0
 jz jo23
 cmp ds:[cache4address],bx
 jc jo23
 sub ds:[cache4address],cx
jo23:

 cmp ds:[cache5age],0
 jz jo24
 cmp ds:[cache5address],bx
 jc jo24
 sub ds:[cache5address],cx
jo24:

;bx is address of picture to delete, cx its length

 add cx,bx ;Copy from address
jo30:
 cmp cx,cs:[MenuLcache]
 jnc jo31
 xchg si,cx
 mov al,es:[si]
 xchg si,cx
 mov es:[bx],al
 inc bx
 inc cx
 jmp short jo30
jo31:

 mov al,0 ;Indicate success
jo41:
 cmp al,0
 ret

;-----

;If cache empty, returns ah=0
;Return address of oldest picture
;ah is entry number, al is its age, bx is the picture address

cachelastpicture:
 mov al,0FFh ;Oldest age
 mov ah,0
 cmp ds:[cache1age],0
 jz jo01
 cmp al,ds:[cache1age]
 jc jo01
 mov al,ds:[cache1age]
 mov ah,1
 mov bx,ds:[cache1address]
jo01:
 cmp ds:[cache2age],0
 jz jo02
 cmp al,ds:[cache2age]
 jc jo02
 mov al,ds:[cache2age]
 mov ah,2
 mov bx,ds:[cache2address]
jo02:
 cmp ds:[cache3age],0
 jz jo03
 cmp al,ds:[cache3age]
 jc jo03
 mov al,ds:[cache3age]
 mov ah,3
 mov bx,ds:[cache3address]
jo03:
 cmp ds:[cache4age],0
 jz jo04
 cmp al,ds:[cache4age]
 jc jo04
 mov al,ds:[cache4age]
 mov ah,4
 mov bx,ds:[cache4address]
jo04:
 cmp ds:[cache5age],0
 jz jo05
 cmp al,ds:[cache5age]
 jc jo05
 mov al,ds:[cache5age]
 mov ah,5
 mov bx,ds:[cache5address]
jo05:
;ah is entry number, al is its age, bx is the picture address
 ret

;-----

;AX is picture number,
;Returns 'NZ' if picture is not in cache,
;or BX as the address of the picture.

incache:
 cmp ds:[cache1age],0
 jz ic01
 cmp ax,ds:[cache1picnum]
 jnz ic01
 mov bl,ds:[currentcacheage]
 mov ds:[cache1age],bl
 mov bx,ds:[cache1address]
 ret
ic01:

 cmp ds:[cache2age],0
 jz ic02
 cmp ax,ds:[cache2picnum]
 jnz ic02
 mov bl,ds:[currentcacheage]
 mov ds:[cache2age],bl
 mov bx,ds:[cache2address]
 ret
ic02:

 cmp ds:[cache3age],0
 jz ic03
 cmp ax,ds:[cache3picnum]
 jnz ic03
 mov bl,ds:[currentcacheage]
 mov ds:[cache3age],bl
 mov bx,ds:[cache3address]
 ret
ic03:

 cmp ds:[cache4age],0
 jz ic04
 cmp ax,ds:[cache4picnum]
 jnz ic04
 mov bl,ds:[currentcacheage]
 mov ds:[cache4age],bl
 mov bx,ds:[cache4address]
 ret
ic04:

 cmp ds:[cache5age],0
 jz ic05
 cmp ax,ds:[cache5picnum]
 jnz ic05
 mov bl,ds:[currentcacheage]
 mov ds:[cache5age],bl
 mov bx,ds:[cache5address]
 ret
ic05:
 mov al,1 ;Return 'NZ'
 cmp al,0
 ret

;-----

;CX is picture number, Returns al=0 if loaded
; al=1 if disk missing
; al=2 if picture file missing
; al=3 if not enough space in cache

loadintocache:
 mov cx,ds:[picnumber]
 call storedecimal

;Now access disk

 mov cs:fcbdrive,0 ;Default drive
 call trydisk
 jnc li01 
 mov al,1 ;No disk in drive
 ret

li01:
 mov ds:[cachenumber],0

 call cachefreespace
 mov cx,ax                    ;cx=length
 mov dx,offset filenamebuffer ;dx=name
 mov si,cs:[MenuLcache]
 sub si,ax                    ;si=Load address
 mov ds:taskaddress,si        ;Save picture address
 mov es,cs:[MenuPcache]       ;Paragraph to load file into
 call LoadUpFile
 cmp al,0
 jz li02                      ;Loaded OK

 mov al,2 ;Picture file missing
 ret

li02:
 push cx
 call cachefreespace
 pop cx
 cmp ax,cx ;Bytes requested > bytes loaded?
 jnc li04

li03:
 mov al,3  ;Not enough space
 ret

li04:
 mov bx,ds:taskaddress

 cmp byte ptr es:BitmapPicWidth[bx],stfileid ;Compressed picture
 jz li05
 cmp byte ptr es:BitmapPicWidth[bx],pcfileid ;Compressed picture
 jnz notcompressed
li05:
 mov ah,es:BitmapPicLength+0[bx] ;Length is stored lo-hi reversed.
 mov al,es:BitmapPicLength+1[bx]
 inc ax ;Include checksum byte
 mov es:BitmapPicLength+0[bx],ax

 cmp cx,bx ;loaded>=size of picture
 jb li03  ;Not all loaded.

 mov si,bx ;Check picture at (es:si)
 call checkrightkindoffile
 jz pictureinmemory

 mov al,2 ;Checksum error, return as file missing
 ret

notcompressed:
 mov bx,es:BitmapPicLength[bx] ;Length of picture
 cmp cx,bx ;Bytes loaded>=size of picture
 jb li03  ;Not all loaded.

pictureinmemory:
 mov bx,es:BitmapPicLength[bx] ;Length of picture

 mov al,0 ;Loaded ok
 mov bx,ds:taskaddress ;Return address loaded

 mov cx,ds:[picnumber]
 mov dl,ds:[currentcacheage]

 inc ds:[currentcacheage] ;Dont allow age to be zero or 0FFh.
 cmp ds:[currentcacheage],0FFh
 jnz li06
 mov ds:[currentcacheage],1
li06:

 cmp ds:[cache1age],0
 jnz li07
 mov ds:[cache1picnum],cx
 mov ds:[cache1age],dl
 mov ds:[cache1address],bx
 ret
li07:

 cmp ds:[cache2age],0
 jnz li08
 mov ds:[cache2picnum],cx
 mov ds:[cache2age],dl
 mov ds:[cache2address],bx
 ret
li08:

 cmp ds:[cache3age],0
 jnz li09
 mov ds:[cache3picnum],cx
 mov ds:[cache3age],dl
 mov ds:[cache3address],bx
 ret
li09:

 cmp ds:[cache4age],0
 jnz li10
 mov ds:[cache4picnum],cx
 mov ds:[cache4age],dl
 mov ds:[cache4address],bx
 ret
li10:

 cmp ds:[cache5age],0
 jnz li11
 mov ds:[cache5picnum],cx
 mov ds:[cache5age],dl
 mov ds:[cache5address],bx
 ret
li11:
 mov al,3 ;Return as error - cache full
 ret

;-----

code ENDS

 END






