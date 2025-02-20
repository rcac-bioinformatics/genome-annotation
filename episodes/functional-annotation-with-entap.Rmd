---
title: 'Functional annotation using EnTAP'
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- What is EnTAP, and how does it improve functional annotation for non-model transcriptomes?
- How does EnTAP filter, annotate, and assign functional roles to predicted transcripts?
- What databases and evidence sources does EnTAP integrate for annotation?
- What are the key steps required to set up and execute EnTAP on an HPC system?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Understand how EnTAP improves functional annotation for non-model eukaryotes.
- Learn how EnTAP processes transcript data through filtering, alignment, and functional assignment.
- Set up and modify EnTAP configuration files for correct execution.
- Run EnTAP on an HPC system and interpret the generated annotations.

::::::::::::::::::::::::::::::::::::::::::::::::

## EnTAP Overview

EnTAP is a bioinformatics pipeline designed to enhance the accuracy, speed, and flexibility of functional annotation for de novo assembled transcriptomes in non-model eukaryotic organisms. It mitigates assembly fragmentation, improves annotation rates, and provides extensive functional insights into transcriptomes. You can provide predicted transcripts in FASTA format and a GFF file containing gene models to run EnTAP.

::: callout

## Key Features

- **Optimized for non-model eukaryotes** – Overcomes challenges of fragmented transcriptome assemblies.
- **Fast & efficient** – Runs significantly faster than comparable annotation tools.
- **Customizable** – Supports optional filtering and analysis steps for user-specific needs.
- **Comprehensive functional insights** – Integrates multiple annotation sources for high-confidence gene assignments.
- **Contaminant detection** – Helps remove misleading sequences for cleaner datasets.

:::


## How EnTAP Works

1. **Transcriptome Filtering** – Identifies true coding sequences (CDS) and removes assembly artifacts:
   - **Expression Filtering (optional)** – Filters transcripts based on gene expression levels using RSEM.
   - **Frame Selection (optional)** – Further refines CDS predictions using TransDecoder.

2. **Transcriptome Annotation** – Assigns functional information to sequences:
   - **Similarity Search** – Rapid alignment against user-selected databases using DIAMOND.
   - **Contaminant Filtering & Best Hit Selection** – Identifies optimal annotations and flags potential contaminants.
   - **Orthologous Group Assignment** – Assigns translated proteins to gene families using **eggNOG/eggnog-mapper**, including:
     - **Protein Domains** (SMART/Pfam)
     - **Gene Ontology (GO) Terms**
     - **KEGG Pathway Annotation**
   - **InterProScan (optional)** – Searches InterPro databases for additional domain, GO, and pathway annotations.
   - **Horizontal Gene Transfer Analysis (optional)** – Detects potential horizontal gene transfer (HGT) events via DIAMOND.



## Running EnTAP

EnTAP is available as a module on the HPC cluster. You can load the module using the following commands:

```bash
ml --force purge
ml biocontainers
ml entap
```

:::::::::::::::::::::::::::::::::::::::  prereq

## First-Time Setup

When running for the first time, you will have to set up the databases for EnTAP. This includes downloading files from various databases, and can be time consuming. This section is already performed so you can skip this step and is included for reference.

:::::::::::::::::::::::::::::::::::::::  


:::::::::::::::::::::::::::::::::::::::::: spoiler

## Setting up databases (optional)

`entap_run.params` file should be setup as follows (be sure to select the correct `databases` for your organism):


```ini
out-dir=entap_dbfiles
overwrite=false
resume=false
input=
database=uniprot_sprot,refseq_plant
no-trim=false
threads=1
output-format=1,3,4,7,
fpkm=0.5
align=
single-end=false
frame-selection=false
transdecoder-m=100
transdecoder-no-refine-starts=false
taxon=
qcoverage=50
tcoverage=50
contam=
e-value=1e-05
uninformative=conserved,predicted,unknown,unnamed,hypothetical,putative,unidentified,uncharacterized,uncultured,uninformative,
diamond-sensitivity=very-sensitive
ontology_source=0,
eggnog-contaminant=true
eggnog-dbmem=true
eggnog-sensitivity=more-sensitive
interproscan-db=
hgt-donor=
hgt-recipient=
hgt-gff=
ncbi-api-key=
ncbi-api-enable=true
```

`entap_config.ini` file should be setup as follows (be sure to modify the paths `<custom_location>` to your desired location):

```ini
data-generate=false
data-type=0,
entap-db-bin=<custom_location>/entap_db/bin/entap_database.bin
entap-db-sql=entap_database.db
entap-graph=entap_graphing.py
rsem-calculate-expression=rsem-calculate-expression
rsem-sam-validator=rsem-sam-validator
rsem-prepare-reference=rsem-prepare-reference
convert-sam-for-rsem=convert-sam-for-rsem
transdecoder-long-exe=TransDecoder.LongOrfs
transdecoder-predict-exe=TransDecoder.Predict
diamond-exe=diamond
eggnog-map-exe=emapper.py
eggnog-map-data=<custom_location>/entap_db/databases
eggnog-map-dmnd=<custom_location>/entap_db/bin/eggnog_proteins.dmnd
interproscan-exe=interproscan.sh

```

Once done, for the first time setup, you can run the following command:


```bash
ml --force purge
ml biocontainers
ml entap
EnTAP \
   --config \
   --run-ini ./entap_run.params \
   --entap-ini ./entap_config.ini \
   --threads ${SLURM_CPUS_ON_NODE}
```

This will download the databases and set up the configuration files for EnTAP.

::::::::::::::::::::::::::::::::::::::::::::::::::



## **Step 1:** Prepare files


Your input files should be in the following format:

- **Transcript FASTA file** – Contains predicted transcripts in FASTA format.
- **Configuration file** – Specifies parameters for EnTAP execution.
    * `entap_run.params` – Contains runtime parameters for EnTAP.
    * `entap_config.ini` – Specifies paths to EnTAP binaries and databases.
    (you can copy the files from `/depot/itap/datasets/entap_db/entap_{config.ini,run.params}`)

Edit the `entap_run.params` file to specify the output directory for EnTAP results and the correct input file

```ini
out-dir=entap_out
input=input_cds.fasta
```



## **Step 2:** Run EnTAP

Run EnTAP using the following command:

```bash
ml --force purge
ml biocontainers
ml entap
EnTAP -\
   -run \
   --run-ini ./entap_run.params \
   --entap-ini ./entap_config.ini \
   --threads ${SLURM_CPUS_ON_NODE}
```

## Interpreting Results

EnTAP generates several output files, but the key results will be in the `entap_out/final_results` directory.


**EnTAP Output Files Summary**

| **File/Directory**                           | **Description** |
|:-----------|----------------|
| **Final Results (`final_results/`)** |
| `annotated.fnn`                             | FASTA file of **annotated** transcripts. |
| `annotated.tsv`                             | Tab-separated file with **functional annotations**. |
| `annotated_gene_ontology_terms.tsv`         | GO terms assigned to annotated transcripts. |
| `entap_results.tsv`                         | **Master summary** of all results, including annotations. |
| `unannotated.fnn`                           | FASTA file of **unannotated** transcripts. |
| `unannotated.tsv`                           | List of transcripts that **failed** annotation. |
| **`gene_family/`**             | Stores **eggNOG** gene family assignments, including orthologs and functional annotations. |
| **`similarity_search/`**       | Contains results from **DIAMOND BLASTX** searches against selected databases. |
| **`transcriptomes/`**          | Holds the **input transcriptome (CDS)** and the **processed** version after filtering. |




::::::::::::::::::::::::::::::::::::: keypoints 

- EnTAP enhances functional annotation by integrating multiple evidence sources, including homology, protein domains, and gene ontology.
- Proper setup of configuration files and databases is essential for accurate and efficient EnTAP execution.
- Running EnTAP involves transcript filtering, similarity searches, and functional annotation through automated workflows.
- The pipeline provides extensive insights into transcript function, improving downstream biological interpretations.

::::::::::::::::::::::::::::::::::::::::::::::::
