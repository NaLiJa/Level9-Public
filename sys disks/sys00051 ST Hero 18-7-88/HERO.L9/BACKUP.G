echo "About to backup Hero to drive A - will erase floppy in drive A. "
echo "The backup process will take about 15 minutes. "
echo "I will start by checking for files on drive A. "
echo "Then, if all is clear, I will format it. "
foreach i { a:\*.* }
 echo 'VERY DANGEROUS - Files exist on Drive A!!!!!!'
 echo 'Press Return If You really want to Format Disk A. Otherwise reset machine'
 echo $<
endfor
 echo 'Ok, I will now format the disk. Press return'
 echo $<
 date >\start.dat
format -2 a
arc 'a a:\heroback.arc *.*'
arc 'a a:\heromain.arc main.l9\*.*'
 echo 'Starting time was '
 type \start.dat
 echo 'Time now is'
 date
 rm \start.dat
