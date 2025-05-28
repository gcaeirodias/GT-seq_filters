#!/bin/bash
set -euo pipefail  # Enable strict error handling

## Input files with validation
declare -A INPUT_FILES=(
    ["VCF"]="chr_25.recode.vcf"
    ["BAM"]="complete.bam"
    ["BED"]="chr_25_filt.bed"
)

## Verify that all input files exist
for key in "${!INPUT_FILES[@]}"; do
    if [[ ! -f "${INPUT_FILES[$key]}" ]]; then
        echo "ERROR: Input file $key (${INPUT_FILES[$key]}) not found!" >&2
        exit 1
    fi
done

## Working directory
WORKDIR="/users/guidias/taos-scratch/code_tests"
mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1

## Create a log file
LOG_FILE="loci_for_GT-seq_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Starting processing at $(date)"

## Function to identify loci compatible with GT-seq protocol
process_data() {
    local BAM="${INPUT_FILES["BAM"]}"
    local BED="${INPUT_FILES["BED"]}"
    local VCF="${INPUT_FILES["VCF"]}"

    echo "Converting RAD reads from BAM to BED..."
    bedtools bamtobed -i "$BAM" |
        awk '{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6}' > all_RADreads.bed

    echo "Processing BED file..."
    awk '{print $1"\t"$2"\t"$3}' "$BED" > mapped_loci.bed

    echo "Retaining RAD loci intersecting with filtered loci in BED file..."
    bedtools intersect -wa -a all_RADreads.bed -b mapped_loci.bed > retained_RADreads.bed

    echo "Separate RAD loci by strands..."
    bedtools merge -S + -c 6 -o collapse -i retained_RADreads.bed > forwardRADlociStrands.bed
    bedtools merge -S - -c 6 -o collapse -i retained_RADreads.bed > reverseRADlociStrands.bed

    echo "Finding loci with non-overlapping strands..."
    # For single-end data the same loci should not have forward and reverse strands.
    bedtools intersect -v -a forwardRADlociStrands.bed -b reverseRADlociStrands.bed > non-overlap_F-R_RADloci_wStrandA.bed
    bedtools intersect -v -a reverseRADlociStrands.bed -b forwardRADlociStrands.bed > non-overlap_F-R_RADloci_wStrandB.bed
    cat non-overlap_F-R_RADloci_wStrandA.bed non-overlap_F-R_RADloci_wStrandB.bed |
        awk '{print $1"\t"$2"\t"$3}' > non-overlap_F-R_RADloci.bed

    echo "Extracting loci with SNPs present in the VCF file..."
    bedtools intersect -wa -wb -a non-overlap_F-R_RADloci.bed -b "$VCF" |
        awk '{print $1"\t"$2"\t"$3"\t"$5}' |
        sort -k1,1 -k2,2n > RADloci_and_SNPs.bed
    awk '{print $1":"$2"-"$3"\t"$5}' RADloci_and_SNPs.bed > RADloci_and_SNPs.txt

    echo "Creating a list of SNPs..."
    bedtools merge -c 4 -o collapse -i RADloci_and_SNPs.bed |
        tr ',' '\t' > RADloci_SNPlist_tab.bed

    echo "Selecting loci adequate for GT-seq primer design..."
    awk 'BEGIN{OFS="\t"} {print $1,$2,$3,$4,$NF,$4-$2,$3-$NF,$NF-$4}' RADloci_SNPlist_tab.bed > SNP_distances_all_loci.bed
    awk '$8 <= 83 && $6 >= 33 && $7 >= 33' SNP_distances_all_loci.bed > max_dist_filter_SNP.bed
    awk 'BEGIN{OFS="\t"} {print $1,$2-1,$3,$4,$5,$6,$7,$8,$4-9,$5+8}' > GT-seq_good_loci.bed

    echo "Extracting the complete RAD loci and the region adequate for GT-seq..."
    awk '{print $1":"$2"-"$3"\t"$9"\t"$10}' GT-seq_good_loci.bed > selected_GT-seq_loci.bed
    awk '{print $1":"$2"-"$3"\t"$2"\t"$3}' GT-seq_good_loci.bed > selected_RADloci.bed

    echo "Loci filtering completed successfully at $(date)"
}

## Run the main function
process_data

## Cleanup temporary files
rm -f all_RADreads.bed mapped_loci.bed retained_RADreads.bed *Strands.bed *overlap*.bed RADloci_*.bed

