# Copyright (c) Facebook, Inc. and its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================

#' Misclassification correction via rmle
#'
#' @name mc_rmle
#' @section Notation:
#' See package level docstring for notation.
#' We use `m` for the number of subgroups.
#'
#' @section See paper:
#' T. K. MAK, W. K. LI, A new method for estimating subgroup means under
#' misclassification, Biometrika, Volume 75, Issue 1, March 1988,
#' Pages 105–111, https://doi.org/10.1093/biomet/75.1.105
#'
#' @section Notation:
#'
#' See package level docstring for notation.
#' We use `m` for the number of subgroups.
#'
#' @param n_jd_P length-m vector of counts in the primary data by misclassified
#'     groups.
#' @param y_sum_jd_P length-m vector of sum(y) in the primary data by
#'     misclassified groups.
#' @param n_ji_V a `m`x`m` matrix of counts in the validation data with rows
#'        for misclassified and columns for true groups.
#' @param y_sum_ji_V a `m`x`m`  matrix of sum(y) in the validation data with
#'     rows for misclassified and columns for true groups.
#' @param y2_sum_ji_V a `m`x`m` matrix of sum(y ^ 2) in the validation data
#'        with rows for misclassified and columns for true groups.
#' @return Matrix with the follow columns:
#'         mak_li: estimates of mu's.
#'         variance: estiamtes of variances.
#' @export
mc_rmle = function(n_jd_P,  y_sum_jd_P, n_ji_V, y_sum_ji_V, y2_sum_ji_V) {

    assertthat::assert_that(is.vector(n_jd_P))
    m = length(n_jd_P)
    assertthat::assert_that(length(y_sum_jd_P) == m)
    assertthat::assert_that(all(dim(n_ji_V) == c(m, m)))
    assertthat::assert_that(all(dim(y_sum_ji_V) == c(m, m)))
    assertthat::assert_that(all(dim(y2_sum_ji_V) == c(m, m)))

    # primary data
    n_dd_P = sum(n_jd_P)
    # validation data
    n_jd_V = rowSums(n_ji_V)
    n_di_V = colSums(n_ji_V)
    n_dd_V = sum(n_di_V)
    y_sum_di_V = colSums(y_sum_ji_V)
    y_sum_jd_V = rowSums(y_sum_ji_V)
    y_bar_di_V = y_sum_di_V / n_di_V
    y_bar_jd_V = y_sum_jd_V / n_jd_V
    y2_sum_jd_V = rowSums(y2_sum_ji_V)

    v_hat_jd = (y_sum_jd_V + y_sum_jd_P) / (n_jd_V + n_jd_P)
    V = diag(
        (
            y2_sum_jd_V / n_dd_V -
            y_sum_jd_V ^ 2 / n_jd_V / n_dd_V
        ) / (n_jd_V ^ 2) * n_dd_V ^ 2
    )

    m_ji = n_jd_V %*% t(n_di_V)

    U = (
        y2_sum_ji_V / m_ji * n_dd_V  +
        y_sum_jd_V %*% t(y_sum_di_V) *
            n_ji_V / m_ji ^ 2 * n_dd_V -
        y_sum_ji_V %*% diag(y_sum_di_V / n_di_V) / m_ji * n_dd_V  -
        diag(y_sum_jd_V / n_jd_V) %*% y_sum_ji_V / m_ji * n_dd_V
    )
    B = solve(V) %*% U
    mak_li = c(y_bar_di_V - t(B) %*% (y_bar_jd_V - v_hat_jd))
    mak_li_var = diag(
        # error in formula for w: \sum Y^2_{jik} should be over j, k.
        n_dd_V * (colSums(y2_sum_ji_V) / n_di_V - y_bar_di_V ^ 2) /
            n_di_V -
        t(U) %*% solve(V) %*% U * n_dd_P / (n_dd_P + n_dd_V)
    ) / n_dd_V

    return(cbind(mak_li, mak_li_var))
}
