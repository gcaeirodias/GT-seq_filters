#!/bin/bash
# Set directories and files
DIR=/users/guidias/taos-scratch/code_tests/fasta_vcf
PRIMER3_FOLDER=primer3_input
#GENOME=/users/guidias/taos-scratch/Bluntnose_shiner_genome/PBSragtag_scaffold_sort.fasta
BED_GTSEQLOCI=/users/guidias/taos-scratch/code_tests/fasta_vcf/all_selected_GTseq_loci.bed
BED_RADLOCI=/users/guidias/taos-scratch/code_tests/fasta_vcf/all_selected_RADloci.bed
#FASTA_GTSEQLOCI=all_selected_GTseq_loci.fa
FASTA_RADLOCI=/users/guidias/taos-scratch/code_tests/fasta_vcf/all_selected_RADloci.fa

# Final output (input for primer3):
OUTPUT=Nsim_2945loci_primer3_input_test.txt

################## Main script ##################
cd $DIR
mkdir -p $PRIMER3_FOLDER
cd $PRIMER3_FOLDER

# Get fasta files
#bedtools getfasta -fo $FASTA_GTSEQLOCI -fi $GENOME -bed $BED_GTSEQLOCI
#bedtools getfasta -fo $FASTA_RADLOCI -fi $GENOME -bed $BED_RADLOCI

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
