\comp.prg
era main.l9\gamedat1.dat
ren main.l9\gamedata.dat main.l9\gamedat1.dat

echo "compile part 2. "
cd \games.l9\lancelt2.l9\
copy \games.l9\lancelt1.l9\table.dat
copy \games.l9\lancelt1.l9\exit.txt
\comp
copy main.l9\gamedata.dat \games.l9\lancelt1.l9\main.l9\gamedat2.dat
era table.dat
era exit.txt
cd \games.l9\lancelt1.l9\

echo "compile part 3. "
cd \games.l9\lancelt3.l9\
\comp
copy main.l9\gamedata.dat \games.l9\lancelt1.l9\main.l9\gamedat3.dat
cd \games.l9\lancelt1.l9\
