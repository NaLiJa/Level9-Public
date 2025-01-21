/*	NEO2LBM.C  */

#include <stdio.h>
#include <dos.h>
#include <dir.h>


	FILE *infile,*outfile;
	int long position;
	char far *screen=0Xa0000000;
	int screenxbytes=40,screenylines=200,screenbitplanes=4;
	union REGS inregs,outregs;

	static struct ffblk fileblock;
	static char filebuffer[200];
	char *bufferptr;

/*	struct ffblk
			{
			char      ff_reserved[21];
			char      ff_attrib;
			unsigned  ff_ftime;
			unsigned  ff_fdate;
			long      ff_fsize;
			char      ff_name[13];
			};						*/

	static char filename[15];

main(argc,argv)
	int argc;
	char **argv;

	{
	int bitp,colour;

/* check parameters */
	if (argc!=2)
		{
		printf("NEO2LBM - parameter is: sourcefilespec\n");
		goto farfinish;
		}

/* parse filename */
	fparse(argv[1],"NEO");


/* find first filename */
	if (findfirst(filename,&fileblock,0)!=0)
		{
		printf("File not found!\n");
		goto farfinish;
		}


/* main loop */
	do
	{


/* open file */
	if ((infile=fopen(fileblock.ff_name,"rb"))==NULL) goto finish;


/* create outfile */
	fparse(fileblock.ff_name,"LBM");
	if ((outfile=fopen(filename,"wb"))==NULL) goto finish;


/* set screen mode */
	setmode(0);


/* write header information */
	writeheader();


/* set palette */
	fseek(infile,4L,SEEK_SET);
	for (colour=0;colour<(1<<screenbitplanes);colour++)
		setcolour(colour);


/* write footer information */
	writefooter();


/* load data */
	screen=0Xa0000000;
	fseek(infile,128L,SEEK_SET);
	while (screenylines--!=0)
		{
		readbuffer(infile);
		for (bitp=0;bitp<screenbitplanes;bitp++)
			{
			setbitplane(bitp);
			writebuffer(bitp,outfile);
			}
		screen+=screenxbytes;
		}

/* write length marker */
	position=ftell(outfile)-8;
	fseek(outfile,4L,SEEK_SET);
	putlong(position,outfile);

prefinish:
	fclose(outfile);

finish:
	fclose(infile);
	}

/* search for next */
	while (findnext(&fileblock)==0);


/* exit */
	setmode(99);
farfinish:
	;
	}



setmode(modenumber)
	int modenumber;

	{
	int screenmode;

	switch(modenumber)
		{
		case 0 :screenmode=13;
				screenxbytes=320/8;
				screenylines=200;
				screenbitplanes=4;
				break;
		case 99:screenmode=2;
				break;
		}
	inregs.h.al=screenmode;
	inregs.h.ah=0;
	int86(0X10,&inregs,&outregs);
	}


writeheader()

	{
	fputs("FORM    ",outfile);
	fputs("ILBMBMHD",outfile);
	putlong(0X14L,outfile);
	putint(320,outfile);	/* x width - pixels */
	putint(200,outfile);	/* y height - pixels */
	putint(0,outfile);		/* 0 ??? word */
	putint(0,outfile);		/* 0 ??? word */
	putc(4,outfile);		/* bitplanes */
	putint(1,outfile);		/* 1 ??? word */
	putint(0,outfile);		/* 0 ??? word */
	putc(15,outfile);		/* no. colours */
	putint(0X0506,outfile);	/* ??? word	*/
	putint(320,outfile);	/* x width - pixels */
	putint(200,outfile);	/* y height - pixels */

	fputs("CMAP",outfile);
	putlong(0X30L,outfile);
	}


writefooter()

	{
	int c;

	fputs("DPPV",outfile);
	putlong(0X68L,outfile);
	fpad(0X68,outfile);

	for (c=0;c<4;c++)
		{
		fputs("CRNG",outfile);
		putlong(8L,outfile);
		fpad(8,outfile);
		}

	fputs("BODY",outfile);
	putlong(32800L,outfile);
	}


putlong(number,stream)
	long int number;
	FILE *stream;

	{
	putc((number>>24),stream);
	putc((number>>16),stream);
	putc((number>>8),stream);
	putc(number,stream);
	}


putint(number,stream)
	int number;
	FILE *stream;

	{
	putc((number>>8),stream);
	putc(number,stream);
	}


setbitplane(bitplane)
	int bitplane;

	{
    outp(0X3C4,2);
	outp(0X3C5,1<<bitplane);
	}


setcolour(colour)
	int colour;

	{
	int tempvalue,portvalue=0;
	int red,green,blue;

	red=(getc(infile)<<5);
	if ((red&64)!=0) portvalue|=32;
	if ((red&128)!=0) portvalue|=4;

	tempvalue=getc(infile);
	green=((tempvalue<<1)&0XE0);
	if ((green&64)!=0) portvalue|=16;
	if ((green&128)!=0) portvalue|=2;

	blue=(tempvalue<<5);
	if ((blue&64)!=0) portvalue|=8;
	if ((blue&128)!=0) portvalue|=1;

	if (red+green+blue!=0)
		{
		red|=63;
		green|=63;
		blue|=63;
		}

	putc(red,outfile);
	putc(green,outfile);
	putc(blue,outfile);

	inp(0X3DA);
	outp(0X3C0,colour);
	outp(0X3C0,portvalue);

	inp(0X3DA);
	outp(0X3C0,0X20);
	}


fparse(infilename,ext)
	char infilename[11],ext[2];

	{
	int c;

	for (c=0;c<8;c++)
		{
		filename[c]=infilename[c];
		if ((infilename[c]=='.')|(infilename[c]==0)) break;
		}
	filename[c++]='.';
	filename[c++]=ext[0];
	filename[c++]=ext[1];
	filename[c++]=ext[2];
	while (c<12) filename[c++]=' ';
	return;
	}


readbuffer(stream)
	FILE *stream;

	{
	int c=160;

	bufferptr=filebuffer;
	while ((c--)!=0)
		*(bufferptr++)=getc(stream);
	}


writebuffer(offset,stream)
	int offset;
	FILE *stream;

	{
	int c;

	putc(39,stream);
	bufferptr=filebuffer+(2*offset);
	offset=0;
	for (c=0;c<20;c++)
		{
		putc(*bufferptr,stream);
		*(screen+offset++)=*(bufferptr++);
		putc(*bufferptr,stream);
		*(screen+offset++)=*(bufferptr++);
		bufferptr+=6;
		}
	}


fpad(c,stream)
	int c;
	FILE *stream;

	{
	while (c--!=0)
		putc(0,stream);
    }