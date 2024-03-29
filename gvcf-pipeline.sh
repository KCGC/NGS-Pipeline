#!/usr/bin/env bash

#! RUN : bash gvcf-pipeline.sh <SAMPLE> <REF>
#! Eg. : bash gvcf-pipeline.sh CS_35365 cf4

SAMPLE=$1
REF=$2
SCRIPTS=`dirname $0`
CFG="${SCRIPTS}/ngs-pipeline-${REF}.config"

[[ -z "$SAMPLE" ]] && { echo "ERROR: No SAMPLE provided for this run"; exit 1; }
[[ -z "$REF" ]] && { echo "ERROR: No REFERENCE provided for this run"; exit 1; }

date

mkdir -p $SAMPLE/logs; cd $SAMPLE
cp $CFG $SAMPLE.config; source $SAMPLE.config
mkdir -p $GENOME; 
mv $SAMPLE.config $GENOME/

cd $GENOME

#PCR_FREE=false;
PCR_MODEL='CONSERVATIVE';

echo
printf "Is the data PCR free?\n"
printf "\t1. No [default]\n"
printf "\t2. Yes\n"
# Assign input value into a variable
read answer

if [[ -n $answer && $answer == "2" ]]; then
    #PCR_FREE=true;
    PCR_MODEL='NONE';
fi

# Copy BAM/BAI files from RCS... will only copy if files no present or rcs version is newer
rsync --progress -av ${WGS}/${SAMPLE}/${SAMPLE}-${REF}.ba* ./

# generate seqeunce groups for future scatter/gather steps.
#perl ${SCRIPTS}/perl/createSeqGroups.pl ${DICT}
#INTERVALS=`wc -l sequence_grouping.txt | awk '{print $1}'`

module load gatk-4.2.5.0-gcc-5.4.0-hzdcjga

mkdir intervals
gatk SplitIntervals -R ${FASTA}/${GENOME}.fasta -L ${INTERVAL_LIST} --scatter-count ${INTERVALS}  -O intervals --subdivision-mode BALANCING_WITHOUT_INTERVAL_SUBDIVISION

# Create gvcf files with HaplotypeCaller
jid1=$(sbatch -A ${ACCOUNT} -J ${SAMPLE}.HC --array=0-$(($INTERVALS-1)) ${SCRIPTS}/slurm/haplotypeCaller.sh ${SAMPLE} ${REF} ${PCR_MODEL})

# Merge gVCF files into single gVCF
jid2=$(sbatch -A ${ACCOUNT} -J ${SAMPLE}.GVCF --dependency=afterok:${jid1##* } ${SCRIPTS}/slurm/combineGvcf.sh ${SAMPLE} ${INTERVALS} ${REF})

echo $jid2
