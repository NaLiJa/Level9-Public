echo "backup all Parts of Lancelot to floppy. "
cd \games.l9\lancelt1.l9\
md a:\games.l9
md a:\games.l9\lancelt1.l9
md a:\games.l9\lancelt2.l9
md a:\games.l9\lancelt3.l9
md a:\games.l9\lancelt1.l9\main.l9
md a:\games.l9\lancelt2.l9\main.l9
md a:\games.l9\lancelt3.l9\main.l9

copy *.txt a:\games.l9\lancelt1.l9\
copy *.bat a:\games.l9\lancelt1.l9\
copy main.l9\message.txt a:\games.l9\lancelt1.l9\main.l9\

cd \games.l9\lancelt2.l9\
copy *.txt a:\games.l9\lancelt2.l9\
copy *.bat a:\games.l9\lancelt2.l9\
copy main.l9\message.txt a:\games.l9\lancelt2.l9\main.l9\

cd \games.l9\lancelt3.l9\
copy *.txt a:\games.l9\lancelt3.l9\
copy *.bat a:\games.l9\lancelt3.l9\
copy main.l9\message.txt a:\games.l9\lancelt3.l9\main.l9\
