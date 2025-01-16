#include <osbind.h>
#include <stdio.h>
#include <portab.h>
#include <fcntl.h>
#include <dos.h>


UBYTE *names[]={
   "11",
   "10",
   "19",
   "26",
   "25",
   "24",
   "20",
   "15",
   "18",
   "8",
   "6",
   "4",
   "14",
   "12",
   "5",
   "7",
   "9",
   "23",
   "17",
   "16"
};

main()
{
   int i;
   UWORD buf[6000];
   UBYTE sec1buf[512];
   UWORD mybuff[256];
   UBYTE fname[30];
   LONG fh;
   UWORD count;
   UWORD cursect,curtrack,sect1point;
   printf("Formating second side\n");
   printf("Put double sided version in drive A:\n");
   printf("Hit any key when disc in drive B:\n");
   getch();
   for(i=0;i<80;++i)
      Flopfmt(buf,0,1,10,i,1,1,0x87654321,0xe5e5);
   printf("Format complete, copying files to side B:\n");
   curtrack=0;
   cursect=2;
   sect1point=0;
   for(i=0;i<20;++i) /* was <17 in knight orc */
   {
      strcpy(&sec1buf[sect1point],names[i]);
      sec1buf[sect1point+8]=curtrack;
      sec1buf[sect1point+9]=cursect;
      sect1point+=10;
      printf("File %s track %d sector %d\n",names[i],curtrack,cursect);
      strmfn(fname,"A","",names[i],0);
      fh=open(fname,O_RDONLY|O_RAW);
      if(fh==-1)
      {
         printf("Fatal error - restart\nCan't find %s\n",fname);
         exit();
      }
      do
      {
         count=read(fh,(UBYTE *)mybuff,512);
         if(Flopwr(mybuff,0,1,cursect,curtrack,1,1))
         {
            printf("Error while writing- Restart\n");
            exit();
         }
         ++cursect;
         if(cursect==11)
         {
            cursect=1;
            ++curtrack;
         }
      }while(count==512);
      close(fh);
   }
   sec1buf[510]=0x12;
   sec1buf[511]=0x34;
   Flopwr(sec1buf,0,1,1,0,1,1);
}
