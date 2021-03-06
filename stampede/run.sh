#!/bin/bash

#SBATCH -J cntrfge 
#SBATCH -A iPlant-Collabs 
#SBATCH -N 4
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p normal

# Author: Ken Youens-Clark <kyclark@email.arizona.edu>
# Second author: Scott G. Daniel <scottdaniel@email.arizona.edu>

module load tacc-singularity 
module load launcher

set -u

#
# Set up defaults for inputs, constants
#
IN_DIR=""
QUERY=""
FORMAT="fasta"
MODE="single"
FASTX=""
FORWARD=""
REVERSE=""
SINGLETONS=""
INDEX="p_compressed+h+v"
OUT_DIR="$PWD/centrifuge-out"
INDEX_DIR="/work/05066/imicrobe/iplantc.org/data/centrifuge-indexes"
MAX_SEQS_PER_FILE=1000000
<<<<<<< HEAD
CENTRIFUGE_IMG="centrifuge-patric.img"
||||||| merged common ancestors
CENTRIFUGE_IMG="centrifuge-1.0.3-beta.img"
=======
CENTRIFUGE_IMG="/work/05066/imicrobe/singularity/centrifuge-1.0.4.img"
>>>>>>> 6cdbc66c6abced72fd41ebe182361bf4dd23acc7
EXCLUDE_TAXIDS=""
SKIP_EXISTING=1
#If you have your own launcher setup on stampede2 just point MY_PARAMRUN at it
#this will override the TACC_LAUNCHER...
echo "\$MY_PARAMRUN = $MY_PARAMRUN"
PARAMRUN="${MY_PARAMRUN:-$TACC_LAUNCHER_DIR/paramrun}"
echo "\$PARAMRUN = $PARAMRUN"
MIN_ABUNDANCE=0.01
FORMAT="fasta"

#
# Some needed functions
#
function lc() { 
    wc -l "$1" | cut -d ' ' -f 1 
}

function HELP() {
    printf "Usage:\n  %s -q DIR_OR_FILE\n\n" "$(basename "$0")"
    printf "Usage:\n  %s -d IN_DIR\n\n" "$(basename "$0")"
    printf "Usage:\n  %s -a FASTX\n\n" "$(basename "$0")"
    printf "Usage:\n  %s -1 FASTX_r1 -2 FASTX_r2 [-s SINGLETONS]\n\n" \
      "$(basename "$0")"
  
    echo "Required arguments:"
    echo " -q DIR_OR_FILE"
    echo ""
    echo "OR"
    echo " -d IN_DIR (single-only)"
    echo ""
    echo "OR"
    echo " -a FASTX (single)"
    echo ""
    echo "OR"
    echo " -1 FASTX_r1 (forward)"
    echo " -2 FASTX_r2 (reverse)"
    echo ""
    echo "Options:"
    echo " -f FORMAT ($FORMAT)"
    echo " -i INDEX ($INDEX)"
    echo " -o OUT_DIR ($OUT_DIR)"
    echo " -t FORMAT ($FORMAT)"
    echo " -s SINGLETONS"
    echo " -k SKIP_EXISTING ($SKIP_EXISTING)"
    echo " -m MIN_ABUNDANCE ($MIN_ABUNDANCE)"
    echo " -x EXCLUDE_TAXIDS"
    echo ""
    exit 0
}

#
# Show HELP if no arguments
#
[[ $# -eq 0 ]] && HELP

<<<<<<< HEAD
while getopts :a:d:i:f:m:o:q:r:s:m:x:k:1:2h OPT; do
||||||| merged common ancestors
while getopts :a:d:i:f:m:o:q:r:s:x:kh OPT; do
=======
while getopts :a:d:i:f:m:o:q:r:s:t:x:kh OPT; do
>>>>>>> 6cdbc66c6abced72fd41ebe182361bf4dd23acc7
    case $OPT in
        a)
            FASTX="$OPTARG"
            ;;
        d)
            IN_DIR="$OPTARG"
            ;;
        h)
            HELP
            ;;
        i)
            INDEX="$OPTARG"
            ;;
        f)
            FORMAT="$OPTARG"
            ;;
        k)
            SKIP_EXISTING=1
            ;;
        m)
            MODE="$OPTARG"
            ;;
        o)
            OUT_DIR="$OPTARG"
            ;;
        q)
            QUERY="$QUERY $OPTARG"
            ;;
        1)
            FORWARD="$OPTARG"
            ;;
        2)
            REVERSE="$OPTARG"
            ;;
        s)
            SINGLETONS="$OPTARG"
            ;;
<<<<<<< HEAD
        m)
            MIN_ABUNDANCE="$OPTARG"
            ;;
||||||| merged common ancestors
=======
        t)
            FORMAT="$OPTARG"
            ;;
>>>>>>> 6cdbc66c6abced72fd41ebe182361bf4dd23acc7
        x)
            EXCLUDE_TAXIDS="$OPTARG"
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument."
            exit 1
            ;;
        \?)
            echo "Error: Invalid option: -${OPTARG:-""}"
            exit 1
    esac
done

if [[ ! -e "$CENTRIFUGE_IMG" ]]; then
    echo "Missing CENTRIFUGE_IMG \"$CENTRIFUGE_IMG\""
    exit 1
fi

#
# Verify existence of INDEX_DIR, chosen INDEX
#
if [[ ! -d "$INDEX_DIR" ]]; then
    echo "Cannot find INDEX_DIR \"$INDEX_DIR\""
    exit 1
fi

NUM=$(find "$INDEX_DIR" -name $INDEX.\*.cf | wc -l | awk '{print $1}')

if [[ $NUM -gt 0 ]]; then
    echo "Using INDEX \"$INDEX\""
else
    echo "Cannot find INDEX \"$INDEX\""
    echo "Please choose from the following:"
    find "$INDEX_DIR" -name \*.cf -exec basename {} \; | sed "s/\.[0-9]\.cf//" | sort | uniq | cat -n
    exit 1
fi

#
# Verify existence of various directories, files
#
[[ ! -d "$OUT_DIR" ]] && mkdir -p "$OUT_DIR"

REPORT_DIR="$OUT_DIR/reports"
[[ ! -d "$REPORT_DIR" ]] && mkdir -p "$REPORT_DIR"

PLOT_DIR="$OUT_DIR/plots"
[[ ! -d "$PLOT_DIR" ]] && mkdir -p "$PLOT_DIR"

if [[ ! -d "$TACC_LAUNCHER_DIR" ]]; then
    echo "Cannot find TACC_LAUNCHER_DIR \"$TACC_LAUNCHER_DIR\""
    exit 1
fi

if [[ ! -f "$PARAMRUN" ]]; then
    echo "Cannot find PARAMRUN \"$PARAM_RUN\""
    exit 1
fi

#
# Create, null-out command file for running Centrifuge
#
CENT_PARAM="$PWD/$$.centrifuge.param"
cat /dev/null > "$CENT_PARAM"

EXCLUDE_ARG=""
[[ -n "$EXCLUDE_TAXIDS" ]] && EXCLUDE_ARG="--exclude-taxids $EXCLUDE_TAXIDS"
RUN_CENTRIFUGE="CENTRIFUGE_INDEXES=$INDEX_DIR singularity run $CENTRIFUGE_IMG $EXCLUDE_ARG"

#
# Set up LAUNCHER env
#
#export LAUNCHER_DIR="$HOME/src/launcher"
#export LAUNCHER_PLUGIN_DIR="$LAUNCHER_DIR/plugins"
export LAUNCHER_WORKDIR="$PWD"
export LAUNCHER_RMI=SLURM
export LAUNCHER_SCHED=interleaved

INPUT_FILES=$(mktemp)

#
# A single FASTX
#
if [[ -n "$FASTX" ]]; then
    BASENAME=$(basename "$FASTX")
    echo "Will process single FASTX \"$BASENAME\""
    echo "$RUN_CENTRIFUGE -f -x $INDEX -U $FASTX -S $REPORT_DIR/$BASENAME.sum --report-file $REPORT_DIR/$BASENAME.tsv" > "$CENT_PARAM"

#
# Paired-end FASTX reads
#
elif [[ -n "$FORWARD" ]] && [[ -n "$REVERSE" ]]; then
    BASENAME=$(basename "$FORWARD")
    echo "Will process FORWARD \"$FORWARD\" REVERSE \"$REVERSE\""

    S=""
    [[ ! -z $SINGLETONS ]] && S="-U $SINGLETONS"

    echo "$RUN_CENTRIFUGE -f -x $INDEX -1 $FORWARD -2 $REVERSE $S -S $REPORT_DIR/$BASENAME.sum --report-file $REPORT_DIR/$BASENAME.tsv" > "$CENT_PARAM"

#
# A directory of single FASTX files
#
elif [[ -n "$IN_DIR" ]] && [[ -d "$IN_DIR" ]]; then
    if [[ $MODE == 'single' ]]; then
        find "$IN_DIR" -type f -size +0c \( -name \*.fa -o -name \*.fasta \) > "$INPUT_FILES"
    else
        echo "Can't yet run IN_DIR with 'paired' mode"
        exit 1
    fi

#
# Either files and/or directories
#
elif [[ -n "$QUERY" ]]; then
    for QRY in $QUERY; do
        if [[ -d "$QRY" ]]; then
            find "$QRY" -type f -not -name .\* >> "$INPUT_FILES"
        elif [[ -f "$QRY" ]]; then
            echo "$QRY" >> "$INPUT_FILES"
        else 
            echo "QUERY ARG \"$QRY\" is neither dir nor file"
        fi
    done

#
# Else "error"
#
else
    echo "Must have -q FILE_OR_DIR/-d IN_DIR/-a FASTX/-f FORWARD & -r REVERSE [-s SINGLETON]"
    exit 1
fi

NUM_INPUT=$(lc "$INPUT_FILES")
if [[ $NUM_INPUT -gt 0 ]]; then
    SPLIT_DIR="$OUT_DIR/split"
    [[ ! -d "$SPLIT_DIR" ]] && mkdir -p "$SPLIT_DIR"
    SPLIT_PARAM="$$.split.param"

    i=0
    while read -r FILE; do
        BASENAME=$(basename "$FILE")
        FILE_SPLIT_DIR="$SPLIT_DIR/$BASENAME"
        NUM_SPLIT_FILES=0
        if [[ -d "$FILE_SPLIT_DIR" ]]; then
            NUM_SPLIT_FILES=$(find "$FILE_SPLIT_DIR" -type f | wc -l | awk '{print $1}')
        fi

        if [[ $NUM_SPLIT_FILES -lt 1 ]]; then
            let i++
            printf "%6d: Split %s\n" $i "$(basename "$FILE")"
<<<<<<< HEAD
            echo "singularity exec $CENTRIFUGE_IMG fxsplit.py -i $FILE -f $FORMAT -o $FILE_SPLIT_DIR -n $MAX_SEQS_PER_FILE" >> "$SPLIT_PARAM"
||||||| merged common ancestors
            echo "singularity exec $CENTRIFUGE_IMG fasplit.py -f $FILE -o $FILE_SPLIT_DIR -n $MAX_SEQS_PER_FILE" >> "$SPLIT_PARAM"
=======
            echo "singularity exec $CENTRIFUGE_IMG fasplit.py -i $FILE -f $FORMAT -o $FILE_SPLIT_DIR -n $MAX_SEQS_PER_FILE" >> "$SPLIT_PARAM"
>>>>>>> 6cdbc66c6abced72fd41ebe182361bf4dd23acc7
        fi
    done < "$INPUT_FILES"

    echo "Launching splitter"
    export LAUNCHER_PPN=8
    export LAUNCHER_JOB_FILE="$SPLIT_PARAM"
    "$TACC_LAUNCHER_DIR/paramrun"
    rm "$SPLIT_PARAM"

    SPLIT_FILES=$(mktemp)
    find "$SPLIT_DIR" -type f -size +0c > "$SPLIT_FILES"
    NUM_SPLIT=$(lc "$SPLIT_FILES")
    echo "Splitter done, found NUM_SPLIT \"$NUM_SPLIT\""

    while read -r FILE; do
        BASENAME=$(basename "$FILE")
        SUM_FILE="$REPORT_DIR/$BASENAME.sum"
        TSV_FILE="$REPORT_DIR/$BASENAME.tsv"
  
        if [[ "$SKIP_EXISTING" -gt 0 ]] && [[ -s "$SUM_FILE" ]] && [[ -s "$TSV_FILE" ]]; then
            echo "Skipping $BASENAME - sum/tsv files exist"
        else
            if [[ "$FORMAT" == "fasta" ]]; then
    #            echo "This is a fasta" #debug
                echo "$RUN_CENTRIFUGE -f -x $INDEX -U $FILE -S $REPORT_DIR/$BASENAME.sum --report-file $REPORT_DIR/$BASENAME.tsv" >> "$CENT_PARAM"
            elif [[ "$FORMAT" == "fastq" ]]; then
    #            echo "This is a fastq" #debug
                echo "$RUN_CENTRIFUGE -x $INDEX -U $FILE -S $REPORT_DIR/$BASENAME.sum --report-file $REPORT_DIR/$BASENAME.tsv" >> "$CENT_PARAM"
            else
                echo "File is not fasta or fastq!"
                exit 1
            fi
        fi
    done < "$SPLIT_FILES"

    rm "$SPLIT_FILES"
    #rm -rf "$SPLIT_DIR"
fi

#
# Pass Centrifuge run to LAUNCHER
# Run "interleaved" to ensure this finishes before bubble
#
NUM_CENT_JOBS=$(lc "$CENT_PARAM")
if [[ "$NUM_CENT_JOBS" -gt 0 ]]; then
    echo "Running \"$NUM_CENT_JOBS\" for Centrifuge \"$CENT_PARAM\""
    export LAUNCHER_JOB_FILE="$CENT_PARAM"
    if [[ $INDEX == 'nt' ]]; then
        export LAUNCHER_PPN=1 # nt requires ALL THE MEMORY
    else
        export LAUNCHER_PPN=4 
    fi
    $PARAMRUN
    echo "Finished Centrifuge"
else
    echo "There are no Centrifuge jobs to run!"
    exit 1
fi

rm "$CENT_PARAM"
#
# Collapse the results
#
COLLAPSE_DIR="$OUT_DIR/collapsed"
echo "Collapsing reports"
#echo "DEBUG"
#echo "These are the input files: "$INPUT_FILES""
#echo "This is the report dir: "$REPORT_DIR""
#echo "This is the collapse dir: "$COLLAPSE_DIR""
singularity exec $CENTRIFUGE_IMG collapse.py -l "$INPUT_FILES" -r "$REPORT_DIR" -o "$COLLAPSE_DIR"
echo "Finished collapse"

#rm "$INPUT_FILES"

#
# Create bubble plot
#
echo "Starting bubble"
singularity exec $CENTRIFUGE_IMG centrifuge_bubble.r --dir "$COLLAPSE_DIR" --outdir "$PLOT_DIR" --outfile "bubble" --title "centrifuge"

<<<<<<< HEAD
#BUBBLE_PARAM="$PWD/$$.bubble.param"
#echo "singularity exec $CENTRIFUGE_IMG centrifuge_bubble.r --dir $COLLAPSE_DIR --outdir $PLOT_DIR --outfile bubble --title centrifuge" > "$BUBBLE_PARAM"
#export LAUNCHER_JOB_FILE="$BUBBLE_PARAM"
#"$LAUNCHER_DIR/paramrun"
echo "Finished bubble"

#
# Getting genomes from PATRIC
#
GENOME_DIR="$OUT_DIR/genomes"
[[ ! -d $GENOME_DIR ]] && mkdir -p $GENOME_DIR
echo "Getting genomes and annotations from patricbrc.org"
#-r directory with tsv report files -o output directory for genomes and annotations
singularity exec $CENTRIFUGE_IMG cfuge_to_genome.py -r "$COLLAPSE_DIR" -o $GENOME_DIR -m $MIN_ABUNDANCE

||||||| merged common ancestors
#BUBBLE_PARAM="$PWD/$$.bubble.param"
#echo "singularity exec $CENTRIFUGE_IMG centrifuge_bubble.r --dir $COLLAPSE_DIR --outdir $PLOT_DIR --outfile bubble --title centrifuge" > "$BUBBLE_PARAM"
#export LAUNCHER_JOB_FILE="$BUBBLE_PARAM"
#"$LAUNCHER_DIR/paramrun"
echo "Finished bubble"

=======
>>>>>>> 6cdbc66c6abced72fd41ebe182361bf4dd23acc7
echo "Done, look in OUT_DIR \"$OUT_DIR\""
echo "Comments to Ken Youens-Clark <kyclark@email.arizona.edu>"
echo "or Scott Daniel <scottdaniel@email.arizona.edu>"
echo "for version that runs patric-cli along with centrifuge (RADCOT)"
