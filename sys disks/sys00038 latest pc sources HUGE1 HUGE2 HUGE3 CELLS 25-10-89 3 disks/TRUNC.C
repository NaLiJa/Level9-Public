#include <stdio.h>
#include <dos.h>
#include <dir.h>
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <io.h>

/*--------------------*/

#define SectorSize 1024
#define NumSectors 712

main(argc,argv)
	int argc;
	char **argv;

{	int sector,sourcefile,destfile;
	char SectorBuffer[SectorSize];

	sourcefile = open("SPRITES1.DAT",O_BINARY+O_RDONLY)	;/*file handle*/
	destfile   = _creat("SPRITES.DAT",FA_ARCH)			;/*file handle*/

	for (sector=0; sector<NumSectors; sector++)
		{	printf("%u/n",sector);
			read(sourcefile,SectorBuffer,SectorSize);
			write(destfile,SectorBuffer,SectorSize);
		}

	close (sourcefile);
	close (destfile);

}


/*--------------------*/


/*--------------------*/

/*--------------------*/

/*--------------------*/


int ReadFile(FileName,Address,Length)
	char *FileName, *Address;
	int Length;
{
	int handle;

	handle = open(FileName,O_BINARY+O_RDONLY) ;	/*file handle*/
    if (handle != -1)
    {
    	if ( read(handle,Address,Length) != Length)
    		 {
        		close(handle);
			handle=-1; /*error*/
			 }
    	else {	close(handle);
       			handle=0;
        	 }

    }
	return(handle);
}

/*--------------------*/

int WriteFile(FileName,Address,Length)
	char *FileName, *Address;
	int Length;
{
	int handle;

	handle = _creat(FileName,FA_ARCH) ;	/*file handle*/
    if (handle != -1)
    {
		if ( write(handle,Address,Length) != Length)
    		 {
        		close(handle);
            	handle=-1; /*error*/
			 }
    	else {	close(handle);
       			handle=0;
        	 }

    }
	return(handle);
}

/*--------------------*/
