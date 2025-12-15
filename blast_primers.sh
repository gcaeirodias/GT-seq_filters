#!/bin/bash

# Define variables
DIR=[path/to/working/directory]
GENOME=[path/to/genome/directory/reference_genome.fasta]
DB=[path/to/blast/local/data/base/prefix]
QUERY=[primer_pairs_0].fa
BLAST_RESULTS=[primer_pairs_0_blast].txt
PRIMERS_FASTA=[primer_pairs_0_singleblast].fa

# Make local blast database
cd $DIR
makeblastdb -in $GENOME -input_type fasta -out $DB -dbtype nucl

# Make blast
blastn -task blastn-short \
  -db $DB \
  -query $QUERY \
  -perc_identity 100 \
  -outfmt "6 qseqid sseqid pident qcovs qcovhsp length mismatch gapopen qstart qend sstart send evalue bitscore" > $BLAST_RESULTS

# Select matches with 100% coverage and 100% identity:
awk '$4 == "100" && $5 == "100"' $BLAST_RESULTS > primer_blast_complete_matches.temp

# Select primers with a single match:
awk '{print $1}' primer_blast_complete_matches.temp | uniq -c | awk '$1 == "1"' > single_matches_count.temp
awk '{print $2}' single_matches_count.temp | sed 's/_/\t/2' | awk '{print $1}' | uniq -c | awk '$1 == "2"' | awk '{print $2}' > pair_single_matches_count.temp

## Select the primers with single matches from the table with the blast results:
grep -f pair_single_matches_count.temp primer_blast_complete_matches.temp > blast_single_matches.temp

## Check if those primers aligned with the righ contig in the genome by comparing query name (first part of the locus name before ':') and the column with subject (genome contig):
sed 's/:/\t/g' blast_single_matches.temp | awk '$1 == $3' | tr ' ' '\t' | sed 's/\t/:/' > blast_single_matches_correct.temp

## Save primer names in a .txt file:
awk '{print $1}' blast_single_matches_correct.temp | sed 's/^/>/' > primers_single_blast.temp

## Select the primer name ($i=NR) and the sequence (NR+1):
rm $PRIMERS_FASTA
for i in `cat primers_single_blast.temp`
       do
	awk "/$i/{print; nr[NR+1]; next}; NR in nr" $QUERY >> $PRIMERS_FASTA
done

rm *.temp
