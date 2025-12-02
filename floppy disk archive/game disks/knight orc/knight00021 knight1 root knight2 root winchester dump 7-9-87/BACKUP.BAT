echo "; Batch file to backup Knight Orc part 1"
md b:\games.l9
md b:\games.l9\knight1.l9
md b:\games.l9\knight1.l9\st.l9

copy \games.l9\knight1.l9\*.* b:\games.l9\knight1.l9\
copy \games.l9\knight1.l9\st.l9\squash.dat b:\games.l9\knight1.l9\st.l9\
copy \games.l9\knight1.l9\st.l9\message.txt b:\games.l9\knight1.l9\st.l9\
copy \games.l9\knight1.l9\st.l9\picture.dat b:\games.l9\knight1.l9\st.l9\
