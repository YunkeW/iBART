#' @title Refine constants in iBART descriptors
#' @description Optimizes both inside constants (c in log(x+c)) and outside weights (β) for selected descriptors
#' @param descriptors Vector of descriptor strings (e.g. c("log((x.2+CONST))", "sin((x.3+CONST))"))
#' @param X Design matrix
#' @param y Response vector
#' @return List containing optimized parameters and model fit
refine_constants <- function(descriptors, X, y) {
  # descriptors: character vector like c("log((x.2+CONST))", "log((x.4+CONST))", …)
  # X: original feature matrix (no CONST column)
  # y: original response

  # 1) Figure out which descriptor j has an "inside constant"
  has_C <- grepl("\\+CONST\\)", descriptors)
  C         <- rep(NA_real_, length(descriptors))
  C[!has_C] <- 0     # no constant for any pure feature

  # 2) For each descriptor with a CONST, do a 1-D optimize over C_j:
  #    we hold all other C_k fixed at their current values
  for (j in which(has_C)) {
    # build a function that, given c, returns the in-sample RMSE
    f_rmse <- function(cj) {
      C[j] <- cj
      # build the design matrix phi with current C's
      Phi <- build_design_matrix(
        X = X,
        descriptor_strings = descriptors,
        C = C
      )
      # solve via ordinary least squares
      fit <- lm(y ~ 0 + Phi)
      sqrt(mean((y - predict(fit))^2))
    }
    # bracket each C_j in a reasonable range, say [0, 5]
    opt <- optimize(f_rmse, interval = c(0, 5))
    C[j] <- opt$minimum
  }

  # 3) Now build the final design with all C's
  Phi_final <- build_design_matrix(X = X, descriptor_strings = descriptors, C = C)
  final_fit <- lm(y ~ 0 + Phi_final)

  # 4) Return a list in the same format as before
  list(
    inside_constants  = C,
    outside_weights    = coef(final_fit),
    intercept          = 0,      # we already absorbed intercept via the CONST column
    model              = final_fit
  )
} 