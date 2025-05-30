#!/bin/bash
# Directories and files
DIR=[path to working directory]
GENOME=[genome].fasta
RECOV_RADLOCI=recovered_RADloci.bed
RECOV_GTSEQLOCI=recovered_GTseq_loci.bed
SELEC_RADLOCI=selected_RADloci.bed
SELEC_GTSEQLOCI=selected_GTseq_loci.bed
VCF=[original].vcf

# Set working directory
cd $DIR || exit

# Merge BED files created by identify_GT-seq_loci.sh and rescue_loci.sh scripts and sort them
merge_and_sort() {
    local output=$1
    shift
    cat "$@" | sort -n -k1,1 -k2,2 -k3,3 | awk '{print $1,$2,$3}' | tr ' ' '\t' > "$output"
}

merge_and_sort all_selected_GTseq_loci.bed $SELEC_GTSEQLOCI $RECOV_GTSEQLOCI
merge_and_sort all_selected_RADloci.bed $SELEC_RADLOCI $RECOV_RADLOCI

# Get FASTA sequences from genome FASTA file
for file in "all_selected_RADloci" "all_selected_GTseq_loci"; do
    bedtools getfasta -fo "${file}.fa" -fi $GENOME -bed "${file}.bed"
done

# Get SNPs retained in the GT-seq loci from original VCF file
sed -e '1i\chrom\tchromStart\tchromEnd' all_selected_GTseq_loci.bed > all_selected_RADloci_header.bed
vcftools --vcf $VCF --bed all_selected_RADloci_header.bed --recode --recode-INFO-all --out SNPs_all_selected_GT-seq_loci
