#!/bin/bash

## Configuration
DIR=[working directory]
DISCARD_DIRS=("discarded_1st_batch" "discarded_2nd_batch")
MAX_DISTANCE=83
MIN_EXTREME=33
PRIMER_BUFFER=8

## Functions
# Function to process discarded loci
process_discarded_loci() {
    local dir=$1
    local input_bed=$2
    local is_first_batch=$3

    mkdir -p $dir

    # For first batch only, create the initial discarded loci files
    if [ "$is_first_batch" = true ]; then
        # Select loci with max distance between SNP higher than threshold
        awk -v max_dist=$MAX_DISTANCE '$8 > max_dist {print $1,$2,$3}' SNP_distances_all_loci.bed | tr ' ' '\t' > $dir/hig_max_dist_filter_SNP.bed

        # Select loci with good distance but without required buffer at extremes
        awk -v min_ext=$MIN_EXTREME '$6 < min_ext || $7 < min_ext {print $1,$2,$3}' max_dist_filter_SNP.bed | tr ' ' '\t' > $dir/SNPs_within_extremes_filter.bed

        # Merge both files with discarded loci
        cat $dir/hig_max_dist_filter_SNP.bed $dir/SNPs_within_extremes_filter.bed | sort -s -n -k1,1 > $dir/discarded_loci.bed
        input_bed=$dir/discarded_loci.bed
    fi
    
    # Extract the loci and SNP list from the bed file
    bedtools intersect -wa -a $DIR/RADloci_SNPlist_tab.bed -b $dir/discarded_loci.bed > $dir/discarded_RADloci_SNPlist.bed
    tr ',' '\t' < $dir/discarded_RADloci_SNPlist.bed > $dir/discarded_RADloci_SNPlist_2.bed

    # Process by excluding last and first SNPs
    process_excludedSNPs "$dir" "last"
    process_excludedSNPs "$dir" "first"

    # Merge and filter results
    merge_and_filter_results "$dir"
}

# Function to process SNP exclusions
process_excludedSNPs() {
    local dir=$1
    local exclusion=$2

    # Create file with excluded SNP
    if [ "$exclusion" = "last" ]; then
        awk '{$NF=""; print $0}' $dir/discarded_RADloci_SNPlist_2.bed | tr ' ' '\t' > $dir/discarded_RADloci_SNPlist_exclude_${exclusion}.bed
    else
        awk '{$4=""; print $0}' $dir/discarded_RADloci_SNPlist_2.bed | tr ' ' '\t' > $dir/discarded_RADloci_SNPlist_exclude_${exclusion}.bed
    fi

    # Extract basic columns
    awk '{print $1,$2,$3,$4,$NF}' $dir/discarded_RADloci_SNPlist_exclude_${exclusion}.bed | tr ' ' '\t' > $dir/rescued_loci_ex${exclusion}1.bed

    # Calculate distances
    awk -v min_ext=$MIN_EXTREME -v max_dist=$MAX_DISTANCE \
        '{print $1,$2,$3,$4,$5,$4-$2,$3-$5,$5-$4}' $dir/rescued_loci_ex${exclusion}1.bed | tr ' ' '\t' > $dir/rescued_loci_ex${exclusion}2.bed

    # Filter by maximum distance
    awk -v max_dist=$MAX_DISTANCE '$8 <= max_dist' $dir/rescued_loci_ex${exclusion}2.bed | tr ' ' '\t' > $dir/rescued_loci_ex${exclusion}3.bed

    # Remove loci with a single SNP (negative distances)
    awk '$8 >= 0' $dir/rescued_loci_ex${exclusion}3.bed | tr ' ' '\t' > $dir/rescued_loci_ex${exclusion}4.bed
}

# Function to merge and filter results
merge_and_filter_results() {
    local dir=$1

    # Find unique and common loci between last and first exclusions
    awk 'NR==FNR{a[$1,$2,$3];next}!(($1,$2,$3) in a)' $dir/rescued_loci_exlast4.bed $dir/rescued_loci_exfirst4.bed > $dir/unique_exfirst.bed
    awk 'NR==FNR{a[$1,$2,$3];next}!(($1,$2,$3) in a)' $dir/rescued_loci_exfirst4.bed $dir/rescued_loci_exlast4.bed > $dir/unique_exlast.bed

    awk 'FNR==NR {a[$1,$2,$3]=$0; next}; (($1,$2,$3) in a) {print a[$1,$2,$3]}' $dir/rescued_loci_exlast4.bed $dir/rescued_loci_exfirst4.bed > $dir/exlast.bed
    awk 'FNR==NR {a[$1,$2,$3]=$0; next}; (($1,$2,$3) in a) {print a[$1,$2,$3]}' $dir/rescued_loci_exfirst4.bed $dir/rescued_loci_exlast4.bed > $dir/exfirst.bed

    # Merge files with rescued loci
    cat $dir/unique_exlast.bed $dir/unique_exfirst.bed $dir/exlast.bed | sort > $dir/rescued_loci_1-1.bed
    cat $dir/unique_exlast.bed $dir/unique_exfirst.bed $dir/exfirst.bed | sort > $dir/rescued_loci_1-2.bed

    # Filter by extreme distances
    awk -v min_ext=$MIN_EXTREME '$6 >= min_ext && $7 >= min_ext' $dir/rescued_loci_1-1.bed | sort -s -n -k1,1 > $dir/rescued_loci_2-1.bed
    awk -v min_ext=$MIN_EXTREME '$6 >= min_ext && $7 >= min_ext' $dir/rescued_loci_1-2.bed | sort -s -n -k1,1 > $dir/rescued_loci_2-2.bed

    # Find unique and common between the two filtered sets
    awk 'NR==FNR{a[$1,$2,$3];next}!(($1,$2,$3) in a)' $dir/rescued_loci_2-2.bed $dir/rescued_loci_2-1.bed > $dir/unique_2-1.bed
    awk 'NR==FNR{a[$1,$2,$3];next}!(($1,$2,$3) in a)' $dir/rescued_loci_2-1.bed $dir/rescued_loci_2-2.bed > $dir/unique_2-2.bed
    awk 'FNR==NR {a[$1,$2,$3]=$0; next}; (($1,$2,$3) in a) {print a[$1,$2,$3]}' $dir/rescued_loci_2-1.bed $dir/rescued_loci_2-2.bed > $dir/rescued_commom.bed

    # Final merge and sort
    cat $dir/unique_2-1.bed $dir/unique_2-2.bed $dir/rescued_commom.bed | sort -n -k1,1 -k2,2 -k3,3 > $dir/rescued_loci_2.bed

    # Create final output files with adjusted coordinates
    awk -v buffer=$PRIMER_BUFFER '{print $1,$2-1,$3,$4,$5,$6,$7,$8,$4-9,$5+buffer}' $dir/rescued_loci_2.bed | tr ' ' '\t' > $dir/rescued_loci_3.bed

    awk '{print $1,$9,$10}' $dir/rescued_loci_3.bed | tr ' ' '\t' > $dir/rescued_loci_interest_region.bed
    awk '{print $1,$2,$3}' $dir/rescued_loci_3.bed | tr ' ' '\t' > $dir/rescued_interest_radtags.bed

    # Validation checks
     awk -v max_dist=$MAX_DISTANCE '$NF < 0 || $8 > max_dist-1' $dir/rescued_loci_2.bed | tr ' ' '\t' > $dir/check_rescued1
    awk -v min_ext=$MIN_EXTREME '$6 < min_ext || $7 < min_ext' $dir/rescued_loci_2.bed | tr ' ' '\t' > $dir/check_rescued2
}

## Main Execution
cd $DIR

# Process first batch
process_discarded_loci "${DISCARD_DIRS[0]}" "" true

# Process second batch
awk 'NR==FNR{a[$1,$2,$3];next}!(($1,$2,$3) in a)' ${DISCARD_DIRS[0]}/rescued_loci_2.bed ${DISCARD_DIRS[0]}/discarded_loci.bed > ${DISCARD_DIRS[1]}/discarded_2nd_batch.bed
process_discarded_loci ${DISCARD_DIRS[1]} ${DISCARD_DIRS[1]}/discarded_2nd_batch.bed false

# If needed, more batches of discarded loci can be processed similarly to "Process second batch" section above.

# Merge all results
cat ${DISCARD_DIRS[0]}/rescued_GTseq_loci.bed \
    ${DISCARD_DIRS[1]}/rescued_GTseq_loci.bed | \
    sort -n -k1,1 -k2,2 -k3,3 | awk '{print $1,$2,$3}' | tr ' ' '\t' > recovered_GTseq_loci.bed

cat ${DISCARD_DIRS[0]}/rescued_RADloci.bed \
    ${DISCARD_DIRS[1]}/rescued_RADloci.bed | \
    sort -n -k1,1 -k2,2 -k3,3 | awk '{print $1,$2,$3}' | tr ' ' '\t' > recovered_RAD_loci.bed
