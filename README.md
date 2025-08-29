# Multi-Serotype Dengue Agent-Based Model

[![NetLogo](https://img.shields.io/badge/NetLogo-6.3.1-blue.svg)](https://ccl.northwestern.edu/netlogo/)
[![Python](https://img.shields.io/badge/Python-3.8+-green.svg)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A comprehensive agent-based model for simulating multi-serotype dengue transmission dynamics with quantified antibody-dependent enhancement (ADE) mechanisms, vector demographic processes, and environmental stochasticity.

---

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Usage Instructions](#usage-instructions)
- [Output Data](#output-data)
- [Results Preview](#results-preview)
- [Contact](#contact)

---

## Overview

This repository contains the **NetLogo model** and **Python analysis tools** used for simulating and analyzing multi-serotype dengue transmission. The workflow is:

1. Run the agent-based model (`dengue_model.nlogo`) in NetLogo.  
2. Export daily epidemic outputs as CSV (example provided: `dengue4.csv`).  
3. Use the Python analysis scripts for comprehensive data analysis and publication-quality visualization.

### Key Features

- **Multi-serotype dengue modeling** with 4 circulating virus strains
- **Individual immune history tracking** across all serotypes
- **Antibody-dependent enhancement (ADE)** implementation based on epidemiological literature
- **Vector population dynamics** with density-dependent regulation
- **Disease severity progression** (mild → severe → critical)
- **Research-validated parameters** from peer-reviewed studies
- **Professional analysis pipeline** generating publication-ready outputs

---

## Installation

### Requirements

**NetLogo Model**
- NetLogo 6.3.1 or later ([Download here](https://ccl.northwestern.edu/netlogo/download.shtml))

**Python Analysis**
- Python 3.8+  
- Required packages:
  ```bash
  pip install pandas numpy matplotlib seaborn scipy jupyter
  ```

**Complete Installation**
```bash
# Clone the repository
git clone https://github.com/yourusername/dengue-multiserotype-abm.git
cd dengue-multiserotype-abm

# Install Python dependencies
pip install -r requirements.txt

# Start analysis environment
jupyter lab
```

---

## Quick Start

### 1. Run the Model in NetLogo

1. Open **NetLogo**.
2. Load **`dengue_model.nlogo`**.
3. Click **setup** then **go** to simulate.
4. Export daily results as CSV using BehaviorSpace or manual export.

You can use the included **`dengue4.csv`** if you don't want to re-run the model immediately.

### 2. Analyze Results in Python

**Option A: Professional Research Analysis**
```python
# Run comprehensive publication-quality analysis
from professional_dengue_analysis import analyze_dengue_for_publication

analyzer, results = analyze_dengue_for_publication('dengue4.csv')
```

**Option B: Jupyter Notebook**
```bash
jupyter lab
# Open dengue.ipynb and run all cells
```

---

## Repository Structure

```
dengue-multiserotype-abm/
├── dengue_model.nlogo              # NetLogo simulation model
├── dengue4.csv                     # Example simulation output
├── dengue.ipynb                    # Basic Jupyter analysis notebook
├── professional_dengue_analysis.py # Research-grade analysis pipeline
├── requirements.txt                # Python dependencies
├── figures/                        # Generated visualizations
│   ├── epidemic_dynamics.png
│   └── immunity_analysis.png
├── results/                        # Analysis outputs
│   ├── table_1_summary_statistics.csv
│   ├── results_section_text.txt
│   └── discussion_section_text.txt
└── README.md                       # This file
```

---

## Usage Instructions

### Basic Workflow

1. **Generate Simulation Data**
   - Use NetLogo to run `dengue_model.nlogo`
   - Export results as CSV format
   - Multiple replications recommended for statistical analysis

2. **Professional Analysis**
   ```python
   # Complete research pipeline
   python professional_dengue_analysis.py
   ```
   
   Generates:
   - High-resolution figures (300 DPI)
   - Statistical summary tables
   - Formatted results text for manuscripts
   - Professional figure captions

3. **Custom Analysis**
   - Use provided Jupyter notebook as template
   - Modify analysis parameters as needed
   - Extend visualizations for specific research questions

### Advanced Usage

**Multi-Run Analysis**
```python
# For multiple simulation replications
from professional_dengue_analysis import analyze_multi_run_experiment
analyzer, results, stats = analyze_multi_run_experiment('experiment_results.csv')
```

**Parameter Sensitivity Analysis**
- Use NetLogo BehaviorSpace for systematic parameter sweeps
- Import provided XML experiment configurations
- Analyze parameter sensitivity using included statistical tools

---

## Output Data

### Simulation Outputs (`dengue4.csv`)

The model generates comprehensive time series data including:

- **Population compartments**: Susceptible, infectious, recovered, deceased individuals
- **Multi-serotype immunity**: Individual immunity status for each of 4 serotypes
- **Disease severity**: Mild, severe (DHF), critical (DSS) case counts
- **Vector dynamics**: Total and infected mosquito populations
- **ADE metrics**: Secondary, tertiary, quaternary infection tracking

### Analysis Outputs

**Research Publications**
- `results_section_text.txt` - Formatted results for journal submission
- `discussion_section_text.txt` - Complete discussion section
- `figure_captions.txt` - Professional figure captions

**Data Tables**
- `table_1_summary_statistics.csv` - Key epidemiological metrics
- `supplementary_data_time_series.csv` - Complete temporal data

**Visualizations**
- Publication-quality figures (300 DPI PNG)
- Multi-panel epidemic dynamics analysis
- ADE risk assessment visualizations

---

## Results Preview

### Key Findings

The multi-serotype dengue model demonstrates:

- **High transmission efficiency**: 70.7% attack rate in susceptible populations
- **ADE vulnerability**: 22.7% of population at risk for severe secondary infections
- **Complex immunity patterns**: Heterogeneous serotype-specific immunity development
- **Literature validation**: Results consistent with epidemiological studies from endemic regions

### Sample Visualizations

![Epidemic Dynamics](figures/epidemic_dynamics_preview.png)
*Figure 1: Multi-panel analysis showing SEIR dynamics, attack rates, mortality progression, and vector population changes over 365-day simulation.*

![Immunity Analysis](figures/immunity_analysis_preview.png)  
*Figure 2: ADE risk assessment showing multi-serotype immunity distribution and severe disease risk stratification.*

### Model Validation

- Attack rates: 50-90% (consistent with urban dengue outbreaks)
- Case fatality rates: 1-20% (severe dengue in resource-limited settings)
- ADE vulnerability: 15-40% (matches endemic area prevalence)
- Immunity patterns: Validated against longitudinal cohort studies

---

## Contact

**Research Supervisor**  
Dr. Sudam Surasinghe  
Department of Mathematics, University of Colombo  
Email: sudameng@gmail.com

**Student Researchers**
- Bandara W.M.S.C. (s16316)
- Mediwake M.W.N.V. (s16334)  
- Jayanath S.K.K.T. (s16316)
- Liyanage B.L.D.H.K. (s16325)
- Wimalasuriya S.M. (s16381)

**Institution**: University of Colombo, Sri Lanka


## Keywords

`agent-based modeling` • `dengue fever` • `multi-serotype dynamics` • `antibody-dependent enhancement` • `vector-borne diseases` • `epidemiological modeling` • `NetLogo` • `computational epidemiology` • `public health` • `disease surveillance`

**Last Updated**: 2025-08-29
