/* ----- */

#include <stdio.h>
#include <fcntl.h>

/* Global variables: */

char screenmap [680] ; /* Colour values for colours 1,2 */
char colourmap [680] ; /* Colour values for colour 3 */

char inputname[80] ;   /* File name/type for CBM file */
char outputname[80] ;  /* File name/type for NEO file */

int inputformat ;      /* Non-zero for full-screen */

int header ;           /* = 1 if input has 128-byte AMSDOS header */

/* ----- */

prs(string)
char *string ;
{ for ( ; *string > '\0' ; )
  { putch ( *string ) ;
    string ++ ;
  }
}

newline()
{ prs("\n") ;
}

anykey()
{ newline() ;
  prs("Press any key to continue:");
  for ( ; kbhit() > 0 ; ) ;
  getch() ;
}


getfilename(name)
char * name [80] ;
{ for ( name[0] = '\0' ; name[0] == '\0' ; ) gets(name) ;
}

displaydecimal(number)
int number ;
{ int digit ;
  if ( number == 0 )
       prs ("0") ;
  else { int index ;
         for ( index = 1 ; (index*10) < number ; index *= 10 ) ;
         for ( ; index > 0 ; )
           { digit = (int) ( number / index ) ;
             putch ( (char) (48 + digit) ) ;
             number = number - ( digit * index ) ;
             index = (int) (index / 10) ;
           }
       }
}

/* ----- */

copyright()
{ newline() ;
  prs("CBM 64 picture to ST/NEO format.") ;
  newline() ;
  newline() ;
  prs("Copyright (C) 1987 Level 9") ;
  newline() ;
}


int _iomode = 0X8000 ;

askfilenames()
{ int exists ;
  int fp ;
  for ( exists=0 ; exists == 0 ; )
    { newline() ;
      prs ("Input file (CBM 64/CBM Art Studio format) ? ") ;
      getfilename(&inputname) ;
      newline() ;
      fp = open ( &inputname , (int) (O_RDONLY) ) ;
      if ( fp == -1 )
           { prs ("File not found") ;
             newline() ;
           }
      else { exists = 1 ;
             close ( fp ) ;
           }  
    }

  newline() ;
  selectheader() ;
  newline() ;
  prs ("Output file (NEO format) ? ") ;
  getfilename(&outputname) ;
}

/* ----- */

selectfiletype()
{ /* newline() ;
  prs ("A. CBM 64 Art studio format.") ;
  newline() ;
  prs ("B. CBM 64 KAOS (Smallpic) format.") ;
  newline() ;
  prs ("Choose: ") ;
  for ( ch = getch() ; (ch == 'a') || (ch == 'b') ||
                       (ch == 'A') || (ch == 'B') ; ) ;
  if (ch == 'a') || (ch == 'A') */
       inputformat = 0 ;
  /* else inputformat = 1 ;
  newline() ; */
}


selectheader()
{ char input[80] ;
  int index ;
  for ( header = 3 ; (header == 3) || (header == 0) ; )
    { prs ("Remove AMSDOS header ((Y/N) ? ");
      gets(input) ;
      for ( index=0 ; (index == 79) || (header == 3) ; )
         { header = 0 ;
           if ( input[index] == 'y' ) header = 1 ;
           if ( input[index] == 'Y' ) header = 1 ;
           if ( input[index] == 'n' ) header = 2 ;
           if ( input[index] == 'N' ) header = 2 ;
           if ( input[index] == ' ' ) header = 3 ;
           index ++ ;
         }
    }
}

/* ----- */

unpackcolourmap()
{ int indexfrom ;
  int indexto ;
  int temp ;
  indexfrom = 339 ;
  indexto = 679 ;
  for ( ; indexfrom > 0 ; )
    { temp = colourmap [ indexfrom ] ;
      colourmap [ indexto ] = temp && 0x00ff ;
      indexto-- ;
      colourmap [ indexto ] = ( temp >> 8 ) && 0X00ff ;
      indexto -- ;
      indexfrom ++ ;
    }
}

junk(fp,length)
int fp ;
int length ;
{ char buffer ;
  int count ;
  for ( count=0 ; count < length; count ++ )
    if ( 1 == read ( fp , &buffer , 1 ) ) ;
    else prs ("***** ERROR: unexpected EOF") ;
}

readattributes()
{ int fp ;
  fp = open ( &inputname , (int) (O_RDONLY) ) ;
  if ( fp == -1 )
     prs ("***** ERROR: can't open input *****") ;
  junk ( fp, 5440 ) ; /* Skip over pixel data */
  if ( read ( fp , screenmap , 680 ) == 680 ) ;
  else prs ("***** ERROR: Can't read screen map *****") ;
  if ( read ( fp , colourmap , 320 ) == 320 )
       unpackcolourmap() ;
  else prs ("***** ERROR: Can't read colour map *****") ;
  close(fp) ;  
}

/* ----- */

main()
{ copyright() ;
  askfilenames() ;
  selectfiletype() ;
  readattributes() ;
  anykey() ;
}
