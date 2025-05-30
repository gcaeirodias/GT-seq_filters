# GT-seq_filters
GT-seq_filters is a series of shell scripts used to identify loci from reduced representation sequencing methods compatible with the preparation of Genotyping-in-Thousands by sequencing (GT-seq) libraries. Bellow is a description of each script. Each script is presented in the order it should be used since each script uses the output of the previous script.

## Required tools
- bedtools
- samtools
- vcflib
- vcftools

## 1. identify_GT-seq_loci.sh

## 2. rescue_loci.sh

## 3. selected_loci_fasta_vcf.sh
This script uses the BED files outputed by identify_GT-seq_loci.sh and rescue_loci.sh and gets the corresponding FASTA sequence from the FASTA genome file. It also exports a VCF file with the SNPs retained for GT-seq.

## 4. fasta2primer3.sh
This script converts a FASTA file to a primer3 input TXT file. It uses the RAD loci FASTA file (all_selected_RADloci.fa) outputed by selected_loci_fasta_vcf.sh to get the sequences that will be used as template to design primers by [primer3](https://github.com/primer3-org/primer3). Only the target regions for GT-sq within the RAD loci are passed to primer3 input.
