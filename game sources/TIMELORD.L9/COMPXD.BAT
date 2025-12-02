echo "Batch file to compile T+M for Atari Disk"

copy mconstxd.txt mconst.txt
copy b:\timelord.l9\xc.l9\squash.dat main.l9\
\comp
copy main.l9\gamedata.dat b:\timelord.l9\xd.l9\gamedat3.dat

cd \games.l9\red_moon.l9\
copy b:\red_moon.l9\xd.l9\squash.dat main.l9\
\comp
copy main.l9\gamedata.dat b:\red_moon.l9\xd.l9\gamedat3.dat

cd \games.l9\magik.l9\
copy b:\magik.l9\xd.l9\squash.dat main.l9\
\comp
copy main.l9\gamedata.dat b:\magik.l9\xd.l9\gamedat3.dat
