# LICENSE
Copyright (c) Facebook, Inc. and its affiliates.

# mc

Suppose one studies the proportion of "Game of Thrones" fans among males vs females
but the source of gender is not reliable. Naively ignoring gender misclassification
can give misleading results. We have implemented estimators in both python and R for
misclassification correction (mc), which achieve much smaller bias and MSE than the
naive estimator.

# Methods

A method of moments (MOM) based method was proposed by Selén (1986):
> Selén, Jan. “Adjusting for Errors in Classification and Measurement in the
Analysis of Partly and Purely Categorical Data.” Journal of the American
Statistical Association, vol. 81, no. 393, 1986, pp. 75–81.
JSTOR, www.jstor.org/stable/2287969.

The high-level idea is to first write the expected value of the misclassified group
means as a function of the true group means and then solve for the true group means.
MOM assumes that misclassification is independent of Y and thus can perform poorly
if this assumption is violated.

A restricted maximum likelihood (RMLE) approach was developed by Mak & Li (1988).
>T. K. MAK, W. K. LI, A new method for estimating subgroup means under
misclassification, Biometrika, Volume 75, Issue 1, March 1988, Pages 105–111.
https://doi.org/10.1093/biomet/75.1.105
