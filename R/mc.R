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

#' mc: package for estimating subgroup means under misclassification.
#'
#' This module implements two methods for estimating subgroup means when
#' grouping can be misclassified.
#'
#' @author Jingang Miao \email{jingang@@fb.com}
#'
#' @section Notation:
#' Template: {y_sum, y2_sum, n}_{ji, jd, dj, dd}_{P,V}
#' First component:
#'     y_sum: sum of y
#'     y2_sum: sum of y ** 2
#'     n: count of observations
#' Second component:
#'     ji: j indicates the misclassified  and i incidates the true group info.
#'         the array is 2D.
#'     jd: d for dot, so jd means summing over the i dimension; aka, sum per
#'         misclassified group. Dimension is 1D.
#'     di: d for dot, so di means summing over the j dimension; aka, sum per
#'         true group. Dimension is 1D.
#'     dd: d for dot, so dd means summing over both the j and i dimensions.
#'         Quantity is scalar.
#' Third coponent:
#'     P: primary data with the misclassified but without the true group info.
#'     V: Validation data where both the misclassified and the true group info
#'         is available.
#'
#' @section Functions:
#' \code{mc_mom()}
#' \code{mc_rmle()}
#'
#' @docType package
#' @name mc
NULL
