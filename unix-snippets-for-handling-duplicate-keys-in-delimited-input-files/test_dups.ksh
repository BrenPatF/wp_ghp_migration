INFILE1_2=test_dups_in_1_2.dat
OUTFILE1_2=$INFILE1_2.cln

INFILE1_3=test_dups_in_1_3.dat
OUTFILE1_3=$INFILE1_3.cln
WRKFILE1=/tmp/temp1.txt
WRKFILE2=/tmp/temp2.txt

echo "k91|k92|a1|k41|k42|a
k11|k12|a1|k41|k42|b
k41|k42|a4x|k41|k42|c
k21|k22|a2|k41|k42|d
k41|k42|a4|k41|k42|c
k41|k42|a4|k41|k42|c
k11|k12|a1|k41|k42|b" > $INFILE1_2

echo $INFILE1_2 with the 2 leading fields key ....
cat $INFILE1_2

echo
echo List the distinct keys that have duplicates
sort $INFILE1_2 | awk -F"|" '	$1$2 == last_key && !same_key {print $1"|"$2; same_key=1} $1$2 != last_key {same_key=0; last_key=$1$2}'

echo
echo List all lines for duplicate keys
sort $INFILE1_2 | awk -F"|" ' 
$1$2 == last_key && !same_key {print last_line; same_key=1} 
$1$2 == last_key {print $0; same_key=1} 
$1$2 != last_key {same_key=0; last_key=$1$2; last_line=$0}'

echo
echo Strip all lines with duplicate keys from the file, returning unsorted lines
dup_list=`sort $INFILE1_2 | awk -F"|" '
$1$2 == last_key && !same_key {print $1"|"$2; same_key=1}
$1$2 != last_key {same_key=0; last_key=$1$2}'`
cp $INFILE1_2 $OUTFILE1_2; for i in $dup_list; do grep -v ^$i $OUTFILE1_2 > $WRKFILE1; mv $WRKFILE1 $OUTFILE1_2; done
cat $OUTFILE1_2

echo
echo Strip the inconsistent duplicates from the file, returning unique sorted lines
dup_list=`sort -u $INFILE1_2 | awk -F"|" '
$1$2 == last_key && !same_key {print $1"|"$2; same_key=1}
$1$2 != last_key {same_key=0; last_key=$1$2}'`
sort -u $INFILE1_2 > $OUTFILE1_2; for i in $dup_list; do grep -v ^$i $OUTFILE1_2 > $WRKFILE1; mv $WRKFILE1 $OUTFILE1_2; done
cat $OUTFILE1_2

echo
echo Swap fields 2 and 3 so that the key fields are not leading
awk -F"|" '  {print $1"|"$3"|"$2"|"$4"|"$5"|"$6}' $INFILE1_2 > $INFILE1_3

echo $INFILE1_3 with fields 1 and 3 key ....
cat $INFILE1_3

echo
echo Strip the inconsistent duplicates from the file, returning unique sorted lines - key fields not leading

awk -F"|" '{print $1"|"$3"|"$2"|"$4"|"$5"|"$6}' $INFILE1_3 | sort -u > $WRKFILE1
dup_list=`awk -F"|" ' $1$2 == last_key && !same_key {print $1"|"$2; same_key=1} $1$2 != last_key {same_key=0; last_key=$1$2}' $WRKFILE1`
for i in $dup_list; do grep -v ^$i $WRKFILE1 > $WRKFILE2; mv $WRKFILE2 $WRKFILE1; done
awk -F"|" '  {print $1"|"$3"|"$2"|"$4"|"$5"|"$6}' $WRKFILE1 > $OUTFILE1_3

echo $OUTFILE1_3 ....
cat $OUTFILE1_3


