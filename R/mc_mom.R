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

#' Misclassification correction via mothod of moments
#'
#' @name mc_mom
#' @section Notation:
#' See package level docstring for notation.
#' We use `m` for the number of subgroups.
#'
#' @section See paper:
#'    Selén, Jan. “Adjusting for Errors in Classification and Measurement in
#'    the Analysis of Partly and Purely Categorical Data.” Journal of the
#'    American Statistical Association, vol. 81, no. 393, 1986, pp. 75–81.
#'    JSTOR, www.jstor.org/stable/2287969. Accessed 10 Aug. 2020.
#'
#' @param n_jd_P length-m vector of counts in the primary data by misclassified
#'     groups.
#' @param y_sum_jd_P length-m vector of sum(y) in the primary data by
#'     misclassified groups.
#' @param n_ji_V a `m`x`m` matrix of counts in the validation data with rows
#'     for misclassified and columns for true groups.
#' @param y_sum_ji_V a `m`x`m`  matrix of sum(y) in the validation data with
#'     rows for misclassified and columns for true groups. If NULL, the
#'     `validation` and `with_y_V` estimates will be NaN.
#' @return matrix with the following estimates of the per group mean:
#'         naive: the naive estimates using the misclassified groups.
#'         validation: estimates using just the validation data.
#'         no_y_V: estiamtes with both datasets but without using the `y` value
#'             in the validation data.
#'         with_y_V: estimates using all data, including the y value in the
#'             validation data.
#' @export
mc_momm = function(n_jd_P, y_sum_jd_P, n_ji_V, y_sum_ji_V=NULL) {

    assertthat::assert_that(is.vector(n_jd_P))
    m = length(n_jd_P)
    assertthat::assert_that(length(y_sum_jd_P) == m)
    assertthat::assert_that(all(dim(n_ji_V) == c(m, m)))
    if (!is.null(y_sum_ji_V)) assertthat::assert_that(all(dim(y_sum_ji_V) == c(m, m)))

    # primary data
    n_dd_P = sum(n_jd_P)
    # validation data
    n_jd_V = rowSums(n_ji_V)
    n_di_V = colSums(n_ji_V)
    n_dd_V = sum(n_di_V)

    # estimate p on validation data
    p_hat_dd_V = n_ji_V %*% diag(1 / n_di_V)

    # naive estimator
    y_bar_jd_P = y_sum_jd_P / n_jd_P
    naive = y_bar_jd_P

    # estimator assumming unknow p: formua 4.5
    no_y_V = c(solve(diag(c(solve(p_hat_dd_V) %*% n_jd_P))) %*%
            solve(p_hat_dd_V) %*% diag(c(n_jd_P)) %*% y_bar_jd_P)

    if (is.null(y_sum_ji_V)) {
        with_y_V = rep(NULL, length(naive))
        validation = rep(NULL, length(naive))
    } else {
        y_sum_di_V = colSums(y_sum_ji_V)
        y_bar_di_V = y_sum_di_V / n_di_V

        # just validation
        validation = y_bar_di_V

        # estimator assumming unknow p but known y: formula 4.6
        P_share = n_dd_P / (n_dd_P + n_dd_V)
        V_share = n_dd_V / (n_dd_P + n_dd_V)
        with_y_V = c(P_share *
            solve(solve(diag(c(p_hat_dd_V %*% n_di_V))) %*% p_hat_dd_V %*%
            diag(n_di_V)) %*% y_bar_jd_P +
            V_share * y_bar_di_V)
    }

    return (cbind(naive, validation, no_y_V, with_y_V))
}
