#!/bin/bash
# Set directories and files
DIR=[working_directory]
PRIMER3_FOLDER=primer3_input
BED_GTSEQLOCI=all_selected_GTseq_loci.bed
BED_RADLOCI=all_selected_RADloci.bed
FASTA_RADLOCI=all_selected_RADloci.fa
OUTPUT=[primer3_input].txt

cd $DIR
mkdir -p $PRIMER3_FOLDER
cd $PRIMER3_FOLDER

# Identify target ranges to be sequenced by GT-seq to pass to Primer3 input
awk 'NR==FNR {
    rad_start[$1]=$2; rad_end[$1]=$3; next
}
$1 in rad_start {
    start = $2 - rad_start[$1] + 1
    end = $3 - rad_start[$1] + 1
    print start "," end - start + 1
}' $BED_RADLOCI $BED_GTSEQLOCI > target_ranges.tmp

# Create Primer3 input file
awk -v ranges="$(paste -s -d '|' target_ranges.tmp)" '
BEGIN { split(ranges, a, "|"); i=1 }
/^>/ {
    print "SEQUENCE_ID=" substr($0, 2)
    getline seq
    print "SEQUENCE_TEMPLATE=" seq
    print "SEQUENCE_TARGET=" a[i++]
    print "="
}' $FASTA_RADLOCI > $OUTPUT

# Cleanup
rm target_ranges.tmp
