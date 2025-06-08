````markdown
# iBART (Corrected Edition)

An R package for symbolic regression via Bayesian Additive Regression Trees (BART), extended to **estimate “inside” constants** in descriptors of the form `log(x + C)`.

---

## Table of Contents

1. [Overview](#overview)  
2. [Key Features](#key-features)  
3. [Installation](#installation)  
4. [Usage](#usage)  
   - [Standard Pipeline](#standard-pipeline)  
   - [Inside-Constant Refinement](#inside-constant-refinement)  
5. [Package Structure](#package-structure)  
6. [Testing](#testing)  
7. [Examples](#examples)  
8. [Development Notes](#development-notes)  
9. [License & Acknowledgments](#license--acknowledgments)  

---

## Overview

iBART is a tool for discovering analytic regression formulas of the form  
\[
y \;=\; \sum_j \beta_j\,f_j\bigl(x_{i_j} + C_j\bigr)\,,
\]  
where each descriptor \(f_j\) may include an **“inside” constant** \(C_j\). This corrected edition adds:

- Automatic insertion and preservation of a `CONST` column  
- Descriptor generation that tags `+CONST` terms  
- A new refinement procedure to jointly optimize \(C\) and \(\beta\)  
- A self-validation test suite that recovers known formulas under zero-noise  

---

## Key Features

- **Descriptor Generation**  
  - Unary operators (`log`, `sqrt`, `abs`, …) applied to \(x_i + \texttt{CONST}\)  
  - Binary operators extended to include “feature + CONST” terms  

- **Inside-Constant Optimization**  
  - `refine_constants()` finds the best constant \(C\) inside each descriptor  
  - Returns both constant estimates and corresponding weights  

- **Self-Test Suite**  
  - `test_iBART.R` runs a zero-noise experiment to verify recovery of  
    \(\displaystyle y = 5\log(x_2 + 1.5) + 2\log(x_4 + 0.3)\)   

---

## Installation

Install the corrected iBART directly from GitHub:

```r
# if needed:
install.packages("devtools")

# then:
devtools::install_github(
  "yourusername/iBART",
  ref = "corrected",
  build_vignettes = TRUE
)
````

---

## Usage

### Standard Pipeline

```r
library(iBART)

# X: an n×p matrix of predictors
# y: numeric response vector
fit <- run_iBART(X, y)

# Access in-sample RMSE and selected descriptors
print(fit$in_sample_RMSE)
print(fit$descriptor_names)
print(fit$coefficients)
```

### Inside-Constant Refinement

```r
library(iBART)

# Suppose we suspect descriptors log(x2+CONST) and log(x4+CONST)
result <- refine_constants(
  X, y,
  descriptors = c("log(x2+CONST)", "log(x4+CONST)")
)

# View estimated constants and weights
print(result$constants)     # e.g. 1.5 and 0.3
print(result$coefficients)  # e.g. 5 and 2
```

---

## Package Structure

```
R/
├── descriptorGenerator.R   # Modified: generates +CONST descriptors
├── iBART.R                 # Modified: handles CONST column & test branch
├── operations.R            # Modified: extends operators to include CONST
├── utilis.R                # Modified: preserves +CONST when filtering
├── refine_constants.R      # New: joint C + β optimization
├── utils_constants.R       # New: helper for parsing and building +CONST terms
├── data.R                  # Unchanged: sample datasets
├── BART_iter.R             # Unchanged: core BART iterations
├── LASSO.R                 # Unchanged: L₁ regression stage
├── L_zero_regression.R     # Unchanged: zero-noise regression support
└── tests/
    └── test_iBART.R        # New: testthat suite for zero-noise recovery
```

---

## Testing

Run the self-validation suite with **testthat**:

```r
# from the package root:
install.packages("testthat")
library(testthat)

test_dir("R/tests")
```

---

## Examples

1. **Recovering a known formula**

   ```r
   set.seed(123)
   n  <- 250; p <- 10
   X  <- matrix(runif(n * p, -1, 1), nrow = n)
   colnames(X) <- paste0("x", 1:p)
   y  <- 5*log(X[,2] + 1.5) + 2*log(X[,4] + 0.3)

   # Zero-noise test
   test_iBART()  # should drive RMSE → 0 and report constants 1.5 & 0.3
   ```

2. **General workflow**

   ```r
   # 1. Generate descriptors
   descriptors <- generate_descriptors(X)

   # 2. Fit BART model
   bart_fit <- run_iBART(X, y)

   # 3. Refine constants for top descriptors
   top_descr <- bart_fit$descriptor_names[1:2]
   refined    <- refine_constants(X, y, descriptors = top_descr)
   plot(refined)  # visualizes fit & constant search surface
   ```

---

## Development Notes

* **`refine_constants.R`** uses `optim()` under the hood to tune constants.
* **`utils_constants.R`** provides

  * `parse_descriptor()` — splits a descriptor string into function, variable, and CONST
  * `build_design_matrix()` — evaluates `x + C` for each descriptor row
* To add new operators or extend other descriptor types, update **operations.R** and **descriptorGenerator.R** in tandem.

---

## License & Acknowledgments

* **License:** MIT
* **Acknowledgments:**

  * Original iBART implementation by *mattsheng*
  * Corrections and extensions by *\[Yunke Wan]* (\[[cnc.winky@gmail.com)])
  * Built and tested using **testthat**, **stats**, and **utils** from CRAN

---
