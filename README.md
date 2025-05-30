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
This script uses the BED files outputed by identify_GT-seq_loci.sh and rescue_loci.sh and gets the corresponding FASTA sequence from the FASTA genome file. It also exports a VCF file with the SNPs retained for GT-seq.

## 4. fasta2primer3.sh
This script uses the reference genome in FASTA file format to obtain the sequences of each locus to be used as template to design primers for GT-seq. First it obtains two fasta files, one with the complete RAD loci sequences and another with the sequences of the GT-seq loci (target regions) that meets the the criteria to degign primers for GT-seq. Those sequences are selected based on two bed files with corresponding intervals (RAD loci and GT-seq loci).
