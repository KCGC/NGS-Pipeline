#!/usr/bin/env bash

#! RUN : sbatch mergeGvcf.sh <SAMPLE> <INTERVALS> <REF>

#! sbatch directives begin here ###############################
#! How many whole nodes should be allocated?
#SBATCH --nodes=1
#! How many (MPI) tasks will there be in total? (<= nodes*32)
#! The skylake/skylake-himem nodes have 32 CPUs (cores) each.
#SBATCH --ntasks=1
#! How much wallclock time will be required?
#SBATCH --time 36:00:00
#! What types of email messages do you wish to receive?
#SBATCH --mail-type=FAIL,INVALID_DEPEND,END
#! Uncomment this to prevent the job from being requeued (e.g. if
#! interrupted by node failure or system downtime):
##SBATCH --no-requeue
#! For 6GB per CPU, set "-p skylake"; for 12GB per CPU, set "-p skylake-himem":
#SBATCH -p skylake
#SBATCH --mem=5gb

#SBATCH -o ../logs/job-%j.out

. /etc/profile.d/modules.sh                 # Leave this line (enables the module command)
module purge                                # Removes all modules still loaded
module load rhel7/default-peta4             # REQUIRED - loads the basic environment

module load jdk-8u141-b15-gcc-5.4.0-p4aaopt 
module load gatk/4.1.0.0                    # GATK 4.1

SAMPLE=$1
INTERVALS=$2
REF=$3
source ${SAMPLE}.config

#ls -1 ${SAMPLE}*.recal_data.csv > bsqr_reports.txt
GVCFS=""
for i in `seq 0 $(($INTERVALS-1))`; do n=$(printf "%04d" $i); GVCFS+="--variant ${SAMPLE}-${REF}.$n.g.vcf "; done

gatk --java-options  "-Djava.io.tmpdir=${HOME}/hpc-work/tmp/ -Xmx5G" CombineGVCFs ${GVCFS} -R ${FASTA}/${GENOME}.fasta -O ${SAMPLE}-${REF}.g.vcf.gz

gvcf_size=$(wc -c < ${SAMPLE}-${REF}.g.vcf.gz)
if [ $gvcf_size -ge 50000000 ];then
  for i in `seq 0 $(($INTERVALS-1))`; do 
    n=$(printf "%04d" $i)
	  rm -rf ${SAMPLE}-${REF}.$n.g.vcf
	  rm -rf ${SAMPLE}-${REF}.$n.g.vcf.idx
  done
fi
