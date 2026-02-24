---
title: Instructor Notes
---

## General Setup

Before the workshop:

1. Verify all training accounts (`trainXX`) can access both Negishi and Gilbreth clusters
2. Confirm the shared data is available at `/depot/workshop/data/annotation_workshop/`
3. Ensure `biocontainers` module loads correctly and all tool modules are accessible
4. Pre-stage the GeneMark license key for learners or provide download instructions
5. Test that GPU allocation works on Gilbreth for the Helixer episode

## Timing Guide

| Episode | Teaching | Exercises | Notes |
|:--------|:--------:|:---------:|:------|
| Introduction | 20 min | 0 min | Conceptual, no hands-on |
| Annotation Strategies | 20 min | 5 min | Conceptual with exercises |
| Annotation Setup | 15 min | 5 min | Walk through only; steps are pre-computed |
| Gene Annotation with BRAKER | 40 min | 10 min | Submit jobs early; review results while waiting |
| Gene Annotation with Helixer | 20 min | 5 min | Requires Gilbreth cluster; switch clusters during break |
| Gene Annotation with EASEL | 25 min | 5 min | Optional/self-guided if time is short |
| Functional Annotation with EnTAP | 20 min | 5 min | Databases are pre-staged |
| Annotation Assessment | 30 min | 10 min | Compare all methods together |

## Common Learner Issues

### Cluster Access
- Learners may forget to switch to Gilbreth for the Helixer episode. Remind them during the break before that session.
- SSH key setup can be tricky on Windows. Have learners test access during the Arrival & Setup period.

### Module Loading
- Always use `ml --force purge` before loading new modules. Without `--force`, sticky modules may cause conflicts.
- If `biocontainers` fails to load, check that the user's `.bashrc` does not have conflicting module commands.

### BRAKER3
- The GeneMark license key must be in `~/.gm_key`. If learners get a "license key not found" error, have them re-copy the key.
- AUGUSTUS config must be writable. Ensure the `copy_augustus_config` step completed successfully.
- Jobs take 7-170 minutes depending on the case. Submit all 5 cases at the start and check results later.

### Helixer
- GPU availability on Gilbreth may be limited. Use `--account=standby` for opportunistic scheduling.
- Model download to `~/.local/share/Helixer` can be slow. Consider pre-staging models.

### EASEL
- Nextflow version matters. The custom installation step avoids conflicts with the system module.
- The `rcac.config` must be correctly placed and referenced in `nextflow.config`.
- If the pipeline fails, check `.nextflow.log` and the `work/` directory for process-level logs.

### EnTAP
- Databases are large and pre-staged at `/depot/itap/datasets/entap_db/`. Learners should not re-download them.
- The `entap_config.ini` paths must point to the correct database locations.

### Assessment
- BUSCO lineage dataset for Arabidopsis is `brassicales_odb10`. Double-check learners use the correct lineage.
- The OMArk database (`LUCA.h5`) is pre-staged at `/depot/itap/datasets/omark/`.

## Challenge Exercise Answers

Answers to all challenge exercises are included in the `:::::: solution` blocks within each episode. Review these before the workshop to anticipate follow-up questions.
