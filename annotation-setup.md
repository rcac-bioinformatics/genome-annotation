---
title: 'Annotation Setup'
teaching: 15
exercises: 2
---


:::::::::::::::::::::::::::::::::::::: questions 

- How should files and directories be structured for a genome annotation workflow?  
- Why is RNA-seq read mapping important for gene prediction?  
- How does repeat masking improve annotation accuracy?  
- What preprocessing steps are necessary before running gene prediction tools?  

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Set up a structured workspace for genome annotation  
- Map RNA-seq reads to the genome to provide evidence for gene prediction  
- Perform repeat masking to prevent false gene annotations  
- Prepare genome and transcriptomic data for downstream annotation analyses  

::::::::::::::::::::::::::::::::::::::::::::::::

## Setup

This section outlines the preprocessing steps required before gene annotation, including organizing directories, mapping RNA-Seq reads, and masking repetitive elements. These steps have already been completed to save time, but the instructions are provided for reference in case you need to run them on custom datasets.

:::::::::::::::::::::::::::::::::::::::  prereq

## Optional Section!

Feel free to skip this section as it is already performed to save time.
The steps below are provided for reference - to run on custom data.

::::::::::::::::::::::::::::::::::::::::::::::::

## Folder structure


```bash
mkdir -p ${RCAC_SCRATCH}/annotation_workshop
cd ${RCAC_SCRATCH}/annotation_workshop
mkdir -p 00_datasets/{fastq,genome,bamfiles}
mkdir -p 04_braker
mkdir -p 05_helixer
mkdir -p 06_easel
mkdir -p 07_entap
mkdir -p 08_assessment
rsync -avP /depot/workshop/data/annotation_workshop/00_datasets/ 00_datasets/
```

![Organization](https://github.com/user-attachments/assets/6184ce77-1cf7-49da-86d8-e56a80b29a6e)

## RNA-Seq mapping 

The RNA-seq dataset used for gene prediction comes from the accession [E-MTAB-6422](https://www.ebi.ac.uk/biostudies/arrayexpress/studies/E-MTAB-6422), that provides a gene expression atlas of Arabidopsis thaliana (Columbia accession), capturing transcriptional programs across 36 libraries representing different tissues (seedling, root, inflorescence, flower, silique, seed) and developmental stages (2-leaf, 6-leaf, 12-leaf, senescence, dry mature, and imbibed seed), with three biological replicates per condition.


**Step 1: Download the reference genome and annotation files**


```bash
# Download the reference genome
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
mkdir -p ${WORKSHOP_DIR}/00_datasets/genome
cd ${WORKSHOP_DIR}/00_datasets/genome 
wget https://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-60/fasta/arabidopsis_thaliana/dna/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa.gz
gunzip Arabidopsis_thaliana.TAIR10.dna.toplevel.fa.gz
ml --force purge
ml biocontainers
ml bioawk
bioawk -c fastx '{print ">"$name; print $seq}' \
   Arabidopsis_thaliana.TAIR10.dna.toplevel.fa |\
   fold > athaliana.fasta
rm Arabidopsis_thaliana.TAIR10.dna.toplevel.fa
```

**Step 2: Index the reference genome using STAR**

```bash
#!/bin/bash
ml --force purge
ml biocontainers
ml star
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
genome="${WORKSHOP_DIR}/00_datasets/genome/athaliana.fasta"
index="${WORKSHOP_DIR}/00_datasets/genome/star_index"
STAR --runThreadN ${SLURM_CPUS_ON_NODE} \
   --runMode genomeGenerate \
   --genomeDir ${index}  \
   --genomeSAindexNbases 12 \
   --genomeFastaFiles ${genome}
```

::: callout

## Options

| Option                     | Description |
|:----|-------------|
| `--runThreadN $SLURM_CPUS_ON_NODE` | Specifies the number of CPU threads to use. In an HPC environment, `$SLURM_CPUS_ON_NODE` dynamically assigns available CPUs per node. |
| `--runMode genomeGenerate` | Runs STAR in genome index generation mode, required before alignment. |
| `--genomeDir ${index}` | Path to the directory where the genome index will be stored. |
| `--genomeSAindexNbases 12` | Defines the length of the SA pre-indexing string. A recommended value is `min(14, log2(GenomeLength)/2 - 1)`, but `12` is commonly used for smaller genomes. |
| `--genomeFastaFiles ${genome}` | Path to the FASTA file containing the reference genome sequences. |


:::

**Step 3: Map the RNA-Seq reads to the reference genome**

We need to setup a script `star-mapping.sh` to map the RNA-Seq reads to the reference genome.


```bash
#!/bin/bash
ml --force purge
ml biocontainers
ml star
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
genome="${WORKSHOP_DIR}/00_datasets/genome/athaliana.fasta"
index="${WORKSHOP_DIR}/00_datasets/genome/star_index"
read1=$1
read2=$2
cpus=${SLURM_CPUS_ON_NODE}
outname=$(basename ${read1} | cut -f 1 -d "_")
STAR \
--runThreadN ${cpus} \
--genomeDir ${index} \
--outSAMtype BAM SortedByCoordinate \
--outFilterScoreMinOverLread 0.3 \
--outFilterMatchNminOverLread 0.3 \
--outFileNamePrefix ${outname}_ \
--readFilesCommand zcat \
--outWigType bedGraph \
--outWigStrand Unstranded \
--outWigNorm RPM \
--readFilesIn ${read1} ${read2}
```

::: callout

## Options

| Option                                 | Description |
|:---|-------------|
| `--runThreadN ${cpus}`                 | Specifies the number of CPU threads to use for alignment. |
| `--genomeDir ${index}`                  | Path to the pre-generated STAR genome index directory. |
| `--outSAMtype BAM SortedByCoordinate`   | Outputs aligned reads in **BAM format**, sorted by genomic coordinates. |
| `--outFilterScoreMinOverLread 0.3`      | Sets the minimum alignment score relative to read length (30% of the max possible score). |
| `--outFilterMatchNminOverLread 0.3`     | Sets the minimum number of matching bases relative to read length (30% of the read must match). |
| `--outFileNamePrefix ${outname}_`       | Prefix for all output files generated by STAR. |
| `--readFilesCommand zcat`               | Specifies a command (`zcat`) to decompress input FASTQ files if they are gzipped. |
| `--outWigType bedGraph`                 | Outputs signal coverage in **bedGraph** format for visualization. |
| `--outWigStrand Unstranded`             | Specifies that the RNA-seq library is **unstranded** (reads are not strand-specific). |
| `--outWigNorm RPM`                      | Normalizes coverage signal to **Reads Per Million (RPM)**. |
| `--readFilesIn ${read1} ${read2}`       | Specifies input paired-end FASTQ files (Read 1 and Read 2). |


:::


**Step 4: Run the STAR mapping script**

```bash
#!/bin/bash
# Define the directory containing FASTQ files
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
FASTQ_DIR="${WORKSHOP_DIR}/00_datasets/fastq"
# Loop through all R1 files and find corresponding R2 files
for R1 in ${FASTQ_DIR}/*_R1.fq.gz; do
    R2="${R1/_R1.fq.gz/_R2.fq.gz}"  # Replace R1 with R2
    if [[ -f "$R2" ]]; then  # Check if R2 exists
        echo "Running STAR mapping for: $R1 and $R2"
        ./star-mapping.sh "$R1" "$R2"
    else
        echo "Error: Matching R2 file for $R1 not found!" >&2
    fi
done
```

**Step 5: store BAM files**

```bash
# Define the directory containing BAM files
BAM_DIR="${WORKSHOP_DIR}/00_datasets/bamfiles"
# Move all BAM files to the BAM directory
mv *_Aligned.sortedByCoord.out.bam ${BAM_DIR}/
```

## RepeatMasker

Some gene prediction tools require repeat-masked genomes to avoid mis-annotation of transposable elements as genes. We will use RepeatMasker to mask the repeats in the genome.
But first, we need to download the RepeatMasker database.

```bash
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
cd ${WORKSHOP_DIR}/00_datasets/genome
# Download the RepeatMasker database
wget https://www.girinst.org/server/RepBase/protected/RepBase30.01.fasta.tar.gz
tar xf RepBase30.01.fasta.tar.gz
replib=$(find $(pwd) -name "athrep.ref")
ml --force purge
ml biocontainers
ml repeatmasker
genome="${WORKSHOP_DIR}/00_datasets/genome/athaliana.fasta"
RepeatMasker \
   -e ncbi \
   -pa ${SLURM_CPUS_ON_NODE} \
   -q \
   -xsmall \
   -lib ${replib} \
   -nocut \
   -gff \
   ${genome}
```

Once done, we will rename it to `athaliana.fasta.masked`

```bash
mv athaliana.fasta.masked athaliana_softmasked.fasta
```




::::::::::::::::::::::::::::::::::::: challenge

## Exercise 1: Calculating STAR `--genomeSAindexNbases`

The STAR aligner requires the `--genomeSAindexNbases` parameter to be tuned based on genome size.
The recommended formula is `min(14, log2(GenomeLength)/2 - 1)`.

The Arabidopsis thaliana genome is approximately 119 Mb (119,000,000 bp).
What value should you use for `--genomeSAindexNbases`?

What about for a larger genome, such as *Zea mays* (~2,300 Mb)?

:::::::::::::: solution

## Solution

For **Arabidopsis thaliana** (~119 Mb):

```
log2(119000000) / 2 - 1 = 26.83 / 2 - 1 = 12.4
min(14, 12.4) = 12
```

So `--genomeSAindexNbases 12` is the correct value (as used in this lesson).

For **Zea mays** (~2,300 Mb):

```
log2(2300000000) / 2 - 1 = 31.1 / 2 - 1 = 14.55
min(14, 14.55) = 14
```

So `--genomeSAindexNbases 14` (the default) would be appropriate for maize.

As a rule of thumb: for genomes smaller than ~500 Mb, you should calculate and lower this value; for large genomes (over 1 Gb), the default of 14 is usually fine.

:::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

## Exercise 2: Choosing the Right Genome File

Different annotation tools have different requirements for repeat masking.
Given the genome files produced in this episode:

- `athaliana.fasta` (unmasked)
- `athaliana_softmasked.fasta` (soft-masked with RepeatMasker)

Which genome file should you use for each of the following tools, and why?

1. BRAKER3
2. Helixer
3. EASEL

:::::::::::::: solution

## Solution

1. **BRAKER3** -- Use `athaliana_softmasked.fasta`. BRAKER3 benefits from soft-masked genomes because its underlying gene finder (Augustus/GeneMark) can recognize repeat regions (in lowercase) and avoid predicting genes within transposable elements.

2. **Helixer** -- Use `athaliana.fasta` (unmasked). Helixer is a deep-learning-based tool that has been trained on both genic and repetitive sequences. It does not require or benefit from repeat masking.

3. **EASEL** -- Use `athaliana_softmasked.fasta`. EASEL's internal pipeline expects a soft-masked genome to improve the accuracy of gene predictions by de-prioritizing repetitive regions.

:::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::: keypoints

- Organizing files and directories ensures a reproducible and efficient workflow  
- Mapping RNA-seq reads to the genome provides essential evidence for gene prediction  
- Repeat masking prevents transposable elements from being mis-annotated as genes  
- Preprocessing steps are crucial for accurate and high-quality genome annotation

::::::::::::::::::::::::::::::::::::::::::::::::

