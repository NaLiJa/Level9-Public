/*	L9DISK.C  */

#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <io.h>

/*--------------------*/

L9ParseFileName(InFileName,OutFileName)
	char InFileName[80],OutFileName[80];
{
	int Index,FoundDot;
	char c;

	Index=0;
	FoundDot=0;

	for (Index=0; Index<80; Index++)
	{
		c=InFileName[Index];
		if (c=='\0') break;			/* end of input */
		if (c=='\\') FoundDot=0;	/* directory, so restart search */
		if (c=='.')	 FoundDot=1;	/* extension specified */
		OutFileName[Index]=c;
	}

	if (FoundDot==0)				/* No extension, so add default */
	{
		OutFileName[Index++]='.';
		OutFileName[Index++]='N';
		OutFileName[Index++]='E';
		OutFileName[Index++]='O';
	}
}

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