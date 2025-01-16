/* ----- */

#include <stdio.h>
#include <fcntl.h>

/* Global variables: */

char screenmap [680] ; /* Colour values for colours 1,2 */
char colourmap [680] ; /* Colour values for colour 3 */
int background ;      /* Colour value for colour 0 */

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

debug( string )
char * string ;
{ newline() ;
  prs ("DEBUG: ") ;
  prs ( string ) ;
  prs (". KEY: ") ;
  anykey() ;
  newline() ;
}

/* ----- */

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
         for ( index = 1 ; (index*10) <= number ; index *= 10 ) ;
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
/*  else inputformat = 1 ;
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
  int temphi ;
  int templo ;
  indexfrom = 340 ;
  indexto = 679 ;
  for ( ; indexfrom > 0 ; )
    { templo = (int) colourmap [ indexfrom-1 ] ;
      if ( templo < 0 ) templo = - templo ;
      temphi = (int) ( templo / 256 ) ;
      templo = templo - ( 256 * temphi ) ;
      colourmap [ indexto ] = templo ;
      indexto-- ;
      colourmap [ indexto ] = temphi ;
      indexto -- ;
      indexfrom -- ;
    }
}

unexpectedeof( string )
char * string ;
{ newline() ;
  prs ("***** ERROR: Unexpected EOF (") ;
  prs ( string ) ;
  prs (")") ;
  newline() ;
  exit ( 1 ) ;
}

junk(fp,length)
int fp ;
int length ;
{ char buffer ;
  int count ;
  for ( count=0 ; count < length; count ++ )
    if ( 1 == read ( fp , &buffer , 1 ) ) ;
    else unexpectedeof ("skip") ;
}

readattributes()
{ int fp ;
  char ch ;
  fp = open ( &inputname , (int) (O_RDONLY) ) ;
  if ( fp == -1 )
     { prs ("***** ERROR: can't re-open input *****") ;
       exit ( 2 ) ;
     }
  junk ( fp, 5440 ) ; /* Skip over pixel data */
  if ( read ( fp , screenmap , 680 ) == 680 ) ;
  else unexpectedeof ( "screen map") ;
  if ( read ( fp , colourmap , 320 ) == 320 )
       unpackcolourmap() ;
  else unexpectedeof( "colour map") ;
  if ( read ( fp , &ch , 1 ) == 1 )
       background = (int) ch ;
  else unexpectedeof("background") ;
close(fp) ;
}

/* ----- */

writebyte ( file , byte )
int file ;
int byte ;
{ char ch ;
  ch = (char) byte ;
  if ( 1 == write ( file , &ch , 1 ) ) ;
  else { prs ("***** ERROR: can't write output") ;
         exit ( 1 ) ;
       }
}

writetwobytes ( file , word )
int file ;
int word ;
{ int lobyte ;
  int hibyte ;
  hibyte = (int) ( word / 256 ) ;
  writebyte ( file , hibyte ) ;
  lobyte = word - ( 256 * hibyte ) ;
  writebyte ( file , lobyte ) ;
}

writeheader( fp )
int fp ;
{ int index ;
  writetwobytes ( fp , 0 ) ; /* Unused */
  writetwobytes ( fp , 0 ) ; /* Colour 0 */
  writetwobytes ( fp , 9 ) ; /* colour 1 */
  writetwobytes ( fp , 18 ) ; /* Colour 2 */
  writetwobytes ( fp , 27 ) ; /* Colour 3 */
  writetwobytes ( fp , 36 ) ; /* Colour 4 */
  writetwobytes ( fp , 45 ) ; /* Colour 5 */
  writetwobytes ( fp , 54 ) ; /* Colour 6 */
  writetwobytes ( fp , 63 ) ; /* Colour 7 */
  writetwobytes ( fp , 72 ) ; /* Colour 8 */
  writetwobytes ( fp , 81 ) ; /* Colour 9 */
  writetwobytes ( fp , 90 ) ; /* Colour 10 */
  writetwobytes ( fp , 99 ) ; /* Colour 11 */
  writetwobytes ( fp , 108 ) ; /* Colour 12 */
  writetwobytes ( fp , 117 ) ; /* Colour 13 */
  writetwobytes ( fp , 126 ) ; /* Colour 14 */
  writetwobytes ( fp , 135 ) ; /* Colour 15 */
  for ( index=0 ; index < 47 ; index++ )
     writetwobytes ( fp , 0 ) ;
}

writepixel( fp , value , row , column )
  int fp ;
  int value ;
  int row ;
  int column ;
{ int index ;
  int byte ;
  index = ( row * 40 ) + ( (int) (column / 4) ) ;
  if ( value = 0 )
       byte = background ;
  else if ( value = 1 )
       byte = screenmap [index] ;
  else if ( value = 2 )
       byte = (int) ( screenmap [index] / 16 ) ;
  else if ( value = 3 )
       byte = colourmap [index] ;
  else { prs ("*****ERROR: internal expansion") ;
         exit ( 2 ) ;
       } ;
  if ( byte < 0 ) byte = - byte ;
  byte = byte - 16 * ( (int) ( byte / 16 ) ) ;
  writebyte ( fp , byte * 17 ) ;
}

transform()
{ int fin ;
  int fout ;
  char ch ;
  int byte ;
  int value ;
  int index ;
  int column,row ;
  fin = open ( &inputname , (int) O_RDONLY );
  fout = creat ( &outputname , 0x8000 ) ;  /* Raw mode */
  writeheader ( fout ) ;
  column = 0 ;
  row = 0 ;
  for ( index=0 ; index < 5440 ; index++ )
     { if ( 1 == read ( fin , &ch , 1 ) )
            { if ( ( (int) ch ) < 0)
                   byte = - ( (int) ch ) ;
              else byte = (int) ch ;
              value = (int) (byte / 64) ;
              byte = byte - value * 64 ;
              writepixel ( fout , value , row , column ) ;
              value = (int) (byte / 16) ;
              byte = byte - value * 16 ;
              writepixel ( fout , value , row , column ) ;
              value = (int) (byte / 4) ;
              byte = byte - value * 4 ;
              writepixel ( fout , value , row , column ) ;
              writepixel ( fout , byte  , row , column ) ;
              column += 4 ;
              if ( column >= 160 )
                 { column = 0 ;
                   row++ ;
                 }
            }
       else unexpectedeof( "pixels" ) ;
     }
  for ( index=0 ; index < 10240 ; index ++ )
       writebyte ( fout , 0 ) ;
  close ( fin ) ;
  close ( fout ) ;
}

/* ----- */

main()
{ copyright() ;
  askfilenames() ;
  selectfiletype() ;
  readattributes() ;
  transform();
  anykey() ;
}
