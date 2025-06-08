# Test file for iBART package

# ─────────────────────────────────────────────────────────────────────────────
# 1) Configure Java heap BEFORE loading bartMachine (to avoid OOM)
# ─────────────────────────────────────────────────────────────────────────────
options(java.parameters = "-Xmx4g")  # 4 GB of Java heap

library(testthat)
library(bartMachine)
library(glmnet)

# Force bartMachine to run on a single core
bartMachine::set_bart_machine_num_cores(1)

# ─────────────────────────────────────────────────────────────────────────────
# 2) Source all of our package‐level files in the proper order
# ─────────────────────────────────────────────────────────────────────────────
source("BART_iter.R")
source("LASSO.R")
source("L_zero_regression.R")
source("operations.R")
source("utilis.R")
source("descriptorGenerator.R")
source("generate_unit.R")
source("data.R")
source("iBART.R")
source("refine_constants.R")

# ─────────────────────────────────────────────────────────────────────────────
# 3) Make all random‐number draws reproducible
# ─────────────────────────────────────────────────────────────────────────────
set.seed(123)

# ─────────────────────────────────────────────────────────────────────────────
# 4) (Optional) If you need to cd into the folder, do it here.  Otherwise,
#    just ensure your working directory *already* contains all the .R files.
# ─────────────────────────────────────────────────────────────────────────────
# setwd("C:/Users/78641/Downloads/ori")

# ─────────────────────────────────────────────────────────────────────────────
# Test: "iBART works with inside constants (exact recovery)"
#
#    We use n = 2000, zero noise.  By using opt = c("binary", "unary"),
#    we force iBART to create two separate columns:
#       "log((x.2+CONST))"   and   "log((x.4+CONST))"
#    in iteration 1.  Because hold = 2 and length(opt)=2, there is no BART call
#    at all.  iBART immediately jumps to the final L₀ regression, which
#    selects exactly those two log columns with inside‐constants 1.5 and 0.3.
#    The final in‐sample RMSE will be on the order of 1 × 10⁻¹⁴, so we test
#    for < 1 × 10⁻¹² to accommodate floating‐point.
# ─────────────────────────────────────────────────────────────────────────────
test_that("iBART works with inside constants (exact recovery)", {
  n <- 2000
  p <- 5
  X <- matrix(runif(n * p, min = 0.1, max = 5), nrow = n, ncol = p)
  colnames(X) <- paste0("x.", 1:p)

  # Ground‐truth (zero noise):
  #   y = 5 * log(x.2 + 1.5) + 2 * log(x.4 + 0.3)
  y <- 5 * log(X[, 2] + 1.5) + 2 * log(X[, 4] + 0.3)

  iBART_results <- iBART(
    X       = X,
    y       = y,
    name    = colnames(X),
    unit    = NULL,
    # First do binary to add constants, then unary to apply log
    opt         = c("binary", "unary"),
    sin_cos = FALSE,
    apply_pos_opt_on_neg_x = FALSE,
    pre_screen  = FALSE,
    hold        = 2,
    Lzero = TRUE,
    K = 2,  # Exactly two descriptors
    aic = FALSE,  # Pick by CV-MSE only
    standardize = FALSE,
    seed = 123
  )

  # Print the predicted formula
  cat("\nPredicted Formula:\n")
  pred_formula <- paste(
    "y =",
    paste(
      sprintf("%.4f * %s", 
              iBART_results$coefficients[-1],  # exclude intercept
              iBART_results$descriptor_names),
      collapse = " + "
    )
  )
  cat(pred_formula, "\n")

  # Print the true formula
  cat("\nTrue Formula:\n")
  true_formula <- "y = 5 * log(x.2 + 1.5) + 2 * log(x.4 + 0.3)"
  cat(true_formula, "\n")

  # Check that we have the exact log terms with inside constants
  expect_true(all(c("log((x.2+CONST))", "log((x.4+CONST))") %in% iBART_results$descriptor_names),
              info = paste("Expected exactly log((x.2+CONST)) and log((x.4+CONST)) among:\n  ->",
                          paste(iBART_results$descriptor_names, collapse = ", ")))

  # Check that the RMSE is very small (zero noise case)
  expect_true(iBART_results$in_sample_RMSE < 1e-12,
              info = paste("In-sample RMSE = ", iBART_results$in_sample_RMSE,
                          "(expected < 1e-12)"))
})

# ─────────────────────────────────────────────────────────────────────────────
# Sanity checks: Make sure all files/functions actually exist
# ─────────────────────────────────────────────────────────────────────────────
file.exists("iBART.R")            # should be TRUE
file.exists("refine_constants.R")  # should be TRUE
file.exists("utils_constants.R")   # should be TRUE

exists("build_design_matrix")      # TRUE (from refine_constants.R)
exists("parse_descriptor")         # TRUE
exists("refine_constants")         # TRUE


