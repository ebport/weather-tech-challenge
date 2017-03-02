#!/bin/bash
# Bash Scripting Tech Challenge - https://captechventuresinc.sharepoint.com/sites/SO/DI/Pages/Tech-Challenges.aspx
# Store arguments in array
args=("@")
echo $@ $#

WORKDIR=$1
OUTPUTDIR=$2

# create working and output directories if they don't exist 
mkdir -p $WORKDIR $OUTPUTDIR

echo working: $WORKDIR output: $OUTPUTDIR

datapath="https://www1.ncdc.noaa.gov/pub/data/uscrn/products/hourly02/updates/2017/"
echo $datapath

# download most recent stations data to working directory
wget -P $WORKDIR/ http://www1.ncdc.noaa.gov/pub/data/uscrn/products/stations.tsv 

# download most recent hourly data TODO: testing of this if/else
base=https://www1.ncdc.noaa.gov/pub/data/uscrn/products/hourly02/updates/2017/
file_pre=CRN60H0203-
curr_suffix=$(date -u +%Y%m%d%H00).txt
prev_suffix=$(date -d "1 hour ago" -u +%Y%m%d%H00).txt
if wget --spider $base$file_pre$curr_suffix 2>/dev/null; then # Does this line actually function?
  file=$file_pre$curr_suffix; 
else
  file=$file_pre$prev_suffix;
  echo used previous;
fi

wget -P $WORKDIR/ $base$file
echo file $file
stat ./working/stations.tsv | grep 'Modify: ' | cut -d' ' -f2,3,4 > $WORKDIR/ts.txt

# Write bad and good records fields 9-12 TODO: Output to working dir
good=$WORKDIR'/good-records.txt'
bad=$WORKDIR'/bad-records.txt'

gawk -v good=$good -v bad=$bad '{ if ($13==-9999.0 || $10==-9999.0 || $11==-9999.0 || $12==-9999.0) print $0 > bad; else print $0 > good }' $WORKDIR/$file

# tranform records - join on station info http://unix.stackexchange.com/questions/43417/join-two-files-with-matching-columns
# join - also pure awk solution that uses join key as key in associative array (dictionary) storing necessary data as value
awk -v OFS=, '{ print $1,$2,$3,$10,$11,$4,$5,$12,$6,$7,$8,$9 }' <(join <(sort <(awk '{ print $1,$2,$3,$7,$8,$10,$11,$12,$13 }' $WORKDIR/good-records.txt)) <(sort <(awk -F'\t' '{ print $1,$2,$3,$9 }' $WORKDIR/stations.tsv))) > $WORKDIR/output-data.csv

# Zip up all output into output dir
outputfile=$(sed 's/[-:]//g' $WORKDIR/ts.txt | cut -d'.' -f1 | tr " " "-")
zip ./$OUTPUTDIR/$outputfile.zip ./$WORKDIR/{output-data.csv,good-records.txt,bad-records.txt,$file}

# clean up working dir
rm -r $WORKDIR

