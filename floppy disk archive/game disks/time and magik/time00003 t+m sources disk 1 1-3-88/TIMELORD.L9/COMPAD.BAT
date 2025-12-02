echo "Batch file to compile T+M for the Amstrad Disk"

copy mconstad.txt mconst.txt
copy b:timelord\ad.l9\squash.dat main.l9\
\comp
copy main.l9\gamedata.dat b:\timelord.l9\ad.l9\gamedat3.dat
copy acode.acd b:\timelord.l9\ad.l9\acode3.acd
copy acode.sml acode.acd
\finish
copy main.l9\gamedata.dat b:\timelord.l9\ad.l9\smallgd3.dat

cd \games.l9\red_moon.l9\
copy b:\ad.l9\squash.dat main.l9\
\comp
copy main.l9\gamedata.dat b:\red_moon.l9\ad.l9\gamedat3.dat
copy acode.acd b:\red_moon.l9\ad.l9\acode3.acd
copy acode.sml acode.acd
\finish
copy main.l9\gamedata.dat b:\red_moon.l9\ad.l9\smallgd3.dat

cd \games.l9\magik.l9\
copy b:\magik.l9\ad.l9\squash.dat main.l9\
\comp
copy main.l9\gamedata.dat b:\magik.l9\ad.l9\gamedat3.dat
copy acode.acd b:\magik.l9\ad.l9\acode3.acd
copy acode.sml acode.acd
\finish
copy main.l9\gamedata.dat b:\magik.l9\ad.l9\smallgd3.dat

cd \games.l9\timelord.l9\
