#!/usr/bin/env bash

if [ $# -ne 5 ]; then
    echo 'Usage: typhi_JINA_pipeline.sh ASMB_LST ASMB_DIR OUT_DIR THREADS BLOCK_SIZE'
    echo '    ASMB_LST: file with the names of genomes to compute'
    echo '    ASMB_DIR: folder containing the sequences in FASTA format'
    echo '    OUT_DIR: folder for pipeline output'
    echo '    THREADS: number of threads to use'
    echo '    BLOCK_SIZE: maximum number of genomes to compare at any given time'
    exit 2
fi

ASMB_LST=$1
ASMB_DIR=$2
OUT_DIR=$3
THREADS=$4
BLOCK_SIZE=$5

# Activate enviroments
source "$(dirname "${CONDA_EXE%/*}")"/etc/profile.d/conda.sh
conda activate typhi_JINA

# Constants
KMERLEN_jellyfish=31
JF_COUNTS='mer_counts.jf'
JF_TEMP='jf.temp'
FOFN="${OUT_DIR}/genome_list.fofn"
METADATA="${OUT_DIR}/nodes.tsv"

KMERLEN=21
SKETCH_SIZE=262144
SKETCH_SEED=41
SKETCH_DIR="${OUT_DIR}/kmer_database.bdsh"
JI_TMP="${OUT_DIR}/tmp.tsv.gz"
JI_DIST="${OUT_DIR}/JI_distances.bdsh.tsv.gz"
EDGES="${OUT_DIR}/edges.tsv"

# Create output directory
mkdir -p ${OUT_DIR}

#### Step 1: Compute GLD with jellyfish ####
if [ -e ${FOFN} ]; then truncate -s 0 ${FOFN}; fi
if [ -e ${METADATA} ]; then truncate -s 0 ${METADATA}; fi
echo -e "ID\tAccessionVersion\tContigs\tDistinct_kmers\tEstimated_genome_length" > ${METADATA}
readarray -t asmb_array < ${ASMB_LST}
for f in "${asmb_array[@]}"; do
    fname=${ASMB_DIR}/${f}.fna
    contigs=`grep -cF '>' ${fname}`
    echo -e "${fname}\t${f}\t${contigs}" >> ${FOFN}

    jellyfish count -C -m ${KMERLEN_jellyfish} -s 6000000 -o ${JF_COUNTS} ${fname}
    d_kmers=`jellyfish stats ${JF_COUNTS} | grep -Po 'Distinct: *\K.*?(?=$)'`
    k_length=$((d_kmers + (KMERLEN - 1) * contigs))
    echo -e "${f%.*}\t${f}\t${contigs}\t${d_kmers}\t${k_length}" >> ${METADATA}
done

#### Step 2: Prepare kmer database ####
bin/bindash_block_sketch.pl --fofn=${FOFN} --outdir=${SKETCH_DIR} --blocksize ${BLOCK_SIZE} --kmerlen ${KMERLEN} --exact --sketchsize ${SKETCH_SIZE} --sketchseed ${SKETCH_SEED} --nthreads ${THREADS}

#### Step 3: Compute JI dist ####
bin/bindash_block_dist.pl ${SKETCH_DIR} --metadata ${METADATA} --output ${JI_TMP} --nthreads ${THREADS}

zcat ${JI_TMP} | \
    awk 'BEGIN{FS=OFS="\t"} (NR==1) {next} {if ($1 == $2) {next} else if ($1 > $2) {print $2,$1,$3,$4,$5,$6,$7} else {print}}' | \
    sort | uniq | sed '1iRef-ID\tQry-ID\tMut-distance\tP-value\tHashes\tJI\tGLD_1M' | gzip > ${JI_DIST}
rm ${JI_TMP}

#### Prepare network files ####
zcat ${JI_DIST} | \
    awk 'BEGIN{FS=OFS="\t"} (NR==1) {print "Source", "Target", "Type", "Weight", "JI", "GLD_1M"; next} {print $1, $2, "Undirected", "1", $6, $7}' > ${EDGES}
