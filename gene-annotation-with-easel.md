---
title: 'Annotation using Easel'
teaching: 25
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- What are the steps required to set up and run EASEL on an HPC system?
- How is Nextflow used to manage and execute the EASEL workflow?
- What configuration files need to be modified before running EASEL?
- How do you submit and monitor an EASEL job using Slurm?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Set up and configure EASEL for execution on an HPC system.
- Install Nextflow and pull the EASEL workflow from the repository.
- Modify the necessary configuration files to match the HPC environment.
- Submit and run EASEL as a Slurm job and verify successful execution.

::::::::::::::::::::::::::::::::::::::::::::::::


EASEL (Efficient, Accurate, Scalable Eukaryotic modeLs) is a genome annotation tool that integrates machine learning, RNA folding, and functional annotations to improve gene prediction accuracy, leveraging optimized AUGUSTUS parameters, transcriptome and protein evidence, and a Nextflow-based scalable pipeline for reproducible analysis.


## Setup

We will do a custom installation of nextflow (we will not use `ml nextflow`):

```bash
ml --force purge
ml openjdk
curl -s https://get.nextflow.io | bash
mv nextflow ~/.local/bin
```

check the installation:

```bash
nextflow -v
which nextflow
```

We can organize our folder structure as follows:

![Folder organization](https://github.com/user-attachments/assets/ce52353b-f0c9-4fae-977f-58b2efa26bd1)




## Running Easel
 
**Step 1:** create a `rcac.config` file to run the jobs using `slurm` scheduler.

```bash
params {
    config_profile_description = 'Negishi HPC, RCAC Purdue University.'
    config_profile_contact     = 'Arun Seetharam (aseethar@purdue.edu)'
    config_profile_url         = "https://www.rcac.purdue.edu/knowledge/negishi"
    partition                  = 'testpbs'
    project                    = 'your_project_name'  // Replace with a valid Slurm project
    max_memory                 = '256GB'
    max_cpus                   = 128
    max_time                   = '48h'
}
singularity {
    enabled    = true
    autoMounts = true
    singularity.cacheDir = "${System.getenv('RCAC_SCRATCH')}/.singularity"
    singularity.pullTimeout = "1h"
}
process {
    resourceLimits = [
        memory: 256.GB,
        cpus: 128,
        time: 48.h
    ]
    executor       = 'slurm'
    clusterOptions = "-A ${params.project} -p ${params.partition}"
}
// Executor-specific configurations
if (params.executor == 'slurm') {
    process {
        cpus   = { check_max( 16    * task.attempt, 'cpus'   ) }
        memory = { check_max( 32.GB * task.attempt, 'memory' ) }
        time   = { check_max( 8.h  * task.attempt, 'time'   ) }
        clusterOptions = "-A ${params.project} -p ${params.partition}"

        errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
        maxRetries    = 1
        maxErrors     = '-1'

        withLabel:process_single {
            cpus   = { check_max( 16                  , 'cpus'    ) }
            memory = { check_max( 32.GB  * task.attempt, 'memory'  ) }
            time   = { check_max( 8.h    * task.attempt, 'time'    ) }
        }
        withLabel:process_low {
            cpus   = { check_max( 32     * task.attempt, 'cpus'    ) }
            memory = { check_max( 64.GB  * task.attempt, 'memory'  ) }
            time   = { check_max( 24.h   * task.attempt, 'time'    ) }
        }
        withLabel:process_medium {
            cpus   = { check_max( 64     * task.attempt, 'cpus'    ) }
            memory = { check_max( 128.GB * task.attempt, 'memory'  ) }
            time   = { check_max( 24.h   * task.attempt, 'time'    ) }
        }
        withLabel:process_high {
            cpus   = { check_max( 128    * task.attempt, 'cpus'    ) }
            memory = { check_max( 256.GB * task.attempt, 'memory'  ) }
            time   = { check_max( 24.h   * task.attempt, 'time'    ) }
        }
        withLabel:process_long {
            time   = { check_max( 48.h  * task.attempt, 'time'    ) }
        }
        withLabel:process_high_memory {
            memory = { check_max( 256.GB * task.attempt, 'memory' ) }
        }
        withLabel:error_ignore {
            errorStrategy = 'ignore'
        }
        withLabel:error_retry {
            errorStrategy = 'retry'
            maxRetries    = 2
        }
    }
}
```


**Step 2:**  pull the Easel nextflow workflow:

```bash
ml --force purge
ml biocontainers
ml nextflow
ml openjdk
nextflow pull -hub gitlab PlantGenomicsLab/easel
```

This will pull the latest version of the Easel workflow from the PlantGenomicsLab GitLab repository.

**Step 3:**  modify the `~/.nextflow/assets/PlantGenomicsLab/easel/nextflow.config` file to include the `rcac.config` file:

```bash
vim ~/.nextflow/assets/PlantGenomicsLab/easel/nextflow.config
```
 or if you prefer `nano`:

```bash
nano ~/.nextflow/assets/PlantGenomicsLab/easel/nextflow.config
```

Add the following line to the `nextflow.config` file:

```bash
profiles {
   debug { process.beforeScript = 'echo $HOSTNAME' }
   ...
   ...
   test  { includeConfig 'conf/test.config' }
   rcac  { includeConfig 'conf/rcac.config' }
}
```
Note that this is in line # 235 in the `nextflow.config` file. and all the lines between `debug` and `test` aren't shown here.

Now, we are ready to run the Easel workflow.


**Step 4:**  create `param.yaml` file to run the Easel workflow:


```bash
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
mkdir -p ${WORKSHOP_DIR}/06_easel
cd ${WORKSHOP_DIR}/06_easel
```

for the `param.yaml` file:

```yaml
outdir: easel
genome: /scratch/negishi/YOUR_USERNAME/annotation_workshop/00_datasets/genome/athaliana_softmasked.fasta
bam: /scratch/negishi/YOUR_USERNAME/annotation_workshop/00_datasets/bamfiles/*.bam
busco_lineage: embryophyta
order: Brassicales
prefix: arabidopsis
taxon: arabidopsis
singularity_cache_dir: /scratch/negishi/YOUR_USERNAME/singularity_cache
training_set: plant
executor: slurm
account: testpbs
qos: normal
project: testpbs
```

::: callout

## Update Paths in params.yaml

Replace `YOUR_USERNAME` with your actual username in the `params.yaml` file. You can find your username by running `whoami` on the cluster. For example, if your username is `train01`, the genome path would be:
`/scratch/negishi/train01/annotation_workshop/00_datasets/genome/athaliana_softmasked.fasta`

:::

Now we are ready to run the Easel workflow:


Our `slurm` file to run the Easel workflow:


```bash
#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --time=04-00:00:00
#SBATCH --job-name=easel
#SBATCH --output=%x.o%j
#SBATCH --error=%x.e%j
# Load the required modules
ml --force purge
ml biocontainers
ml openjdk
nextflow run \
   -hub gitlab PlantGenomicsLab/easel \
   -params-file params.yaml \
   -profile rcac \
   --project testpbs
```

This will run the Easel workflow on the RCAC HPC.
 
## Results and Outputs

EASEL produces output in the `easel/` directory (as specified by `outdir` in `params.yaml`). The key output files are:

| **File/Directory** | **Description** |
|:-------------------|:----------------|
| `easel/annotation/*.gff3` | Final gene predictions in GFF3 format |
| `easel/annotation/*.cds.fa` | Predicted coding sequences |
| `easel/annotation/*.pep.fa` | Predicted protein sequences |
| `easel/busco/` | BUSCO completeness assessment results |
| `easel/entap/` | Functional annotation results from EnTAP |
| `easel/pipeline_info/` | Nextflow execution reports and timelines |

You can check the gene count in the EASEL output:

```bash
awk '$3=="gene"' easel/annotation/*.gff3 | wc -l
```

:::::::::::::::::::::::::::::::::::::::::: spoiler

## Expected Output

For Arabidopsis thaliana, EASEL should predict approximately 25,000-30,000 genes. The pipeline also generates a BUSCO report automatically, which you can find in the `easel/busco/` directory.

Check the Nextflow execution report in `easel/pipeline_info/` to review runtime, resource usage, and any failed processes.

::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::: challenge

## Exercise 1: Adapting EASEL for a Different Organism

If you were annotating a vertebrate genome (e.g., zebrafish) instead of a plant genome, which parameters in the `params.yaml` file would you need to change? List all the parameters and explain why each would need updating.

:::::::::::::: solution

## Solution

You would need to change the following parameters in `params.yaml`:

- **`busco_lineage`**: Change from `embryophyta` (plants) to the appropriate vertebrate lineage (e.g., `actinopterygii` for ray-finned fish, or `vertebrata` for a broader assessment).
- **`order`**: Change from `Brassicales` to the correct taxonomic order for your organism (e.g., `Cypriniformes` for zebrafish).
- **`prefix`**: Change from `arabidopsis` to an appropriate prefix for your organism (e.g., `zebrafish` or `drerio`).
- **`taxon`**: Change from `arabidopsis` to your target organism name (e.g., `zebrafish`).
- **`training_set`**: Change from `plant` to the appropriate AUGUSTUS training set for your organism (e.g., `vertebrate` or a closely related species like `zebrafish`).

The genome, bam, and other path-related parameters would also change, but those are specific to your data rather than to the organism type.

:::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: challenge

## Exercise 2: Resuming a Failed EASEL Run

Your EASEL Nextflow pipeline failed partway through execution. How would you resume the run without recomputing already completed steps? Where would you look for error logs to diagnose the issue?

:::::::::::::: solution

## Solution

To resume a failed Nextflow run, add the `-resume` flag to your `nextflow run` command:

```bash
nextflow run \
   -hub gitlab PlantGenomicsLab/easel \
   -params-file params.yaml \
   -profile rcac \
   --project testpbs \
   -resume
```

Nextflow caches completed tasks, so only failed or pending steps will be re-executed.

To diagnose the failure, check these locations:

1. **`.nextflow.log`** in the working directory: Contains detailed Nextflow execution logs, including error messages and stack traces.
2. **`work/` directory**: Each task runs in a subdirectory under `work/`. Navigate to the failed task's directory (shown in the error output) and check the `.command.log`, `.command.err`, and `.command.out` files for the specific error.
3. **SLURM output files**: Check the `easel.o*` and `easel.e*` files for SLURM-level errors (e.g., memory limits, time limits).

:::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: keypoints

- EASEL is executed using Nextflow, which simplifies workflow management and ensures reproducibility.
- Proper configuration of resource settings and HPC parameters is essential for successful job execution.
- Running EASEL requires setting up input files, modifying configuration files, and submitting jobs via Slurm.
- Understanding how to monitor and troubleshoot jobs helps ensure efficient pipeline execution.

::::::::::::::::::::::::::::::::::::::::::::::::

