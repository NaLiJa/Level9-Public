echo "Batch file to compile T+M for MSX Cassette"

copy mconstmsx.txt mconst.txt
copy b:\timelord.l9\st.l9\squash.dat main.l9\
\comp
copy main.l9\gamedata.dat b:\timelord.l9\msx.l9\gamedat3.dat

cd \games.l9\red_moon.l9\
copy b:\red_moon.l9\st.l9\squash.dat main.l9\
\comp
copy main.l9\gamedata.dat b:\red_moon.l9\msx.l9\gamedat3.dat

cd \games.l9\magik.l9\
copy b:\magik.l9\st.l9\squash.dat main.l9\
\comp
copy main.l9\gamedata.dat b:\magik.l9\msx.l9\gamedat3.dat

cd \games.l9\timelord.l9\
