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
    base=$(basename ${i%.*})
    gffread \
       -g ${WORKSHOP_DIR}/00_datasets/genome/athaliana.fa \
       -x ${base}_cds.fa \
       -y ${base}_pep.fa $i
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
       --gff ${gff3} \
       -o gff3_stats/${base}_stats.txt
done

```



## BUSCO assesment

We will use BUSCO to asses the quality of the annotation.

```bash
#!/bin/bash
ml --force purge
ml biocontainers
ml busco
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
workdir=${WORKSHOP_DIR}/08_assessment
cd ${workdir}
for pep in *_pep.fa; do
    base=$(basename ${pep%.*})
     busco \
        --in ${pep} \
        --cpu ${SLURM_CPUS_ON_NODE} \
        --out ${base}_busco \
        --mode prot \
        --lineage_dataset brassicales_odb10 \
        --force
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

The proteomes should be filtered to take only primary isoforms before running OMark.

```bash
ml --force purge
ml biocontainers
ml seqkit
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
workdir=${WORKSHOP_DIR}/08_assessment
cd ${workdir}
for pep in braker*_pep.fa; do
    base=$(basename ${pep%.*})
    grep "\.t1$" $pep | sed 's/>//g' > ${base}.primary.ids
    seqkit grep -f ${base}.primary.ids $pep > ${base}.primary.pep.fa
    rm ${base}.primary.ids
done
cp helixer_pep.fa helixer.primary.pep.fa
```

Running OMark:

```bash
#!/bin/bash
ml --force purge
ml biocontainers
ml omark
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
workdir=${WORKSHOP_DIR}/08_assessment
database="/depot/itap/datasets/omark/LUCA.h5"
cd ${workdir}
for pep in *.primary.pep.fa; do
    base=$(basename ${pep%.*})
    omamer search \
       --db ${database} \
       --query ${pep} \
       --out ${pep%.*}.omamer \
       --nthreads ${SLURM_CPUS_ON_NODE}
    omark \
       --file ${pep%.*}.omamer \
       --database ${database} \
       --outputFolder ${pep%.*} \
       --og_fasta ${pep}
done

```
:::::::::::::::::::::::::::::::::::::::::: spoiler

## **OMark Results Summary**

**Conserved HOGs in Brassicaceae**

| **Category** | **Count** | **Percentage** |
|:-----------------|------:|:--------:|
| **Total Conserved HOGs** | 17,996 | 100% |
| **Single-Copy HOGs (S)** | 16,237 | 90.23% |
| **Duplicated HOGs (D)** | 1,315 | 7.31% |
|  _Unexpected Duplications (U)_ | 351 | 1.95% |
|  _Expected Duplications (E)_ | 964 | 5.36% |
| **Missing HOGs (M)** | 444 | 2.47% |


**Proteome Composition**

| **Category** | **Count** | **Percentage** |
|:--------|---:|----:|
| **Total Proteins** | 26,994 | 100% |
| **Consistent (A)** | 25,480 | 94.39% |
| _Partial Hits (P)_ | 1,306 | 4.84% |
| _Fragmented (F)_ | 630 | 2.33% |
| **Inconsistent (I)** | 167 | 0.62% |
| _Partial Hits (P)_ | 106 | 0.39% |
| _Fragmented (F)_ | 29 | 0.11% |
| **Likely Contamination (C)** | 0 | 0.00% |
| _Partial Hits (P)_ | 0 | 0.00% |
| _Fragmented (F)_ | 0 | 0.00% |
| **Unknown (U)** | 1,347 | 4.99% |



**HOG Placement - Detected Species**

| **Species** | **NCBI TaxID** | **Associated Proteins** | **% of Total Proteome** |
|--------------|---:|---:|---:|
| _Arabidopsis thaliana_ | 3702 | 25,647 | 95.01% |

::::::::::::::::::::::::::::::::::::::::::::::::





## Feature assignment

To measure the number of raw reads assigned to the features predicted by the annotation, we will use `featureCounts` from the `subread` package.


```bash
#!/bin/bash
ml --force purge
ml biocontainers
ml subread
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
workdir=${WORKSHOP_DIR}/08_assessment
cd ${workdir}
mkdir -p featureCounts
for gff3 in *.gff3; do
    base=$(basename ${gff3%.*})
    featureCounts \
      -T ${SLURM_CPUS_ON_NODE} \
      -a ${gff3} \
      -t exon \
      -g ID \
      -p \
      -B \
      -o ${base}_merged_counts.txt \
      --tmpDir /tmp ${RCAC_SCRATCH}/annotation_workshop/00_datasets/bamfiles/*.bam
done

```


## Reference annotation comparison


We will use `mikado compare` the reference annotation with the predicted annotation.

```bash
#!/bin/bash
ml --force purge
ml biocontainers
ml mikado
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
workdir=${WORKSHOP_DIR}/08_assessment
cd ${workdir}
for gff3 in *.gff3; do
    base=$(basename ${gff3%.*})
    mikado compare \
      --protein-coding \
      -r ${RCAC_SCRATCH}/annotation_workshop/00_datasets/genome/athaliana_TAIR10.gff3 \
      -p ${gff3} \
      -o ref-TAIR10_vs_prediction_${base}_compared \
      --log ${base}_compare.log
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

