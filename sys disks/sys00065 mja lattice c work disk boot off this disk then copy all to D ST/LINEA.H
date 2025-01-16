/**
*
* This header file defines useful macros and typedefs for use with the
* Line 'A' functions
*
**/
#ifndef NARGS
extern void linea0();
extern void linea1();
extern void linea2();
extern void linea3();
extern void linea4();
extern void linea5();
extern void linea6();
extern void linea7(LA_BLIT *);
extern void linea8();
extern void linea9();
extern void lineaa();
extern void lineab();
extern void lineac(char *);
extern void linead(long, long, char *, char *);
extern void lineae();
extern void lineaf();
#else
extern void linea0();  /* Initialize the Line 'A' */
extern void linea1();  /* Plot a pixel */
extern void linea2();  /* Get a pixel */
extern void linea3();  /* Draw a line */
extern void linea4();  /* Draw a horizontal line */
extern void linea5();  /* Draw a filled rectangle */
extern void linea6();  /* Draw 1 scan line of a filled polygon */
extern void linea7();  /* Perform a BIT block transfer */
extern void linea8();  /* Perform a TEXT block transfer */
extern void linea9();  /* Show the mouse */
extern void lineaa();  /* Hide the mouse */
extern void lineab();  /* Transform the mouse's form */
extern void lineac();  /* Undraw the previously drawn sprite */
extern void linead();  /* Draw a sprite */
extern void lineae();  /* Copy a raster form */
extern void lineaf();  /* Perform a seedfill */
#endif

/**
* Calling linea0() will fetch the following structure from
* the system and store it in external memory.
**/
typedef struct linea_info
{
/* Early versions of TOS don't implement all the possible functions */
  long    li_d0;       /* 0 if old system bugs persist */
  LA_DATA *li_a0;      /* linea data structure pointer */
  LA_FONT **li_a1;     /* system font vector */
  long    (*li_a2)();  /* linea function vector */
} LINEA_INFO;

extern LINEA_INFO LA_INFO;

/**
* The system data structure for implementing graphics.
* Most of this is simply here to confuse you.
**/
typedef struct
{
  WORD ld_vplanes;         /* number of video planes: 1, 2, or 4 */
  WORD ld_vwrap;           /* number of bytes/video line */
  WORD *ld_contrl;         /* pointer to CONTRL array */
  WORD *ld_intin;          /* pointer to INTIN array */
  WORD *ld_ptsin;          /* pointer to PTSIN array */
  WORD *ld_intout;         /* pointer to INTOUT array */
  WORD *ld_ptsout;         /* pointer to PTSOUT array */
  WORD ld_colbit[4];       /* color bit-plane[i] value */
  WORD ld_lstlin;          /* -1 */
  WORD ld_lnmask;          /* line style mask */
  WORD ld_wmode;           /* writing mode 0:replace, 1:transparent, */
                           /* 2:exclusive or, 3:inverse transparent */
  WORD ld_x1;              /* x1 coordinate */
  WORD ld_y1;              /* y1 coordinate */
  WORD ld_x2;              /* x2 coordinate */
  WORD ld_y2;              /* y2 coordinate */
  WORD *ld_patptr;         /* fill pattern pointer */
  WORD ld_patmsk;          /* fill pattern mask */
  WORD ld_mfill;           /* multi-plane fill flag */
  WORD ld_clip;            /* clipping flag */
  WORD ld_xmincl;          /* minimum x clipping value */
  WORD ld_ymincl;          /* minimum y clipping value */
  WORD ld_xmaxcl;          /* maximum x clipping value */
  WORD ld_ymaxcl;          /* maximum y clipping value */
  WORD ld_xdda;            /* accumulator for textblt dda */
  WORD ld_ddainc;          /* fixed point scale factor */
  WORD ld_scaldir;         /* scale direction flag */
  WORD ld_mono;            /* current font is monospaced */
  WORD ld_srcx;            /* x coord of character in font */
  WORD ld_srcy;            /* y coord of character in font */
  WORD ld_dstx;            /* x coord of character on screen */
  WORD ld_dsty;            /* y coord of character on screen */
  WORD ld_delx;            /* width of character */
  WORD ld_dely;            /* height of character */
  WORD *ld_fbase;          /* pointer to start of font form */
  WORD ld_fwidth;          /* width of font form */
  WORD ld_style;           /* textblt special effects flags */
  WORD ld_litemsk;         /* lightening mask */
  WORD ld_skewmsk;         /* skewing mask */
  WORD ld_weight;          /* thickening factor */
  WORD ld_roff;            /* skew offset above baseline */
  WORD ld_loff;            /* skew offset below baseline */
  WORD ld_scale;           /* scaling flag */
  WORD ld_chup;            /* character rotation vector */
  WORD ld_textfg;          /* text foreground color */
  WORD *ld_scrtchp;        /* text special effects buffer */
  WORD ld_scrpt2;          /* offset to scaling buffer from above */
  WORD ld_textbg;          /* text background color */
  WORD ld_copytran;        /* copy raster form type flag */
  WORD (*ld_seedabort)();  /* seedfill end detect function */
} LA_DATA;

/**
* Macro definitions using la_info and la_data to make
* MACRO names as used in the linea.doc description.
**/
#define VPLANES   la_info.li_a0->ld_vplanes
#define VWRAP     la_info.li_a0->ld_vwrap
#define CONTRL    la_info.li_a0->ld_contrl
#define INTIN     la_info.li_a0->ld_intin
#define PTSIN     la_info.li_a0->ld_ptsin
#define INTOUT    la_info.li_a0->ld_intout
#define PTSOUT    la_info.li_a0->ld_ptsout
#define COLBIT0   la_info.li_a0->ld_colbit[0]
#define COLBIT1   la_info.li_a0->ld_colbit[1]
#define COLBIT2   la_info.li_a0->ld_colbit[2]
#define COLBIT3   la_info.li_a0->ld_colbit[3]
#define LSTLIN    la_info.li_a0->ld_lstlin
#define LNMASK    la_info.li_a0->ld_lnmask
#define WMODE     la_info.li_a0->ld_wmode
#define X1        la_info.li_a0->ld_x1
#define Y1        la_info.li_a0->ld_y1
#define X2        la_info.li_a0->ld_x2
#define Y2        la_info.li_a0->ld_y2
#define PATPTR    la_info.li_a0->ld_patptr
#define PATMSK    la_info.li_a0->ld_patmsk
#define MFILL     la_info.li_a0->ld_mfill
#define CLIP      la_info.li_a0->ld_clip
#define XMINCL    la_info.li_a0->ld_xmincl
#define YMINCL    la_info.li_a0->ld_ymincl
#define XMAXCL    la_info.li_a0->ld_xmaxcl
#define YMAXCL    la_info.li_a0->ld_ymaxcl
#define XDDA      la_info.li_a0->ld_xdda
#define DDAINC    la_info.li_a0->ld_ddainc
#define SCALDIR   la_info.li_a0->ld_scaldir
#define MONO      la_info.li_a0->ld_mono
#define SRCX      la_info.li_a0->ld_srcx
#define SRCY      la_info.li_a0->ld_srcy
#define DSTX      la_info.li_a0->ld_dstx
#define DSTY      la_info.li_a0->ld_dsty
#define DELX      la_info.li_a0->ld_delx
#define DELY      la_info.li_a0->ld_dely
#define FBASE     la_info.li_a0->ld_fbase
#define FWIDTH    la_info.li_a0->ld_fwidth
#define STYLE     la_info.li_a0->ld_style
#define LITEMSK   la_info.li_a0->ld_litemsk
#define SKEWMSK   la_info.li_a0->ld_skewmsk
#define WEIGHT    la_info.li_a0->ld_weight
#define ROFF      la_info.li_a0->ld_roff
#define LOFF      la_info.li_a0->ld_loff
#define SCALE     la_info.li_a0->ld_scale
#define CHUP      la_info.li_a0->ld_chup
#define TEXTFG    la_info.li_a0->ld_textfg
#define SCRTCHP   la_info.li_a0->ld_scrtchp
#define SCRPT2    la_info.li_a0->ld_scrpt2
#define TEXTBG    la_info.li_a0->ld_textbg
#define COPYTRAN  la_info.li_a0->ld_copytran
#define SEEDABORT la_info.li_a0->ld_seedabort

/**
* Macros for the most reasonable linea functions.
* All the rest require a long discussion.
**/
#define putpixel(x,y,v) ((PTSIN[0]=x),(PTSIN[1]=y),(INTIN[0]=v),linea1())
#define getpixel(x,y)   ((PTSIN[0]=x),(PTSIN[1]=y),linea2())
#define showmouse()     (linea9())
#define hidemouse()     (lineaa())

/**
* linea7() = BitBlt parameter block.
* Source and destination description blocks
**/
typedef struct
{
  WORD bl_xmin;   /* Minimum x */
  WORD bl_ymin;   /* Minimum y */
  WORD *bl_form;  /* Word aligned memory form */
  WORD bl_nxwd;   /* Offset to next word in line */
  WORD bl_nxln;   /* Offset to next line in plane */
  WORD bl_nxpl;   /* Offset to next plane */
} LA_BLK;

typedef struct
{
  WORD   bb_b_wd;       /* width of block in pixels */
  WORD   bb_b_ht;       /* height of block in pixels */
  WORD   bb_plane_ct;   /* number of planes to blit */
  WORD   bb_fg_col;     /* foreground color */
  WORD   bb_bg_col;     /* background color */
  char   bb_op_tab[4];  /* logic for fg x bg combination */
  LA_BLK bb_s;          /* source info block */
  LA_BLK bb_d;          /* destination info block */
  WORD   *bb_p_addr;    /* pattern buffer address */
  WORD   bb_p_nxln;     /* offset to next line in pattern */
  WORD   bb_p_nxpl;     /* offset to next plane in pattern */
  WORD   bb_p_mask;     /* pattern index mask */
  char   bb_fill[24];   /* work space */
} LA_BLIT
/* Offsets to next word in plane */
#define HIGH_NXWD 2
#define MED_NXWD  4
#define LOW_NXWD  8
/* Scan line widths of the screen */
#define HIG
#define MED_NXLN 160
#define LOW_NXLN 160
/* Offsets between planes */
#define NXPL 2

/**
* linead() = Draw sprite, sprite definition block.
*   sprite save block is 10+VPLANES*64 bytes big.
**/
typedef struct
{
  WORD ls_xhot;       /* x hot spot offset */
  WORD ls_yhot;       /* y hot spot offset */
  WORD ls_form;       /* 1 for VDI, -1 for XOR */
  WORD ls_bgcol       /* background color index */
  WORD ls_fgcol;      /* foreground color index */
  WORD ls_image[32];  /* background/foreground interleaved image */
} LA_SPRITE;

/**
* Font Header. Taken from GEM VDI Programmers Guide G-2
**/

typedef struct
{
  WORD     font_id;           /* face identifier */
  WORD     font_size;         /* font size in points */
  char     font_name[32];     /* face name */
  WORD     font_low_ade;      /* lowest ascii value in face */
  WORD     font_hi_ade;       /* highest ascii value in face */
                              /* distance measured from char baseline */
  WORD     font_top_dst;      /* top line distance */
  WORD     font_ascent_dst;   /* ascent line distance */
  WORD     font_half_dst;     /* half line distance */
  WORD     font_descent_dst;  /* descent line distance */
  WORD     font_bottom_dist;  /* bottom line distance */
  WORD     font_fatest;       /* width of widest char in font */
  WORD     font_fat_cell;     /* width of widest char cell in font */
  WORD     font_left_off;     /* left offset */
  WORD     font_right_off;    /* right offset */
  WORD     font_thickening;   /* number of pixles to widen chars */
  WORD     font_underline;    /* width in pixles of underline */
  WORD     font_lightening;   /* mask used to drop pixles out */
  WORD     font_skewing;      /* mask used to determine skewing */
  unsigned default_font:1;    /* set if default system font */
  unsigned horiz_ofset:1;     /* horizontal ofset tables should be used */
  unsigned byte_swap:1;       /* byte swap flag */
  unsigned mono_space:1;      /* mono spaced font */
  WORD     *font_horiz_off;   /* pointer to horizontal offset table */
  WORD     *font_char_off;    /* pointer to char offset table */
  char     *font_data;        /* pointer to font data */
  WORD     font_width;        /* font width */
  WORD     font_height;       /* font height */
  char     *font_next;        /* pointer to next font */
} LA_FONT;
