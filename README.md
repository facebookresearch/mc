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

# Simulation results
I replicate simulations in the papers and added variations of my own.
See [Python notebook](./notebooks/simulations_py.ipynb) for detail.


## misclassification independent of Y
I first replicate simulation setting a in Mak & Li with 2 groups, where
* probability that true group = 1 is 0.2
* the misclassification matrix has p11=0.9 and p22=0.8
  (same as the example p matrix above).
* Y follows a Bernoulli with true probabilities 
  mu1 = 0.8 (for true group 1) and mu2 = 0.4 (for true group 2) —
  those are the parameters of interest
* the primary and validation data sizes are 400 and 100 respectively.

Here the misclassification matrix does not depend on values of Y.
Based on 1000 replications, the bias (average of estimates - truth)
and MSE (average squared distance between estimates and truth) are calculated.

Bias
```
       naive       validation    no_y_V     with_y_V    mak_li 
mu1    -0.188843    0.001773     -0.022137  0.000729     0.006590 
mu2     0.009426   -0.001499     -0.002380  -0.002108   -0.002691
```

MSE
```
       naive      validation    no_y_V    with_y_V    mak_li 
mu1    0.037526    0.008667     0.010077  0.007131    0.006804 
mu2    0.001027    0.002806     0.001253  0.000829    0.000906
```

REML is slightly better than MOM, and both are much better than the
naive method. In particular for mu1, RMLE/mak_li has a 28X reduction
in bias and a 5X reduction in MSE compared with the naive estimator.

In my own variation below, I increase the primary data's size to
400X of the validation data to mimic a common use case,
where the primary data is huge but the validation, e.g., a survey, is quite small.

Bias
```
       naive      validation    no_y_V    with_y_V    mak_li 
mu1    0.037526    0.008667     0.010077  0.007131    0.006804 
mu2    0.001027    0.002806     0.001253  0.000829    0.000906
```

MSE
```
       naive      validation    no_y_V    with_y_V    mak_li 
mu1    0.035491   0.008539      0.005806  0.004405    0.006371
mu2    0.000158   0.002859      0.000149  0.000106    0.000424
```

In this case, the MOM estimators beat mak_li in terms of MSE.

## misclassification dependent on Y
Here I replicate simulation setting c in Mak & Li, where the difference
is that misclassification depends on value of Y:
* if Y=1: p11=0.93, p22=0.77
* if Y=0: p11=0.87, p22=0.83

Here are the results based on 1000 replications.
Bias
```
       naive       validation    no_y_V     with_y_V    mak_li 
mu1    0.188340    0.001687     -0.008752   0.006375    0.006507
mu2    0.012209    0.000073     -0.001510  -0.000508   -0.000546
```

MSE
```
       naive      validation    no_y_V    with_y_V    mak_li 
mu1    0.056440    0.008667     0.022008  0.013200     0.006683
mu2    0.001984    0.002806     0.001718  0.001154     0.000928
```

RMLE is better than MOM, which is still much better than naive.

# Recommendations on what to use
Based on the simulation results, I recommend the RMLE method in general,
unless you have strong prior knowledge or the method does not work:
* if no validation data: naive is the only option
* if validation data does not have Y: use no_y_V from MOM
* if you believe misclassification is independent of Y and primary data
  is much larger than validation data: use with_y_V from MOM

Intuitively, MOM's weakness is that it relies on independence,
whereas RMLE's weakness is that it does not seem to fully utilize the primary data.
As a result, RMLE should be the default and MOM is preferred only
when independence holds AND primary data is huge.
It’s a good practice to calculate all estimates to compare and contrast,
which fortunately is fairly easy with the implemented functions here.

## People
Package is created and maintained by Jingang Miao.
