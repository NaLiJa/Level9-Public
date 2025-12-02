echo "Batch file to compile all parts of Knight Orc for the Amstrad. "

echo "compiling part 1. "
cd \games.l9\knight1.l9\
copy mconstad.txt mconst.txt
copy exit8.txt exit.txt
\comp
copy amstrad.l9\gamedata.dat \games.l9\knight2.l9\amstrad.l9\gamedat1.dat
copy acode.acd \games.l9\knight2.l9\amstrad.l9\acode1.acd
copy acode.sml acode.acd
cd \games.l9\knight1.l9\
\finish
copy amstrad.l9\gamedata.dat \games.l9\knight2.l9\amstrad.l9\smallgd1.dat

echo "compiling hitech. "
cd \games.l9\knight2.l9\dat amstrad.l9\biggd3.dat
copy acode.acd amstrad.l9\acode3.acd
copy acode.sml acode.acd
cd \games.l9\knight2.l9\
\finish
copy amstrad.l9\gamedata.dat amstrad.l9\smallgd3.dat
copy amstrad.l9\biggd3.dat amstrad.l9\gamedat3.dat

era amstrad.l9\biggd2.dat
era amstrad.l9\biggd3.dat
ееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееееdat amstrad.l9\biggd3.dat
copy acode.acd amstrad.l9\acode3.acd
copy acode.sml acode.acd
cd \games.l9\knight2.l9\
\finish
copy amstrad.l9\gamedata.dat amstrad.l9\smallgd3.dat
copy amstrad.l9\biggd3.dat amstrad.l9\gamedat3.dat

era amstrad.l9\biggd2.dat
era amstrad.l9\biggd3.dat
