---
title: 'Annotation using Helixer'
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- How to predict genes using Helixer?
- How to download trained models for Helixer?
- How to run Helixer on the HPC cluster (Gilbreth)?


::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives
- Learn how to predict genes using Helixer.
- Learn how to download trained models for Helixer.
- Learn how to run Helixer on the HPC cluster (Gilbreth).


::::::::::::::::::::::::::::::::::::::::::::::::



Helixer is a deep learning-based gene prediction tool that uses a convolutional neural network (CNN) to predict genes in eukaryotic genomes. Helixer is trained on a wide range of eukaryotic genomes and can predict genes in both plant and animal genomes. Helixer can predict genes wihtout any extrinisic information such as RNA-seq data or homology information, purely based on the sequence of the genome.


:::::::::::::::::::::::::::::::::::::::  prereq

## This section should be run on Gilbreth HPC cluster.

Due to the GPU requirement for Helixer, you need to run this section on the Gilbreth HPC cluster. You don't have to copy fastq, or bamfiles, but only need `athaliana.fasta` file in the `00_datasets/genome` directory. 


:::::::::::::::::::::::::::::::::::::::

```bash
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
mkdir -p ${WORKSHOP_DIR}/05_helixer
cp <depot_location>/genome/athaliana.fasta ${WORKSHOP_DIR}/05_helixer/athaliana.fasta
```

![Folder organization](https://github.com/user-attachments/assets/a1767236-304b-4912-8200-e2ea97ec63b8)




## Setup

Helixer is available as a Singularity/apptainer container. You can pull the container using the following `apptainer pull` command. See the [Helixer Docker](https://github.com/gglyptodon/helixer-docker) repository for more information.

Helixer is installed as a module on the Gilbreth cluster, and can be loaded using the following commands:


```bash
ml --force purge
ml biocontainers
ml helixer
```

## Downloading trained models

Helixer requires a trained model to predict genes. With the included script `fetch_helixer_models.py` you can download models for specific lineages. Currently, models are available for the following lineages:

- `land_plant`
- `vertebrate`
- `invertibrate`
- `fungi`

You can download the models using the following command:

```bash
# all models
# fetch_helixer_models.py --all
# or for a specific lineage
fetch_helixer_models.py --lineage land_plant
```

This will download all lineage models in the models directory. You can also download models for specific lineages using the `--lineage` option as shown above.

By default, files will be downloaded to `~/.local/share/Helixer` directory.
You should see the follwing files:

```
.
└── models
    └── land_plant
        ├── land_plant_v0.3_a_0080.h5
        ├── land_plant_v0.3_a_0090.h5
        ├── land_plant_v0.3_a_0100.h5
        ├── land_plant_v0.3_a_0200.h5
        ├── land_plant_v0.3_a_0300.h5
        ├── land_plant_v0.3_a_0400.h5
        ├── land_plant_v0.3_m_0100.h5
        └── land_plant_v0.3_m_0200.h5
```

`land_plant_v0.3_a_0080.h5` is the smallest model and `land_plant_v0.3_m_0200.h5` is the largest model.
The model size is determined by the number of parameters in the model. The larger models are more accurate but require more memory and time to run.

## Running Helixer

Helixer requires GPU for prediction. For running Helixer, you need to request a GPU node. You will also need the genome sequence in fasta format. For this tutorial, we will use Maize genome (Zea mays subsp. mays), and use the `land_plant` model to predict genes.

```bash
#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --gpus-per-node=1
#SBATCH --time=04:00:00
#SBATCH --account=standby
#SBATCH --job-name=helixer
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
ml --force purge
ml biocontainers
ml helixer
genome=athaliana.fasta
species="Arabidopsis thaliana"
output="athaliana_helixer.gff"
Helixer.py \
    --lineage land_plant \
    --fasta-path ${genome} \
    --species ${species} \
    --gff-output-path ${output}
```


A typical job will take ~40 mins to finish depedning on the GPU the job gets allocated.


You can count the nubmer of predictions in your gff3 file using the following command:

```bash
awk '$3=="gene"' athaliana_helixer.gff | wc -l
```


The GFF format output had 27,201 genes predicted using Helixer. You can view the various features in the gff file using the following command:

```bash
grep -v "^#" athaliana_helixer.gff |\
   cut -f 3 |\
   sort |\
   uniq -c
```

To get `cds` and `pep` files, you can use the following command:

```bash
ml --force purge
ml biocontainers
ml cufflinks
gffread Arabidopsis_thaliana.gff3 \
   -g athaliana.fasta \
   -y helixer_pep.fa \
   -x helixer_cds.fa
```


As you may have noticed, the number of mRNA and gene features are the same. 
This is because isoforms aren’t predicted by Helixer and you only have one transcript per gene.
Exons are indetified with high confidence and alternative isoforms are usually collapsed into a single gene model. 
This is one of the known limitations of Helixer.


::::::::::::::::::::::::::::::::::::: keypoints 

- Helixer is a deep learning-based gene prediction tool that uses a convolutional neural network (CNN) to predict genes in eukaryotic genomes.
- Helixer can predict genes wihtout any extrinisic information such as RNA-seq data or homology information, purely based on the sequence of the genome.
- Helixer requires a trained model and GPU for prediction. 
- Helixer predicts genes in the GFF3 format, but will not predict isoforms.

::::::::::::::::::::::::::::::::::::::::::::::::

