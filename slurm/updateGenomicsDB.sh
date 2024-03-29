#!/usr/bin/env bash

#! RUN : sbatch updateGenomicsDB.sh <SAMPLE_LIST> <REF>

#! sbatch directives begin here ###############################
#! How many whole nodes should be allocated?
#SBATCH --nodes=1
#! How many (MPI) tasks will there be in total? (<= nodes*32)
#! The skylake/skylake-himem nodes have 32 CPUs (cores) each.
#SBATCH --ntasks=1
#! How much wallclock time will be required?
#SBATCH --time 04:00:00
#! What types of email messages do you wish to receive?
#SBATCH --mail-type=ALL
#! Uncomment this to prevent the job from being requeued (e.g. if
#! interrupted by node failure or system downtime):
##SBATCH --no-requeue
#! For 6GB per CPU, set "-p skylake"; for 12GB per CPU, set "-p skylake-himem":
#SBATCH -p skylake-himem
#SBATCH --mem=10gb

#SBATCH -o logs/job-%A_%a.out

. /etc/profile.d/modules.sh                 # Leave this line (enables the module command)
module purge                                # Removes all modules still loaded
module load rhel7/default-peta4             # REQUIRED - loads the basic environment

module load gatk-4.2.5.0-gcc-5.4.0-hzdcjga

SAMPLE_LIST=$1
REF=$2
source ${REF}.config


INTERVALS=`head -${SLURM_ARRAY_TASK_ID} ${FASTA}/${REF}-genomicsDB.intervals | tail -1 | sed s/" "/" -L "/g`
CHR=`echo ${INTERVALS} | cut -f 1 -d' ' | cut -d'_' -f 1 | cut -f 1 -d':'`

if [[ ${#CHR} -lt 4 ]] ; then
  CHR="chr"${CHR}
fi


GVCFs=""
for s in `cat ${SAMPLE_LIST}`; do GVCFs+="-V ${s}-${REF}.g.vcf.gz "; done

gatk --java-options "-Djava.io.tmpdir=${HOME}/hpc-work/tmp/ -Xmx10G" GenomicsDBImport \
    ${GVCFs} \
    --tmp-dir ${HOME}/hpc-work/tmp/ \
    --genomicsdb-update-workspace-path ${GDB}/${GENOME}/${CHR}-${SLURM_ARRAY_TASK_ID}
