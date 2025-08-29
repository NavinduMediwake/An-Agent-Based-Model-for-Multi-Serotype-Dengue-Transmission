# Multi-Serotype Dengue Agent-Based Model

[![NetLogo](https://img.shields.io/badge/NetLogo-6.3.1-blue.svg)](https://ccl.northwestern.edu/netlogo/)
[![Python](https://img.shields.io/badge/Python-3.8+-green.svg)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)


A comprehensive agent-based model for simulating multi-serotype dengue transmission dynamics with quantified antibody-dependent enhancement (ADE) mechanisms, vector demographic processes, and environmental stochasticity.

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Model Documentation](#model-documentation)
- [Repository Structure](#repository-structure)
- [Usage Instructions](#usage-instructions)
- [Reproducing Results](#reproducing-results)
- [Parameters](#parameters)
- [Output Data](#output-data)
- [Validation](#validation)
- [Contributing](#contributing)
- [Citation](#citation)
- [Contact](#contact)

## Overview

This repository contains the implementation and analysis code for a spatially explicit agent-based model of multi-serotype dengue transmission developed in NetLogo 6.3.1. The model incorporates research-calibrated mechanisms including quantified antibody-dependent enhancement, vertical transmission in mosquitoes, demographic vector dynamics, and environmental rainfall effects.



## Key Features

### Biological Mechanisms
- **Four dengue serotypes** (DENV-1 to DENV-4) with independent circulation
- **Quantified ADE**: 1.5× transmission enhancement for secondary infections
- **Vertical transmission**: 2.43% efficiency from infected mosquitoes to offspring
- **Multi-stage disease progression**: Mild → Severe DHF → Critical DSS
- **Individual immune tracking**: Serotype-specific immunity development

### Vector Population Dynamics
- **Age-structured mosquito populations** with 5 demographic types
- **Research-calibrated lifespans** (25-30 days) and mortality rates
- **Rainfall-dependent reproduction** with carrying capacity regulation
- **Density-dependent competition** effects

### Spatial and Environmental Features
- **Spatially explicit transmission** with 3-patch (36-meter) infection radius
- **Random movement patterns** for both humans and mosquitoes
- **Environmental stochasticity** through rainfall variability
- **Population regulation** preventing extinction/explosion

## Installation

### Requirements

**NetLogo Model:**
- NetLogo 6.3.1 or later ([Download here](https://ccl.northwestern.edu/netlogo/download.shtml))
- Minimum 4GB RAM, 8GB recommended for large populations
- Compatible with Windows, macOS, and Linux

**Python Analysis:**
```bash
Python 3.8+
pandas >= 1.3.0
matplotlib >= 3.5.0
seaborn >= 0.11.0
scipy >= 1.7.0
numpy >= 1.21.0
```

### Setup Instructions

1. **Clone the repository:**
```bash
git clone https://github.com/YourUsername/dengue-multiserotype-abm.git
cd dengue-multiserotype-abm
```

2. **Install Python dependencies:**
```bash
pip install -r requirements.txt
```

3. **Verify NetLogo installation:**
   - Open NetLogo 6.3.1
   - Load `model/dengue_model.nlogo`
   - Confirm model loads without errors

## Quick Start

### Running a Basic Simulation

1. **Open the model:**
   - Launch NetLogo
   - Open `model/dengue_model.nlogo`

2. **Configure parameters** (use defaults for standard simulation):
   - Population: 1000 humans, 100 mosquitoes
   - Infection rate: 10%
   - Recovery rate: 10%
   - Simulation duration: 365 days

3. **Execute simulation:**
   ```netlogo
   setup
   repeat 365 [ go ]
   ```

4. **Export results:**
   - Use BehaviorSpace or manual data export
   - Save as CSV for analysis

### Analyzing Results

```bash
python scripts/dengue41_analysis.py
```

This generates comprehensive visualizations and statistical summaries.

## Model Documentation

### Agent Types

#### Human Agents
- **State variables**: `infected?`, `infected-serotype`, `immune-serotypes`, `infection-stage`, `days-infected`
- **Immunity tracking**: List of recovered serotypes (1-4)
- **Disease progression**: Daily probability-based transitions
- **Movement**: Random walk (1 patch/tick)

#### Mosquito Agents  
- **Demographics**: Age, lifespan (25-30 days), mosquito type (1-5)
- **Disease status**: `carrying-serotype?`, `serotype` (1-4)
- **Reproduction**: Rainfall-dependent birth rates with vertical transmission
- **Mortality**: Age-dependent + density-dependent death rates

### Disease Dynamics

**Primary Infections:**
- Base transmission probability: 10%
- Recovery rate: 10% daily (mild cases)
- Mortality rate: 0.05% daily

**Secondary+ Infections (ADE):**
- Enhanced transmission: 15% (1.5× increase)
- Severe disease risk: 2-10× higher
- Stage-specific mortality: 1-5% daily

## Repository Structure

```
dengue-multiserotype-abm/
├── model/
│   ├── dengue_model.nlogo          # Main NetLogo model
│   ├── parameters/                 # Parameter configuration files
│   └── experiments/                # BehaviorSpace experiment files
├── scripts/
│   ├── dengue41_analysis.py        # Main analysis script
│   ├── parameter_sweep.py          # Sensitivity analysis
│   └── utils/                      # Utility functions
├── data/
│   ├── dengue41.csv               # Primary simulation output
│   ├── validation/                # Validation datasets  
│   └── results/                   # Generated analysis results
├── docs/
│   ├── model_description.md       # Detailed model documentation
│   ├── parameter_guide.md         # Parameter descriptions
│   └── validation_results.md      # Model validation results
├── figures/                       # Generated visualizations
├── requirements.txt               # Python dependencies
├── LICENSE                        # MIT License
└── README.md                     # This file
```

## Usage Instructions

### Standard Simulation

1. **Setup parameters** via NetLogo interface sliders
2. **Initialize model**: Click `setup` button
3. **Run simulation**: Click `go` button repeatedly or use `forever`
4. **Monitor progress**: Use built-in plots and monitors

### Batch Experiments

Use NetLogo's BehaviorSpace for systematic parameter exploration:

```netlogo
experiment parameter-sweep [
  ["initial-humans" 500 1000 1500]
  ["initial-dengue-infection-rate" 0.05 0.1 0.15]
  ["human-recovery-rate" 0.05 0.1 0.15]
]
```

### Sensitivity Analysis

```bash
python scripts/parameter_sweep.py --parameter infection-rate --range 0.01,0.2,0.01
```

## Reproducing Results

### Main Paper Results

To reproduce the primary results reported in the paper:

1. **Run standard simulation:**
   ```netlogo
   set initial-humans 1000
   set initial-mosquitoes 100  
   set initial-dengue-infection-rate 0.1
   setup
   repeat 365 [ go ]
   ```

2. **Export data** to `dengue41.csv`

3. **Generate analysis:**
   ```bash
   python scripts/dengue41_analysis.py
   ```

**Expected outcomes:**
- Attack rate: ~73.9%
- Case fatality rate: ~0.52%
- ADE vulnerable population: ~24.1%
- Peak infections: Day 89

### Validation Studies

Reproduce model validation against literature:

```bash
python scripts/validation_analysis.py
```

This compares model outputs with published dengue transmission data.

## Parameters

### Core Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `initial-humans` | 1000 | 100-5000 | Initial human population |
| `initial-mosquitoes` | 100 | 50-500 | Initial mosquito population |
| `initial-dengue-infection-rate` | 0.1 | 0.01-0.3 | Transmission probability per bite |
| `human-recovery-rate` | 0.1 | 0.05-0.2 | Daily recovery probability (mild cases) |
| `initial-vertical-transmission-rate` | 0.0243 | 0.01-0.05 | Mosquito vertical transmission |
| `mosquito-lifespan` | 25-30 | 15-45 | Days (varies by mosquito type) |

### Research-Calibrated Values

Based on literature review:
- **ADE enhancement**: 1.5× (Katzelnick et al., 2017)
- **Vertical transmission**: 2.43% (Lam et al., 2020)  
- **Mosquito lifespan**: 25-30 days (laboratory studies)
- **Infection radius**: 36 meters (Mahmood et al., 2020)

## Output Data

### Primary Outputs

**Time Series Data** (`dengue41.csv`):
- Daily counts: susceptible, infectious, recovered, dead
- Immunity levels: single, multi-serotype immunity
- Vector dynamics: total, infected mosquitoes
- Disease severity: mild, severe, critical cases

**Summary Statistics**:
- Attack rates by serotype
- Case fatality rates
- Immunity distribution patterns
- Peak epidemic metrics

### Visualization Outputs

- Population dynamics over time
- Immunity development patterns  
- Severe disease progression
- Vector population dynamics
- Spatial transmission patterns

## Validation

The model has been validated against:

1. **Epidemiological data**: Attack rates (50-90%), CFR (1-20%)
2. **ADE research**: Secondary infection enhancement
3. **Vector studies**: Demographic parameters, vertical transmission
4. **Outbreak data**: Cuban dengue epidemics (1981-2002)

See `docs/validation_results.md` for detailed validation analyses.

## Contributing

We welcome contributions to improve the model and analysis. Please follow these guidelines:

1. **Fork the repository** and create a feature branch
2. **Follow coding standards**: Comment code thoroughly, use meaningful variable names
3. **Test changes**: Ensure model runs without errors
4. **Document modifications**: Update relevant documentation
5. **Submit pull request** with clear description of changes

### Reporting Issues

Please report bugs, feature requests, or questions via [GitHub Issues](https://github.com/YourUsername/dengue-multiserotype-abm/issues).

## Contact

**Research Supervisor**: Dr. Sudam Surasinghe  
**Institution**: Department of Mathematics, University of Colombo  
**Email**: [sudameng@gmail.com]

**Student Researchers**:
- Bandara W.M.S.C. (s16316)
- Mediwake M.W.N.V. (s16334) 
- Jayanath S.K.K.T. (s16316)
- Liyanage B.L.D.H.K. (s16325)
- Wimalasuriya S.M. (s16381)

---

**Keywords**: agent-based modeling, dengue, multi-serotype, antibody-dependent enhancement, vector dynamics, NetLogo, epidemiological modeling

**Last Updated**: [Date]
