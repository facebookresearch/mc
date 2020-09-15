# LICENSE
Copyright (c) Facebook, Inc. and its affiliates.

# mc

Suppose one studies the proportion of "Game of Thrones" fans among males vs females
but the source of gender is not reliable. Naively ignoring gender misclassification
can give misleading results. We have implemented estimators in both python and R for
misclassification correction (mc), which achieve much smaller bias and MSE than the
naive estimator.
## Installation

The easiest way is propably using pip:

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

Package works for python 3 and R.

## Usage
Package can be imported as

```python
import mc
```

```R
library(devtools)
install_github("facebookresearch/mc")
library(mc)
```

The best way to learn how to use the package is probably by following one of the
notebooks, and the recommended way of opening them is Google Colab.

* [Python](./notebooks/simulations_py.ipynb)
* [R](./notebooks/simulations_R.ipynb)
 
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


## People
Package is created and maintained by Jingang Miao.
