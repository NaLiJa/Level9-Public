* RAM.S
*
* Includes all workspace areas which can be set up using ds.b

RamArea

 even
;cyclicib equ RamArea
;* ds.b 4000
;cyclicibtop equ RamArea+4000

* ds.b 1024
AutoRunBlock equ RamArea

gintstacktop equ AutoRunBlock+AutoRunSize+1024 ; cyclicibTop+1024

driveribuff equ gintstacktop
* ds.b driverIbuffSize

Ibuff equ driveribuff+driverIbuffSize
* ds.b 500

* ds.w 127
gnospinitial equ IBuff+500+(127*2)

IntDriverBuffer equ gnospinitial
* ds.b 500

UseCompressedGraphics equ IntDriverBuffer+500
* ds.b 1

UseCompressedCache equ UseCompressedGraphics+1
* ds.b 1

* must be even
CompressedCacheAddress equ UseCompressedCache+1
* ds.l 1

StoredPictureNumber equ CompressedCacheAddress+4
* ds.w 1

* workspace for compressed picture code...
TempBuffer equ CompressedCacheAddress+6
* ds.b PictureData+2

DecompDiskBuffer equ TempBuffer+PictureData+2
* ds.b 256
EndDecompDiskBuffer equ DecompDiskBuffer+300 * 264

CheckSumFound equ EndDecompDiskBuffer
 ds.b 1

LengthToCheckSum equ EndDecompDiskBuffer+2

WorkSpace equ EndDecompDiskBuffer+4
rawdata equ WorkSpace+0
;  DS.W    20				* some space

data_byte equ RawData+20
* ds.b 1

xwidth equ WorkSpace+22
* ds.w 1
ywidth equ WorkSpace+24
*            ds.w 1
previouspixel equ WorkSpace+26
*     ds.b 1
* even
huffmandatabuffer equ WorkSpace+28
* ds.l 1
huffmanshiftcount equ WorkSpace+32
* ds.l 1
sourcepointer equ WorkSpace+36
* ds.l 1

lineofpixels equ WorkSpace+40
* DS.W 320

PictureFileType equ WorkSpace+1040
* ds.w 1

EndWorkSpace equ WorkSpace+1042 * avoid corrupted pics corrupting following
* stuff in workspace when decompressed 360
 even

cyclicib equ EndWorkSpace ; RamArea
* ds.b 1000
cyclicibtop equ cyclicIB+1000 ; RamArea+4000



DriverBuffer equ CyclicIBTop ; EndWorkSpace
* ds.b 40

;;IsPictureValid equ DriverBuffer+40

sprsav equ DriverBuffer+42
* ds.b 266
gint_buffer equ sprsav+266
* ds.b 20
unpackBuffer equ gint_buffer+20
* ds.b 64
threeCharacters equ unpackbuffer+64
* ds.b 33
wrapBuffer equ ThreeCharacters+34 * +1 to make it even.
* ds.b 32
WrapBufferEnd equ WrapBuffer+32
obuff equ WrapBufferEnd
* ds.b 33
gnoscratch equ obuff+33
* ds.b nonspecific * nonspecific is odd, so will sum with 33 to give even
cache equ gnoscratch+nonspecific
* ds.l 25
fileblock equ cache+100
* ds.b 44
dirbuff equ fileblock+44
* ds.b 128
dirtrack equ dirbuff+128
* ds.w 256
scr_buffer equ dirtrack+512
* ds.w 160
buff equ scr_buffer+320
* ds.b 44

* must be even
* interpreter workspace...
WorkSpaceStart equ buff+44
VarTable equ WorkSpaceStart
* ds.b 512
ListArea equ WorkSpaceStart+512
* ds.b $600
WorkSpaceEnd equ WorkSpaceStart+512+$600

InputDebugBlock equ WorkSpaceEnd
* ds.b 128

*MenuSaveArea equ InputDebugBlock+128
* ds.b 160*8*6

allbuffers	equ	InputDebugBlock+128
current		equ	allbuffers+164000 * 160000
startfile equ current
filenamelist	equ	current
* for menu program to build up a list
* of possible games, from which the user chooses one
