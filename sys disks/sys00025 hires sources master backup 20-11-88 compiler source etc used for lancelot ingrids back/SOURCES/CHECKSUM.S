* checksum program
* to perform a checksum on named files
*
* Copyright (C) 1986, Level 9 Computing
*
* M.J.Austin, 24/8/86
*
 bra startchecksum
 include 'driver.s'
printchar
 bra driverprintchar

startchecksum
 move.b #initdcode,d0
 bsr driver
trychecksum
* now get file to checksum
 lea checksumdriverblock,a6
 lea endchecksum,a0
 move.l a0,(a6)
 clr.b $8(a6) * zero filename - driver to prompt
 move.b #loaddcode,d0
 bsr driver
 cmp.b #1,(a6)
 beq returntogem
* now calculate the checksum
 bsr prs
 dc.b "Checksum value is: ",0
 even
 move.b #checksumdcode,d0
 bsr driver
 move.b (a6),d0
 bsr hexbyted0
 bsr prs
 dc.b ".",cr,0
 even
 bra.s trychecksum
 even
checksumdriverblock
 ds.b 100
endchecksum
* file will be loaded here