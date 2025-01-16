#include <stdio.h>

dummy(j)
{
 ++j;
 return(j);
}

main()
{

 register i,j;

 printf("\ntype return to start ");

 i=0;
 j=0;
 getch(i);

 for(i=0;i<50001;++i) j=dummy(j);

 printf("\n stop timing!");

 j=dummy(j);
 dummy(j);

 printf ("\n final j is %d",j);
 getch();
 return(i);
}


