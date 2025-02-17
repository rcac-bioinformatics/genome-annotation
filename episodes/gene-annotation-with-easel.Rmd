---
title: 'Annotation using Easel'
teaching: 10
exercises: 2
---

:::::::::::::::::::::::::::::::::::::: questions 

- to do1
- to do2
- to do3

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- to do1
- to do2
- to do3

::::::::::::::::::::::::::::::::::::::::::::::::


## 01_Setup

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




## 02_Running Easel
 
First, we will create a `rcac.config` file to run the jobs using `slurm` scheduler.

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
        cpus   = { check_max( 1    * task.attempt, 'cpus'   ) }
        memory = { check_max( 6.GB * task.attempt, 'memory' ) }
        time   = { check_max( 4.h  * task.attempt, 'time'   ) }
        clusterOptions = "-A ${params.project} -p ${params.partition}"

        errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
        maxRetries    = 1
        maxErrors     = '-1'

        withLabel:process_single {
            cpus   = { check_max( 1                  , 'cpus'    ) }
            memory = { check_max( 6.GB * task.attempt, 'memory'  ) }
            time   = { check_max( 4.h  * task.attempt, 'time'    ) }
        }
        withLabel:process_low {
            cpus   = { check_max( 2     * task.attempt, 'cpus'    ) }
            memory = { check_max( 12.GB * task.attempt, 'memory'  ) }
            time   = { check_max( 4.h   * task.attempt, 'time'    ) }
        }
        withLabel:process_medium {
            cpus   = { check_max( 8     * task.attempt, 'cpus'    ) }
            memory = { check_max( 36.GB * task.attempt, 'memory'  ) }
            time   = { check_max( 8.h   * task.attempt, 'time'    ) }
        }
        withLabel:process_high {
            cpus   = { check_max( 16    * task.attempt, 'cpus'    ) }
            memory = { check_max( 100.GB * task.attempt, 'memory'  ) }
            time   = { check_max( 16.h  * task.attempt, 'time'    ) }
        }
        withLabel:process_long {
            time   = { check_max( 20.h  * task.attempt, 'time'    ) }
        }
        withLabel:process_high_memory {
            memory = { check_max( 200.GB * task.attempt, 'memory' ) }
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


Second, we will pull the Easel nextflow workflow:

```bash
ml --force purge
ml biocontainers
ml nextflow
ml openjdk
nextflow pull -hub gitlab PlantGenomicsLab/easel
```

This will pull the latest version of the Easel workflow from the PlantGenomicsLab GitLab repository.

Third, we will modify the `~/.nextflow/assets/PlantGenomicsLab/easel/nextflow.config` file to include the `rcac.config` file:

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


Fourth, we will create `param.yaml` file to run the Easel workflow:


```bash
WORKSHOP_DIR="${RCAC_SCRATCH}/annotation_workshop"
mkdir -p ${WORKSHOP_DIR}/06_easel
cd ${WORKSHOP_DIR}/06_easel
```

for the `param.yaml` file:

```yaml
outdir    : "easel"
genome    : "/scratch/negishi/aseethar/annotation_workshop/00_datasets/genome/athaliana_softmasked.fasta"
bam       : "/scratch/negishi/aseethar/annotation_workshop/00_datasets/bamfiles/*.bam"
busco_lineage   : "embryophyta"
order : "Brassicales"
prefix     : "arabidopsis"
taxon : "arabidopsis"
singularity_cache_dir: "/scratch/negishi/aseethar/singularity_cache"
training_set : 'plant'
executor : 'slurm'
account: 'testpbs'
qos: 'normal'
project: testpbs
```

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
ml purge
ml biocontainers
ml openjdk
nextflow run \
   -hub gitlab PlantGenomicsLab/easel \
   -params-file params.yaml \
   -profile rcac \
   --project testpbs
```

This will run the Easel workflow on the RCAC HPC.
 
## 03_Results and Outputs

Interpreting Gene Predictions
Assessing Annotation Quality



::::::::::::::::::::::::::::::::::::: keypoints 

- to do1
- to do2
- to do3

::::::::::::::::::::::::::::::::::::::::::::::::

