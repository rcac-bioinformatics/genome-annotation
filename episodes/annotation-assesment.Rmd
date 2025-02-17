---
title: 'Annotation Assesment'
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- How to assess the quality of a genome annotation?
- What are the different tools available for assessing the quality of a genome annotation?
- How to compare the predicted annotation with the reference annotation?
- How to measure the number of raw reads assigned to the features predicted by the annotation?



::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Assess the quality of a genome annotation using different tools.
- Compare the predicted annotation with the reference annotation.
- Measure the number of raw reads assigned to the features predicted by the annotation.


::::::::::::::::::::::::::::::::::::::::::::::::


## Setup

The folder organization is as follows:






The annotation files (`gff3`) are from the previous steps. But are collected in this folder for convenience.

We will extract CDS and Protein sequences from the `gff3` file before we begin the assesment.


```bash 
ml --force purge
ml biocontainers
ml cufflinks
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
workdir=${WORKSHOP_DIR}/08_assessment
cd ${workdir}
for i in *.gff3; do
    base=$(basename $i .gff3)
    gffread \
       -g ${WORKSHOP_DIR}/00_datasets/genome/athaliana.fa \
       -x ${base}.cds.fa \
       -y ${base}.pep.fa $i
done
```

## GFF3 metrics

We will use `agat_sp_statistics.pl` to calculate the statistics of the GFF3 file.


```bash
ml --force purge
ml biocontainers
ml agat
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
workdir=${WORKSHOP_DIR}/08_assessment
cd ${workdir}
mkdir -p gff3_stats
for gff3 in *.gff3; do
    base=$(basename $gff3 .gff3)
    agat_sp_statistics.pl \
       -g ${gff3} \
       -o gff3_stats/${base}_stats.txt
done
```



## BUSCO assesment

We will use BUSCO to asses the quality of the annotation.

```bash
ml --force purge
ml biocontainers
ml busco
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
workdir=${WORKSHOP_DIR}/08_assessment
cd ${workdir}
for pep in *.pep.fa; do
    base=$(basename $pep .pep.fa)
     busco \
        -i ${pep} \
        -c ${SLURM_CPUS_ON_NODE} \
        -o ${base}_busco \
        -m prot \
        -l brassicales_odb10 \
        -f
done
```

Once the BUSCO assesment is complete, we can view the results using the following command:

```bash
ml --force purge
ml biocontainers
ml busco
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
workdir=${WORKSHOP_DIR}/08_assessment
mkdir -p busco_results
for f in */*_busco/short_summary*busco.txt; do
   cp $f busco_results/;
done
generate_plot.py –wd busco_results
```

## Omark assesment

OMArk is a software for proteome (protein-coding gene repertoire) quality assessment. It provides measures of proteome completeness, characterizes the consistency of all protein coding genes with regard to their homologs, and identifies the presence of contamination from other species. 

```bash
ml --force purge
ml biocontainers
ml omark
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
workdir=${WORKSHOP_DIR}/08_assessment
database="${WORKSHOP_DIR}/08_assessment/omark/LUCA.h5"
cd ${workdir}
for pep in *.pep.fa; do
    base=$(basename $pep .pep.fa)
    omamer search \
       --db ${database} \
       --query ${pep} \
       --out ${pep%.*}.omamer \
       --nthreads ${SLURM_CPUS_ON_NODE}
    omark \
       --file ${pep%.*}.omamer \
       --database ${database} \
       --outputFolder ${pep%.*} \
       --og_fasta ${pep} \
       --isoform_file ${pep%.*}.splice
done
```

## Feature assignment

To measure the number of raw reads assigned to the features predicted by the annotation, we will use `featureCounts` from the `subread` package.


```bash
ml --force purge
ml biocontainers
ml subread
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
workdir=${WORKSHOP_DIR}/08_assessment
cd ${workdir}
mkdir -p featureCounts
for gff3 in *.gff3; do
    base=$(basename $f .gff3)
    featureCounts \
        -T ${SLURM_CPUS_ON_NODE} \
        -a ${gff3} \
        -o featureCounts/${base}_featureCounts.txt \
        -s 2 \
        -p --countReadPairs \
        -t gene -g ID \
        --tmpDir /dev/shm \
        ${WORKSHOP_DIR}/00_datasets/bamfiles/*.bam
done

```


## Reference annotation comparison


We will use `gffcompare` to compare the reference annotation with the predicted annotation.

```bash
ml --force purge
ml biocontainers
ml cufflinks
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
workdir=${WORKSHOP_DIR}/08_assessment
cd ${workdir}
mkdir -p gffcompare
for gff3 in *.gff3; do
    base=$(basename $gff3 .gff3)
    gffcompare \
       -r ${WORKSHOP_DIR}/00_datasets/annotation/athaliana.gff3 \
       -o gffcompare/${base} \
       ${gff3}
done
```

## Summary

::::::::::::::::::::::::::::::::::::: keypoints 

- `busco` and `omark` assess how well conserved genes are represented in the predicted gene set  
- `gff3` metrics provide structural insights and highlight discrepancies compared to known annotations  
- `featureCounts` assignment quantifies the number of RNA-seq reads aligning to predicted features  
- Reference annotation comparison evaluates how closely the predicted genes match an established reference  
- Multiple assessment methods ensure a comprehensive evaluation of annotation quality

::::::::::::::::::::::::::::::::::::::::::::::::

