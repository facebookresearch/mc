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

"""Estimate subgroup means under misclassification.

This module implements two methods for estimating subgroup means when
grouping can be misclassified.

Notation: {y_sum, y2_sum, n}_{ji, jd, dj, dd}_{P,V}
First component:
    y_sum: sum of y
    y2_sum: sum of y ** 2
    n: count of observations
Second component:
    ji: j indicates the misclassified  and i incidates the true group info.
        the array is 2D.
    jd: d for dot, so jd means summing over the i dimension; aka, sum per
        misclassified group. Dimension is 1D.
    di: d for dot, so di means summing over the j dimension; aka, sum per
        true group. Dimension is 1D.
    dd: d for dot, so dd means summing over both the j and i dimensions.
        Quantity is scalar.
Third coponent:
    P: primary data with the misclassified but without the true group info.
    V: Validation data where both the misclassified and the true group info
        is available.

"""

import numpy as np
import pandas as pd
from scipy.linalg import inv


def mc_mom(n_jd_P, y_sum_jd_P, n_ji_V, y_sum_ji_V=None):
    """"Misclassification correction via mothod of moments.

    See paper:
       Selén, Jan. “Adjusting for Errors in Classification and Measurement in
       the Analysis of Partly and Purely Categorical Data.” Journal of the
       American Statistical Association, vol. 81, no. 393, 1986, pp. 75–81.
       JSTOR, www.jstor.org/stable/2287969. Accessed 10 Aug. 2020.

    We use m for the number of subgroups.

    Args:
        n_jd_P: a (m,) array of counts in the primary by misclassified groups.
        y_sum_jd_P: a (m,) array of sum(y) in the primary dataset by
            misclassified groups.
        n_ji_V: a (m, m) array of counts in the validation data with rows
            for for misclassified and columns for true groups.
        y_sum_ji_V: a (m, m)array of sum(y) in the validation data with rows
            for for misclassified and columns for true groups. If None, the
            `validation` and `with_y_V` estimates will be NaN.
    Returns:
        pd.DataFrame with the following estimates of the per group mean:
            naive: the naive estimates using the misclassified groups.
            validation: estimates using just the validation data.
            no_y_V: estiamtes with both datasets but without using the `y` value
                in the validation data.
            with_y_V: estimates using all data, including the y value in the
                validation data.
    """
    m = len(n_jd_P)
    if (n_jd_P.shape != (m, )):
        raise ValueError(
            f"n_jd_P's shape should be ({m},) but got {n_jd_P.shape}."
        )
    if (y_sum_jd_P.shape != (m, )):
        raise ValueError(
            f"y_sum_jd_P's shape should be ({m},) but got {y_sum_jd_P.shape}."
        )
    if (n_ji_V.shape != (m, m)):
        raise ValueError(
            f"n_ji_V's shape should be ({m}, {m})"
            f" but got {n_ji_V.shape}."
        )
    if y_sum_ji_V is not None:
        if (y_sum_ji_V.shape != (m, m)):
            raise ValueError(
                f"y_sum_ji_V's shape should be ({m}, {m})"
                f" but got {y_sum_ji_V.shape}."
            )

    # primary data
    n_dd_P = np.sum(n_jd_P)
    # validation data
    n_jd_V = np.sum(n_ji_V, axis=1)
    n_di_V = np.sum(n_ji_V, axis=0)
    n_dd_V = np.sum(n_di_V)

    # estimate p on validation data
    p_hat_dd_V = n_ji_V @ np.diag(1 / n_di_V)

    # naive estimator
    y_bar_jd_P = y_sum_jd_P / n_jd_P
    naive = y_bar_jd_P

    # estimator assumming know p: formula 4.2
    # known_p = inv(inv(np.diag(p @ pi)) @ p @ np.diag(pi)) @ y_bar_jd_P

    # estimator assumming unknow p: formua 4.5
    no_y_V = (
        inv(np.diag(inv(p_hat_dd_V) @ n_jd_P))
        @ inv(p_hat_dd_V)
        @ np.diag(n_jd_P)
        @ y_bar_jd_P
    )

    if y_sum_ji_V is None:
        with_y_V = np.full(np.nan, naive.shape)
        validation = np.full(np.nan, naive.shape)
    else:
        y_sum_di_V = np.sum(y_sum_ji_V, axis=0)
        y_bar_di_V = y_sum_di_V / n_di_V

        # just validation
        validation = y_bar_di_V

        # estimator assumming unknow p but known y: formula 4.6
        P_share = n_dd_P / (n_dd_P + n_dd_V)
        V_share = n_dd_V / (n_dd_P + n_dd_V)
        with_y_V = (
            P_share
            * inv(inv(np.diag(p_hat_dd_V @ n_di_V)) @ p_hat_dd_V @ np.diag(n_di_V))
            @ y_bar_jd_P
            + V_share * y_bar_di_V
        )

    return pd.DataFrame(
        {
            "naive": naive,
            "validation": validation,
            "no_y_V": no_y_V,
            "with_y_V": with_y_V,
        }
    )


def mc_rmle(n_jd_P, y_sum_jd_P, n_ji_V, y_sum_ji_V, y2_sum_ji_V):
    """"Misclassification correction via rmle.

    See paper:
    T. K. MAK, W. K. LI, A new method for estimating subgroup means under
    misclassification, Biometrika, Volume 75, Issue 1, March 1988,
    Pages 105–111, https://doi.org/10.1093/biomet/75.1.105

    Args:
        n_jd_P: a (m,) array of counts in the primary by misclassified groups.
        y_sum_jd_P: a (m,) array of sum(y) in the primary dataset by
            misclassified groups.
        n_ji_V: a (m, m) array of counts in the validation data with rows
            for for misclassified and columns for true groups.
        y_sum_ji_V: a (m, m)array of sum(y) in the validation data with rows
            for for misclassified and columns for true groups.
        y2_sum_ji_V: a (m, m)array of sum(y ** 2) in the validation data
            with rows for for misclassified and columns for true groups.
    Returns:
        pd.DataFrame with the following columns:
            mak_li: estimates of mu's.
            variance: estiamtes of variances.
    """
    m = len(n_jd_P)
    if (n_jd_P.shape != (m, )):
        raise ValueError(
            f"n_jd_P's shape should be ({m},) but got {n_jd_P.shape}."
        )
    if (y_sum_jd_P.shape != (m, )):
        raise ValueError(
            f"y_sum_jd_P's shape should be ({m},) but got {y_sum_jd_P.shape}."
        )
    if (n_ji_V.shape != (m, m)):
        raise ValueError(
            f"n_ji_V's shape should be ({m}, {m})"
            f" but got {n_ji_V.shape}."
        )
    if (y_sum_ji_V.shape != (m, m)):
        raise ValueError(
            f"y_sum_ji_V's shape should be ({m}, {m})"
            f" but got {y_sum_ji_V.shape}."
        )
    if (y2_sum_ji_V.shape != (m, m)):
        raise ValueError(
            f"y2_sum_ji_V's shape should be ({m}, {m})"
            f" but got {y2_sum_ji_V.shape}."
        )

    # primary data
    n_dd_P = np.sum(n_jd_P)
    # validation data
    n_jd_V = np.sum(n_ji_V, axis=1)
    n_di_V = np.sum(n_ji_V, axis=0)
    n_dd_V = np.sum(n_di_V)
    y_sum_di_V = np.sum(y_sum_ji_V, axis=0)
    y_sum_jd_V = np.sum(y_sum_ji_V, axis=1)
    y_bar_di_V = y_sum_di_V / n_di_V
    y_bar_jd_V = y_sum_jd_V / n_jd_V
    y2_sum_jd_V = np.sum(y2_sum_ji_V, axis=1)

    v_hat_jd = (y_sum_jd_V + y_sum_jd_P) / (n_jd_V + n_jd_P)
    V = np.diag(
        (y2_sum_jd_V / n_dd_V - y_sum_jd_V ** 2 / n_jd_V / n_dd_V)
        / (n_jd_V ** 2)
        * n_dd_V ** 2
    )

    m_ji = n_jd_V[:, np.newaxis] @ n_di_V[np.newaxis, :]

    U = (
        y2_sum_ji_V / m_ji * n_dd_V
        + y_sum_jd_V[:, np.newaxis]
        @ y_sum_di_V[np.newaxis, :]
        * n_ji_V
        / m_ji ** 2
        * n_dd_V
        - y_sum_ji_V @ np.diag(y_sum_di_V / n_di_V) / m_ji * n_dd_V
        - np.diag(y_sum_jd_V / n_jd_V) @ y_sum_ji_V / m_ji * n_dd_V
    )
    B = inv(V) @ U
    mak_li = y_bar_di_V - B.T @ (y_bar_jd_V - v_hat_jd)
    variance = (
        # error in formula for w: \sum Y^2_{jik} should be over j, k.
        n_dd_V * (np.sum(y2_sum_ji_V, axis=0) / n_di_V - y_bar_di_V ** 2) / n_di_V
        - U.T @ inv(V) @ U * n_dd_P / (n_dd_P + n_dd_V)
    ) / n_dd_V

    return pd.DataFrame({"mak_li": mak_li, "mak_li_var": np.diag(variance)})
