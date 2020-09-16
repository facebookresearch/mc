# LICENSE
Copyright (c) Facebook, Inc. and its affiliates.

# mc

`mc` is for misclassification correction.

Suppose one studies the proportion of "Game of Thrones" fans among males vs females
but the source of gender is not reliable. Naively ignoring gender misclassification
can give misleading results. We have implemented estimators in both python and R for
misclassification correction (mc), which achieve much smaller bias and MSE than the
naive estimator.
## Installation

### Python
For python, the easiest way is propably using pip:

```
pip install -q git+https://github.com/facebookresearch/mc
```

If you are using a machine without admin rights, you can do:

```
pip install -q git+https://github.com/facebookresearch/mc --user
```

If you are using [Google Colab](https://colab.research.google.com/), just add
"!" to the beginning:

```
!pip install -q git+https://github.com/facebookresearch/mc
```

Package can be imported as

```python
import mc
```

Package works for python 3.6 and above.

### R
For R, you can do

```R
library(devtools)
install_github("facebookresearch/mc")
library(mc)
```
## Usage

The best way to learn how to use the package is probably by following one of the
notebooks, and the recommended way of opening them is Google Colab.

* [Python notebook](./notebooks/simulations_py.ipynb)
* [R notebook](./notebooks/simulations_R.ipynb)

## Double sampling

The implemented methods depends on double sampling, where
in addition to a primary data with misclassified group information plus some metric
Y whose per group mean is of interest, a validation sample is also collected from
the same population with true as well as misclassified group information.
The validation sample may or may not have Y values. Then correction can be done
by leveraging the misclassification matrix (p) based on the validation sample, where
* each row is a misclassified group
* each column is a true group, and
* and each column sums to 1.

An example is shown below, where when true group is 1, the misclassified group is
also 1 with a probability of 90% and is 2 with a probability of 10%.

```
                         true group
                         1         2
 misclassified group 1   90%      20%
                     2   10%      80%
```

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


Here are the methods:
* naive: just the primary sample; using the misclassified groups
* validation: just the validation sample (Y variable must be available);
  using the true groups  — I added this one, which was not in the papers
* MOM (method of moments)
    - no_y_V: both samples; not using Y of the validation set
    - with_y_V: both samples;  using Y of the validation set
* RMLE (restricted maximum likelihood estimator)
    - mak_li: both samples;  using Y of the validation set

## People
Package is created and maintained by Jingang Miao.
