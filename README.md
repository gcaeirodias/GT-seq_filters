# GT-seq_filters
GT-seq_filters is a series of shell scripts used to identify loci from RADseq data compatible with the preparation of Genotyping-in-Thousands by sequencing (GT-seq) libraries. Also one script is provided to create an input file for [primer3](https://github.com/primer3-org/primer3) for further primer design for GT-seq. Bellow is a description of each script. Each script is presented in the order it should be used since each script uses the output of the previous script.

## Required tools
- bedtools
- samtools
- vcflib
- vcftools

## 1. identify_GT-seq_loci.sh
This script identifies loci that are compatible with GT-seq, following the parameters described in [Caeiro-Dias G et al. (2024)](https://doi.org/10.22541/au.173501104.41338406/v1).

### Usage
There are four variables containing the path to working directory and names of files needed to identify loci compatible with GT-seq. Those common files resulting from most pipelines used to identify SNPs from RADseq data (or other similar reduced representation sequencig methods).
~~~
DIR=[working directory]
        Path to working directory containing the input files.

["VCF"]=[original].vcf
        A VCF file containing the filtered SNPs identified from RADseq data from wich to identify loci compatible with GT-seq.

["BAM"]=[original].bam
        A BAM file containing the filtered alignments obtained from RADseq data for all individuals used to call variants from wich SNPs were identified.

["BED"]=[original].bed
        A BED file containing all the RAD loci intervals that have SNPs identified, i.e., the SNPs in the [original].vcf file.
~~~

## 2. rescue_loci.sh

## 3. selected_loci_fasta_vcf.sh
This script uses the BED files outputed by identify_GT-seq_loci.sh and rescue_loci.sh and gets the corresponding FASTA sequence from the FASTA genome file. It also exports a VCF file with the SNPs retained for GT-seq.

### Usage
There are seven variables containing the path to working directory and names of files used by selected_loci_fasta_vcf.sh that should be modified accordingly. This script can be run from the directory containing the outputs from identify_GT-seq_loci.sh and rescue_loci.sh. 
~~~
DIR=[path working directory]
        Path to working directory.

GENOME=[genome].fasta
        FASTA file (and path if needed) containing the genome used as reference to identify SNPs from RADseq data.
 
RECOV_RADLOCI=recovered_RADloci.bed
        BED file containing the recovered RAD loci intervals. Outputed by rescue_loci.sh.

RECOV_GTSEQLOCI=recovered_GTseq_loci.bed
        BED file containing the recovered intervals compatible with GT-seq (GT-seq loci). Outputed by rescue_loci.sh.

SELEC_RADLOCI=selected_RADloci.bed
        BED file containing the originally identified RAD loci intervals containing region adequate for GT-seq. Outputed by identify_GT-seq_loci.sh.
        
SELEC_GTSEQLOCI=selected_GTseq_loci.bed
        BED file containing the originally identified region adequate for GT-seq. Outputed by identify_GT-seq_loci.sh.

VCF=[original].vcf
        VCF file containing the original filtered SNPs from RADseq data. 
~~~

## 4. fasta2primer3.sh
This script converts a FASTA file to a primer3 input TXT file. It uses the RAD loci FASTA file (all_selected_RADloci.fa) outputed by selected_loci_fasta_vcf.sh to get the sequences that will be used as template to design primers by primer3. Only the target regions for GT-sq within the RAD loci are passed to primer3 input.

### Usage
There are six variables containing the path to working directory and names of files used by fasta2primer3.sh that should be modified accordingly. This script can be run from the directory containing the outputs from selected_loci_fasta_vcf.sh. 
~~~
DIR=[path working directory]
        Path to working directory.

PRIMER3_FOLDER=primer3_input
        Name a folder that will be created where to save the output.

BED_GTSEQLOCI=all_selected_GTseq_loci.bed
        Name (and path if needed) of the BED file containing the intervals corresponding to filtered RAD loci (target regions) that can be used for GT-seq (GT-seq loci). Outputed by selected_loci_fasta_vcf.sh.

BED_RADLOCI=all_selected_RADloci.bed
        Name (and path if needed) of the BED file containing the intervals corresponding to RAD loci. Outputed by selected_loci_fasta_vcf.sh.

FASTA_RADLOCI=all_selected_RADloci.fa
        Name (and path if needed) of the FASTA file containing the intervals corresponding to RAD loci. Outputed by selected_loci_fasta_vcf.sh.

OUTPUT=[primer3_input].txt
        Name of the output files. This is a TXT file that will be used as input for primer3.
~~~

## Citation
If you use any of these scripts included on GT-seq_filters, please cite the pre-print where GT-seq_filters was first published, while the article is in review: [Caeiro-Dias G, Osborne MJ, Turner TF. Time is of the essence: using archived samples in the development a GT-seq panel to preserve continuity of ongoing genetic monitoring. Authorea. December 24, 2024.](https://doi.org/10.22541/au.173501104.41338406/v1). 

## Contact
Send your questions, suggestions, or comments to gcaeirodias@unm.edu
