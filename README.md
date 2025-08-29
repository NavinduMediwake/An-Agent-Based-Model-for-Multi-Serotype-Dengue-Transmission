Got it ✅
Here’s the full README.md rewritten in the same detailed style as your original, but now including only the uploaded files: dengue_model.nlogo, dengue4.csv, and dengue.ipynb. You can paste this directly into GitHub.

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
- [Contact](#contact)

---

## Overview

This repository contains the **NetLogo model** and **Python Jupyter notebook** used for simulating and analyzing multi-serotype dengue transmission. The workflow is:

1. Run the agent-based model (`dengue_model.nlogo`) in NetLogo.  
2. Export daily epidemic outputs as CSV (example provided: `dengue4.csv`).  
3. Use the Jupyter notebook (`dengue.ipynb`) for data analysis and visualization.

---

## Installation

### Requirements

**NetLogo Model**
- NetLogo 6.3.1 or later ([Download here](https://ccl.northwestern.edu/netlogo/download.shtml))

**Python Notebook**
- Python 3.8+  
- JupyterLab or Notebook  
- Core packages:
  ```bash
  pandas
  numpy
  matplotlib
  seaborn
  scipy

Install everything at once:

pip install jupyterlab pandas numpy matplotlib seaborn scipy


⸻

Quick Start

1. Run the Model in NetLogo
	1.	Open NetLogo.
	2.	Load dengue_model.nlogo.
	3.	Click setup then go to simulate.
	4.	Export daily results as CSV.

You can use the included dengue4.csv if you don’t want to re-run the model immediately.

⸻

2. Analyze Results in Python
	1.	Start Jupyter:

jupyter lab

or

jupyter notebook


	2.	Open dengue.ipynb.
	3.	Run all cells.
	•	The notebook loads dengue4.csv by default.
	•	Replace with your own exported file if needed.

⸻

Repository Structure

dengue-multiserotype-abm/
├── dengue_model.nlogo       # NetLogo simulation model
├── dengue4.csv              # Example simulation output (CSV)
├── dengue.ipynb             # Jupyter notebook for analysis
└── README.md                # Documentation


⸻

Usage Instructions
	•	Use NetLogo to generate simulation outputs.
	•	Save results as CSV (replace dengue4.csv if you want to analyze your own runs).
	•	Open the notebook (dengue.ipynb) to generate plots and basic statistics.

⸻

Output Data

The included dengue4.csv contains:
	•	Time series of compartments (susceptible, infected, recovered, dead).
	•	Vector population dynamics (mosquito totals, infected mosquitoes).
	•	Disease severity (mild, severe, critical).

The notebook (dengue.ipynb) provides:
	•	Line plots of epidemic curves.
	•	Summary statistics (attack rate, peak day, mortality, etc.).

⸻

Contact

Research Supervisor: Dr. Sudam Surasinghe
Institution: Department of Mathematics, University of Colombo
Email: [sudameng@gmail.com]

Student Researchers:
	•	Bandara W.M.S.C. (s16316)
	•	Mediwake M.W.N.V. (s16334)
	•	Jayanath S.K.K.T. (s16316)
	•	Liyanage B.L.D.H.K. (s16325)
	•	Wimalasuriya S.M. (s16381)

⸻

Last Updated: 2025-08-29

Would you like me to also include a **sample plot screenshot section** (with a placeholder image link) so your GitHub repo looks more visually appealing?
