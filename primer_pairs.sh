#!/bin/bash

# Define varaiables
DIR=[path/to/working/directory]
INPUT="${WORK_DIR}/primer3_output.txt"
PRIMER_PAIR=0
FASTA="${WORK_DIR}/primer_pairs_${PRIMER_PAIR}.fa"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

cd "$INPUT_DIR"
# Check if input file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: Input file not found: $INPUT_FILE" >&2
    exit 1
fi

# Define patterns corresponding to primer sequence ID in primer3 output file
PATTERNS="SEQUENCE_ID=
PRIMER_LEFT_${PRIMER_PAIR}_SEQUENCE=
PRIMER_RIGHT_${PRIMER_PAIR}_SEQUENCE="

# Extract primer pair sequences from primer3 output file
awk -v pair="$PRIMER_PAIR" '
BEGIN {
    # Patterns to search for
    patterns["SEQUENCE_ID"] = 1
    patterns["PRIMER_LEFT_"pair"_SEQUENCE"] = 1
    patterns["PRIMER_RIGHT_"pair"_SEQUENCE"] = 1
    # Variables
    seq_id = ""
    left_primer = ""
    right_primer = ""
}
# Function to process lines containing previously defined patterns
function process_line(line) {
    split(line, parts, "=")
    key = parts[1]
    value = parts[2]
    if (key == "SEQUENCE_ID") {
        # If primer sequences exist, output it
        if (seq_id != "" && left_primer != "" && right_primer != "") {
            printf ">%s_PRIMER_LEFT\n%s\n>%s_PRIMER_RIGHT\n%s\n", 
                   seq_id, left_primer, seq_id, right_primer
        }
        # Start new record
        seq_id = value
        left_primer = ""
        right_primer = ""
    }
    else if (key == "PRIMER_LEFT_" pair "_SEQUENCE") {
        left_primer = value
    }
    else if (key == "PRIMER_RIGHT_" pair "_SEQUENCE") {
        right_primer = value
    }
}
# Apply the previous function
{
    for (pattern in patterns) {
        if (index($0, pattern "=") == 1) {
            process_line($0)
            next
        }
    }
}
END {
    # Output the last primer pair
    if (seq_id != "" && left_primer != "" && right_primer != "") {
        printf ">%s_PRIMER_LEFT\n%s\n>%s_PRIMER_RIGHT\n%s\n", 
               seq_id, left_primer, seq_id, right_primer
    }
}' "$INPUT_FILE" > "$PRIMER_FASTA"
# Check if output was created successfully and count the number of loci with primer pairs succesfully designed
if [[ ! -s "$PRIMER_FASTA" ]]; then
    echo "Warning: No primers found in output." >&2
else
    echo "Successfully created: $PRIMER_FASTA"
    echo "Number of primer pairs extracted: $(grep -c "^>.*_PRIMER_LEFT$" "$PRIMER_FASTA")"
fi

exit 0
