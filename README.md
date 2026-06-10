# Checkerboard Reversal VEP-Plasticity Preprocessing
This repository contains MATLAB scripts implementing the core EEG preprocessing and visual evoked potential (VEP) analysis pipeline (checkerboard reversal).  The provided code focuses on the essential steps required to reproduce the preprocessing and extraction of VEP components. Auxiliary, exploratory, and visualization scripts are not included. This paradigm is adapted from 
Normann C, Schmitz D, Fürmaier A, Döing C, Bach M. Long-term plasticity of visually evoked potentials in humans is altered in major depression. Biol Psychiatry. 2007 Sep 1;62(5):373-80. doi: 10.1016/j.biopsych.2006.10.006. Epub 2007 Jan 19. PMID: 17240361.

## Overview

The pipeline consists of two main stages:

1. **Preprocessing**

   * Loading raw EEG data (Curry `.cdt` format)
   * Event recoding and block assignment
   * Re-referencing (if applicable)
   * Band-pass filtering
   * Epoching and baseline correction
   * Artifact rejection based on amplitude thresholds

2. **VEP Extraction**

   * Extraction of ERP waveforms
   * Component quantification:

     * C1, P1, N1a (peak-based, Oz)
     * N1b (mean amplitude, P7/P8)
     * P2 (mean amplitude, Oz/POz)
   * Calculation of P1N1 amplitude

---

## Repository Structure

```text
preprocessing/
    preprocess_pipeline.m

functions/
    VEP_recodeEvents.m
    VEP_extractERPs.m
```

---

## Requirements

* MATLAB (tested with recent versions)
* EEGLAB toolbox
* `pop_loadcurry` support for loading Curry EEG files

Ensure EEGLAB is added to your MATLAB path before running the scripts.

---

## Usage

1. **Set paths in the preprocessing script**
   At the top of the script, specify:

   * path to raw EEG data
   * path for preprocessed output
   * path for ERP output

2. **Run preprocessing**
   Execute the preprocessing script:

   ```matlab
   preprocess_pipeline
   ```

3. **Output**
   For each subject:

   * Preprocessed EEG data (`*_VEP.mat`)
   * Extracted ERP measures (`*_VEP_ERP.mat`)

---

## Notes on Implementation

* Event recoding assumes stimulus triggers coded as `1` and `2`

* Block boundaries are defined by pauses > 2 seconds between events

* ERP components are extracted within predefined time windows:

  * C1: 50–100 ms
  * P1: 70–130 ms
  * N1a: 120–170 ms
  * N1b: 150–190 ms
  * P2: 225–280 ms

* Peak amplitudes (C1, P1, N1a) are derived from averaged Oz waveforms
* N1b and P2 are computed as mean amplitudes over predefined regions of interest

---

## Reproducibility
This repository provides the core preprocessing and analysis steps underlying the reported results. While not a fully automated end-to-end pipeline, the included scripts allow reconstruction of the key data processing stages.

---

## Contact

For questions regarding the pipeline, please contact the corresponding author.
