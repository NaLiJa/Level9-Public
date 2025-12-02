echo "Batch file to compile T+M for CBM Disk//Atari XL disk//CPC-PCW disk"

copy mconstcd.txt mconst.txt
copy b:\timelord.l9\cd.l9\squash.dat main.l9\
\comp
copy main.l9\gamedata.dat b:\timelord.l9\cd.l9\gamedat1.dat

cd \red_moon.l9\
copy b:\red_moon.l9\cd.l9\squash.dat main.l9\
\comp
copy main.l9\gamedata.dat b:\red_moon.l9\cd.l9\gamedat2.dat

cd \magik.l9\
copy b:\magik.l9\cd.l9\squash.dat main.l9\
\comp
copy main.l9\gamedata.dat b:\magik.l9\cd.l9\gamedat3.dat

cd \timelord.l9\
