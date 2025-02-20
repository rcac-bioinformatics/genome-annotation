---
title: Setup
---

## Instructors

1. **Arun Seetharam, Ph.D.**: Arun is a lead bioinformatics scientist at Purdue University’s Rosen Center for Advanced Computing. With extensive expertise in comparative genomics, genome assembly, annotation, single-cell genomics,  NGS data analysis, metagenomics, proteomics, and metabolomics. Arun supports a diverse range of bioinformatics projects across various organisms, including human model systems.

2. **Charles Christoffer, Ph.D.**: Charles is a Senior Computational Scientist at Purdue University’s Rosen Center for Advanced Computing. He has a Ph.D. in Computer Science in the area of structural bioinformatics and has extensive experience in protein structure prediction. 


## Schedule

| **Time**  | **Session**  |
|:---|-------------|
| **8:30 AM** | Arrival & Setup  |
| **9:00 AM** | **Introduction & Annotation Strategies** – Overview of genome annotation, structural vs. functional annotation, key challenges, and selecting the right pipeline |
| **10:30 AM** | **Break** |
| **10:40 AM** | **Gene Annotation with BRAKER** – Running BRAKER for ab initio and RNA-seq-supported annotation, gene model evaluation |
| **12:00 PM** | **Lunch Break** |
| **1:00 PM** | **Interpreting BRAKER Results & Gene Annotation with Helixer** – Reviewing BRAKER outputs, refining predictions, and using Helixer for deep-learning-based annotation |
| **2:50 PM** | **Break** |
| **3:10 PM** | **Functional Annotation with EnTAP & Annotation Quality Assessment** – Assigning gene functions, GO term mapping, evaluating completeness with BUSCO, and benchmarking gene models |
| **4:30 PM** | **Wrap-Up & Discussion** – Troubleshooting, Q&A, and next steps |




## What is not covered

1. Gene prediction using MAKER
2. Evidence based gene prediction (EviAnn, EVidenceModeler)
3. Genome assembly
4. Comparative analyses

## Pre-requisites

1. Basic knowledge of genomics
2. Basic knowledge of command line interface
3. Basic knowledge of bioinformatics tools



## Data Sets

To copy only data:

```bash
rsync -avP /depot/workshop/data/annotation_workshop ${RCAC_SCRATCH}/
```

The worked out folder is available at `/depot/workshop/data/annotation_workshop-results` on the training cluster. You can copy the data to your scratch space using the following command:

```bash
rsync -avP /depot/workshop/data/annotation_workshop-results ${RCAC_SCRATCH}/
```

Only use this if you are unable to finish the exercises in the workshop.

You only need one directory on Gilbreth cluster. See below for details.

::::::::::::::::::::::::::::::::::::::: spoiler

## For Gilbreth Cluster only


```bash
rsync -avP /depot/workshop/data/annotation_workshop/05_helixer ${RCAC_SCRATCH}/
```

::::::::::::::::::::::::::::::::::::::::




## Software Setup


::::::::::::::::::::::::::::::::::::::: discussion

### Details

SSH key setup for different systems is detailed in the expandable sections below.

:::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::: solution

### Windows

Open a terminal and run:

```sh
ssh-keygen -b 4096 -t rsa
type .ssh\id_rsa.pub | ssh trainXX@negishi.rcac.purdue.edu "mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys"
```

:::::::::::::::::::::::::

:::::::::::::::: solution

### MacOS

Open Terminal and run
```sh
ssh-keygen -b 4096 -t rsa
cat .ssh/id_rsa.pub | ssh trainXX@negishi.rcac.purdue.edu "mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys"
```

:::::::::::::::::::::::::


:::::::::::::::: solution

### Linux

Open a terminal and run:
```sh
ssh-keygen -b 4096 -t rsa
cat .ssh/id_rsa.pub | ssh trainXX@negishi.rcac.purdue.edu "mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys"
```

:::::::::::::::::::::::::



