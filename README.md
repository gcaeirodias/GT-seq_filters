# GT-seq_filters
GT-seq_filters is a series of shell scripts used to identify loci from reduced representation sequencing methods compatible with the preparation of GT-seq libraries. Bellow is a description of each script. Each script is presented in the order it should be used since each script uses the output of the previous script.

## Required tools
bedtools
samtools
vcflib
vcftools

## 1. identify_GT-seq_loci.sh

## 2. rescue_loci.sh

## 3. selected_loci_fasta_vcf.sh
This script uses the merged BED files outputed by rescue_loci.sh and gets the corresponding FASTA sequence from the FASTA genome file. It also exports a VCF file with the SNPs retained for GT-seq.
