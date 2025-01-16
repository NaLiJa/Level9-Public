


********************************
* 3_d.s   data area etc.       *
********************************

map_hgt:	equ	12
map_wdth:	equ	20

step:	equ	4
xmin:	equ	0
x_max:	equ	288
ymin:	equ	128
y_max:	equ	172

map_cells:	equ	map_hgt*map_wdth	* no. map cells
max_char:	equ	13		* max char no. used
max_flr:	equ	0		* max floor code
num_links:	equ	1000		* no. links in list

x_pos:	dc.w	0		* sprite xcord
y_pos:	dc.w	128		* sprite ycord

xcord:	dc.w	0		* x_cord
zcord:	dc.w	0		* z_cord
hcord:	dc.w	0		* height
ycord:	dc.w	0		* y cord
list_len:	dc.w	0		* data list length
xsize:	dc.w	0		* block x width
xcnt:	dc.w	0		* block x width counter
obj_num:	dc.w	0		* initial object no.

rstr_pnt:	dc.l	rstr_tab		* raster objects pointer
rstr_cnt:	dc.w	49		* max raster no.
comp_pnt:	dc.l	comp_tab		* compressed objects pointer
comp_cnt:	dc.w	99		* max compressed no.
ctrl_pnt:	dc.l	ctrl_tab		* control objects pointer
ctrl_cnt:	dc.w	149		* max control no.
anim_pnt:	dc.l	anim_tab		* animation objects pointer
anim_cnt:	dc.w	199		* max animation no.
cell_pnt:	dc.l	cell_tab		* cell data pointer

image:	dc.w	0		* image no.
hi_cnt:	dc.w	0		* top lines count
lo_cnt:	dc.w	0		* low lines count
pd_off:	dc.l	0		* low data offset
pm_off:	dc.l	0		* hi mask offset

mask1:	dc.l	0		* mask1 pointer
mask2:	dc.l	0
mask3:	dc.l	0
mask4:	dc.l	0
scrn1:	dc.l	0		* screen1 pointer
scrn2:	dc.l	0
scrn3:	dc.l	0
scrn4:	dc.l	0


nx_f_link:	dc.w	0		* next free link offset
nx_f_cnum:	dc.w	0		* next free char number
nx_f_char:	dc.l	0		* next free char pointer
nx_f_mask:	dc.l	0		* next free mask pointer

scrn:	dc.l	0		* screen pointer
scrn_res:	dc.w	0		* screen res save


palet:	dc.w	$000,$111,$222,$333,$444,$777,$770,$740
	dc.w	$700,$047,$137,$214,$020,$334,$223,$112


p_data:
	dc.l	$07E00000,$000007E0,$1FF80000,$00001FF8
	dc.l	$3FFC0000,$00003FFC,$3FFC0000,$00003FFC
	dc.l	$7FFE0000,$00007FFE,$739E0000,$00007FFE
	dc.l	$F39F0000,$0000FFFF,$FFFF0000,$0000FFFF
	dc.l	$FFFF0000,$0000FFFF,$EFF70000,$0000FFFF
	dc.l	$77EE0000,$00007FFE,$781E0000,$00007FFE
	dc.l	$3FFC0000,$00003FFC,$3FFC0000,$00003FFC
	dc.l	$1FF80000,$00001FF8,$07E00000,$000007E0
p_mask:
	ds.b	32

null_mask:	dc.l	$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
	dc.l	$FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF



;g_map:	ds.b	map_cells*4 	* ground cell map
;links:	ds.b	10240-map_cells*4	* link list area
;v_map:	ds.b	map_cells*2 	* view map area




