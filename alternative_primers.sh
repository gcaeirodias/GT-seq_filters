#!/bin/bash

# Define variables
DIR=[path/to/working/directory]
INPUT=$DIR/[primers3_output].txt
FASTA_PREV_PRIMERS=ARS_primer_pairs_1.fa
FASTA_PREV_SINGLE_BLAST_PRIM=ARS_primer_pairs_1_singleblast.fa
PREVIOUS_PAIR=0
PRIMER_PAIR=1
PRIMER_LIST=ARS_primer_pairs_0.txt
PRIMER_LIST_SINGLE_MATCH=ARS_primer_pairs_0_singleblast.txt
PRIMER_FASTA=ARS_primer_pairs_1.fa

cd $DIR

# Define patterns corresponding to primer sequence ID in primer3 output file
echo "SEQUENCE_ID=
PRIMER_LEFT_${PRIMER_PAIR}_SEQUENCE=
PRIMER_RIGHT_${PRIMER_PAIR}_SEQUENCE=" > patterns.temp

# Search those patterns in the primer3 output (with all primers) and write each primer pair name and sequences in a single line;
# then remove loci that do not have a selected primer pair designed (index 0, 1, 2, etc.). This is done by removing lines with "SEQUENCE_ID=" but without "PRIMER"
grep -f patterns.temp $INPUT | sed ':a;N;$!ba;s/\nPRIMER_/_PRIMER_/g' | sed '/PRIMER/!d' > loci_wo_primers.temp

# Create a list of all loci with primers from previous primer number (0, 1, 2, ect.):
grep ">" $FASTA_PREV_PRIMERS | sed 's/>//' | sed "s/_PRIMER_LEFT_$PREVIOUS_PAIR//" | sed "s/_PRIMER_RIGHT_$PREVIOUS_PAIR//" | uniq > $PRIMER_LIST
# Create a list of loci whose previous primers had a single hit on the genome:
grep ">" $FASTA_PREV_SINGLE_BLAST_PRIM | sed 's/>//' | sed "s/_PRIMER_LEFT_$PREVIOUS_PAIR//" | sed "s/_PRIMER_RIGHT_$PREVIOUS_PAIR//" | uniq > $PRIMER_LIST_SINGLE_MATCH
# Intersect previous lists to retain only the loci whose previous primers had multiple hits on the genome:
grep -f $PRIMER_LIST_SINGLE_MATCH $PRIMER_LIST > get_alternative_primers.temp
grep -v -f get_alternative_primers.temp loci_wo_primers.temp > alternative_primers.temp

# Save primers in fasta format:
sed 's/_SEQUENCE=/\n/' alternative_primers.temp | sed 's/_PRIMER_LEFT/\nPRIMER_LEFT/' | sed 's/_PRIMER_RIGHT/\nPRIMER_RIGHT/' | sed 's/_SEQUENCE=/\n/'| sed 's/SEQUENCE_ID=/>/' > primers.fa.temp
grep -n ">" primers.fa.temp | tr ':' '\t' | awk '{print $1}' > line_nr.temp
a=1
b=2
c=3
d=4
rm $PRIMER_FASTA
for i in `cat line_nr.temp`
        do
	MARKER=$i
        LEFT=`expr $i + $a`
        LEFT_SEQ=`expr $i + $b`
        RIGHT=`expr $i + $c`
        RIGHT_SEQ=`expr $i + $d`
        sed -n "${MARKER}p" primers.fa.temp >> $PRIMER_FASTA
        sed -n "${LEFT}p" primers.fa.temp >> $PRIMER_FASTA
        sed -n "${LEFT_SEQ}p" primers.fa.temp >> $PRIMER_FASTA
        sed -n "${MARKER}p" primers.fa.temp >> $PRIMER_FASTA
        sed -n "${RIGHT}p" primers.fa.temp >> $PRIMER_FASTA
        sed -n "${RIGHT_SEQ}p" primers.fa.temp >> $PRIMER_FASTA
done

sed -i ':a;N;$!ba;s/\nPRIMER/_PRIMER/g' $PRIMER_FASTA
rm *.temp
