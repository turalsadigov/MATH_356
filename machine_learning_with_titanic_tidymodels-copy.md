Machine Learning with titanic data and tidymodels
================
Tural Sadigov
August 5, 2022

## Libraries and data

``` r
library(tidyverse) # for data manipulation
```

    ## ── Attaching packages ─────────────────────────────────────── tidyverse 1.3.2 ──
    ## ✔ ggplot2 3.3.6     ✔ purrr   0.3.4
    ## ✔ tibble  3.1.8     ✔ dplyr   1.0.9
    ## ✔ tidyr   1.2.0     ✔ stringr 1.4.0
    ## ✔ readr   2.1.2     ✔ forcats 0.5.1
    ## ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
    ## ✖ dplyr::filter() masks stats::filter()
    ## ✖ dplyr::lag()    masks stats::lag()

``` r
library(tidymodels)
```

    ## ── Attaching packages ────────────────────────────────────── tidymodels 1.0.0 ──
    ## ✔ broom        1.0.0     ✔ rsample      1.0.0
    ## ✔ dials        1.0.0     ✔ tune         1.0.0
    ## ✔ infer        1.0.2     ✔ workflows    1.0.0
    ## ✔ modeldata    1.0.0     ✔ workflowsets 1.0.0
    ## ✔ parsnip      1.0.0     ✔ yardstick    1.0.0
    ## ✔ recipes      1.0.1     
    ## ── Conflicts ───────────────────────────────────────── tidymodels_conflicts() ──
    ## ✖ scales::discard() masks purrr::discard()
    ## ✖ dplyr::filter()   masks stats::filter()
    ## ✖ recipes::fixed()  masks stringr::fixed()
    ## ✖ dplyr::lag()      masks stats::lag()
    ## ✖ yardstick::spec() masks readr::spec()
    ## ✖ recipes::step()   masks stats::step()
    ## • Dig deeper into tidy modeling with R at https://www.tmwr.org

``` r
titanic_train <- read_csv('train.csv')
```

    ## Rows: 891 Columns: 12
    ## ── Column specification ────────────────────────────────────────────────────────
    ## Delimiter: ","
    ## chr (5): Name, Sex, Ticket, Cabin, Embarked
    ## dbl (7): PassengerId, Survived, Pclass, Age, SibSp, Parch, Fare
    ## 
    ## ℹ Use `spec()` to retrieve the full column specification for this data.
    ## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

``` r
titanic_test <- read_csv('test.csv')
```

    ## Rows: 418 Columns: 11
    ## ── Column specification ────────────────────────────────────────────────────────
    ## Delimiter: ","
    ## chr (5): Name, Sex, Ticket, Cabin, Embarked
    ## dbl (6): PassengerId, Pclass, Age, SibSp, Parch, Fare
    ## 
    ## ℹ Use `spec()` to retrieve the full column specification for this data.
    ## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

## Machine Learning with tidymodels

**`Goal:`** Using various other traveler characteristics, we would like
to predict if a traveler survived or not. That means that we would like
to create/fit a model that can classify travelers into one of two
groups. This is called classification algorithm. Outcome, survived or
not, is a categorical variable with two levels. Thus, our model will be
a binary classification model. Since we do know if travelers survived or
not already, that means that we will be fitting a supervised algorithm
where data ‘supervises’ the model by telling it what happened with a
particular traveler.

Here are usual steps that we will be conducting from start to end for
every machine learning project.

-   Loading necessary libraries and data. Then, Exploratory Data
    Analysis (EDA) to understand the data at hand.

-   Splitting data into training and testing using stratified sampling.

-   Then further resampling from the training data to choose a model or
    model hyperparameters via either cross validation, bootstrapping or
    just single validation set.

-   Declaring model specifications.

-   Declaring recipes for feature engineering using EDA results.

-   Fitting resamples with various hyperparameters and workflows.

-   Assess the results of these fitting to choose a final model.

-   Fit a final model with the chosen algorithm and hyperparameters to
    the whole training set and make predictions on the testing data to
    report generalization accuracy/error.

Lets start. First, we split the data using stratified sampling. Well,
this step has been already done for us in the data, so we skip. But we
create bootstrap (re)samples for model selection.

``` r
library(tidymodels)
set.seed(2022)
titanic_folds <- bootstraps(data = titanic_train, 
                            times = 25)
titanic_folds
```

    ## # Bootstrap sampling 
    ## # A tibble: 25 × 2
    ##    splits            id         
    ##    <list>            <chr>      
    ##  1 <split [891/328]> Bootstrap01
    ##  2 <split [891/338]> Bootstrap02
    ##  3 <split [891/318]> Bootstrap03
    ##  4 <split [891/316]> Bootstrap04
    ##  5 <split [891/328]> Bootstrap05
    ##  6 <split [891/317]> Bootstrap06
    ##  7 <split [891/330]> Bootstrap07
    ##  8 <split [891/339]> Bootstrap08
    ##  9 <split [891/322]> Bootstrap09
    ## 10 <split [891/317]> Bootstrap10
    ## # … with 15 more rows
    ## # ℹ Use `print(n = ...)` to see more rows

We obtain a new object, a tibble, with list column that has the
bootstrap samples and also out of bag (OOB) samples. When sample size is
large, out of samples approximately consists of
![\frac{1}{e}](https://latex.codecogs.com/png.image?%5Cdpi%7B110%7D&space;%5Cbg_white&space;%5Cfrac%7B1%7D%7Be%7D "\frac{1}{e}")
of the sampled data.

``` r
exp(-1)
```

    ## [1] 0.3678794

For the first bootstrap sample, there are 328 out of bag samples.

``` r
328/891
```

    ## [1] 0.3681257

That is pretty close to the theoretical percentage. Since we have done
EDA in another Quarto, we will use that analysis during feature
engineering. Next step is to define model specifications. We will use
three models: Logistic Regression, Random Forest and Support Vector
Machine with radial kernel.

``` r
# logistic regression
titanic_glm_spec <- 
  logistic_reg() %>% # model
  set_engine('glm') %>%  # package to use
  set_mode('classification') # choose one of two: classification vs regresson

titanic_rf_spec <-  
  rand_forest(trees = 1000) %>% # algorithm speicfic argument:1000 trees
  set_engine('ranger') %>% 
  set_mode('classification')

titanic_svm_spec <-  
  svm_rbf() %>% # rbf - radial based
  set_engine('kernlab') %>% 
  set_mode('classification')
```

One can look into these objects to see model specifications.

``` r
titanic_svm_spec
```

    ## Radial Basis Function Support Vector Machine Model Specification (classification)
    ## 
    ## Computational engine: kernlab

Now we declare recipe which helps us to do feature engineering for
training data, and then will automatically apply the same steps to
testing data.

``` r
# declare recipe
titanic_recipe <- 
  recipe(Survived ~ Pclass + Sex + Age + SibSp + Parch + Fare + Embarked, 
         data = titanic_train) %>% # keep variables we want
  step_impute_median(Age,Fare) %>% # imputation
  step_impute_mode(Embarked) %>% # imputation
  step_mutate_at(Survived, Pclass, Sex, Embarked, fn = factor) %>% # make these factors
  step_mutate(Travelers = SibSp + Parch + 1) %>% # new variable
  step_rm(SibSp, Parch) %>% # remove variables
  step_dummy(all_nominal_predictors()) %>% # create indicator variables
  step_normalize(all_numeric_predictors()) # normalize numerical variables
```

We will define workflows that will combine model with the recipe, and
fit it all together.

``` r
doParallel::registerDoParallel() # resample fitting is embarrasingly parrallel problem
titanic_glm_wf <- 
  workflow() %>% 
  add_recipe(titanic_recipe) %>% 
  add_model(titanic_glm_spec) %>% 
  fit_resamples(titanic_folds)
titanic_glm_wf
```

    ## # Resampling results
    ## # Bootstrap sampling 
    ## # A tibble: 25 × 4
    ##    splits            id          .metrics         .notes          
    ##    <list>            <chr>       <list>           <list>          
    ##  1 <split [891/328]> Bootstrap01 <tibble [2 × 4]> <tibble [0 × 3]>
    ##  2 <split [891/338]> Bootstrap02 <tibble [2 × 4]> <tibble [0 × 3]>
    ##  3 <split [891/318]> Bootstrap03 <tibble [2 × 4]> <tibble [0 × 3]>
    ##  4 <split [891/316]> Bootstrap04 <tibble [2 × 4]> <tibble [0 × 3]>
    ##  5 <split [891/328]> Bootstrap05 <tibble [2 × 4]> <tibble [0 × 3]>
    ##  6 <split [891/317]> Bootstrap06 <tibble [2 × 4]> <tibble [0 × 3]>
    ##  7 <split [891/330]> Bootstrap07 <tibble [2 × 4]> <tibble [0 × 3]>
    ##  8 <split [891/339]> Bootstrap08 <tibble [2 × 4]> <tibble [0 × 3]>
    ##  9 <split [891/322]> Bootstrap09 <tibble [2 × 4]> <tibble [0 × 3]>
    ## 10 <split [891/317]> Bootstrap10 <tibble [2 × 4]> <tibble [0 × 3]>
    ## # … with 15 more rows
    ## # ℹ Use `print(n = ...)` to see more rows

Collect metrics (accuracy and area under the receiver characteristic
curve) for logistic regression.

``` r
collect_metrics(titanic_glm_wf)
```

    ## # A tibble: 2 × 6
    ##   .metric  .estimator  mean     n std_err .config             
    ##   <chr>    <chr>      <dbl> <int>   <dbl> <chr>               
    ## 1 accuracy binary     0.793    25 0.00301 Preprocessor1_Model1
    ## 2 roc_auc  binary     0.843    25 0.00350 Preprocessor1_Model1

We now fit other two models.

``` r
# random forest
doParallel::registerDoParallel()
titanic_rf_wf <- 
  workflow() %>% 
  add_recipe(titanic_recipe) %>% 
  add_model(titanic_rf_spec) %>% 
  fit_resamples(titanic_folds)
# svm
doParallel::registerDoParallel()
titanic_svm_wf <- 
  workflow() %>% 
  add_recipe(titanic_recipe) %>% 
  add_model(titanic_svm_spec) %>% 
  fit_resamples(titanic_folds)
```

Look at performances on OOB samples for all three models.

``` r
collect_metrics(titanic_glm_wf)
```

    ## # A tibble: 2 × 6
    ##   .metric  .estimator  mean     n std_err .config             
    ##   <chr>    <chr>      <dbl> <int>   <dbl> <chr>               
    ## 1 accuracy binary     0.793    25 0.00301 Preprocessor1_Model1
    ## 2 roc_auc  binary     0.843    25 0.00350 Preprocessor1_Model1

``` r
collect_metrics(titanic_rf_wf)
```

    ## # A tibble: 2 × 6
    ##   .metric  .estimator  mean     n std_err .config             
    ##   <chr>    <chr>      <dbl> <int>   <dbl> <chr>               
    ## 1 accuracy binary     0.820    25 0.00325 Preprocessor1_Model1
    ## 2 roc_auc  binary     0.865    25 0.00328 Preprocessor1_Model1

``` r
collect_metrics(titanic_svm_wf)
```

    ## # A tibble: 2 × 6
    ##   .metric  .estimator  mean     n std_err .config             
    ##   <chr>    <chr>      <dbl> <int>   <dbl> <chr>               
    ## 1 accuracy binary     0.813    25 0.00343 Preprocessor1_Model1
    ## 2 roc_auc  binary     0.835    25 0.00336 Preprocessor1_Model1

It seems that Random Forest is the winner with 82% accuracy and ROCAUC
of 86.5. We use it as a final fit to the whole training data.

``` r
titanic_rf_last_wf <- 
  workflow() %>% 
  add_recipe(titanic_recipe) %>% 
  add_model(titanic_rf_spec)
final_fit <- 
  fit(object = titanic_rf_last_wf, 
      data = titanic_train)
final_fit %>% 
  extract_recipe(estimated = T)
```

    ## Recipe
    ## 
    ## Inputs:
    ## 
    ##       role #variables
    ##    outcome          1
    ##  predictor          7
    ## 
    ## Training data contained 891 data points and 179 incomplete rows. 
    ## 
    ## Operations:
    ## 
    ## Median imputation for Age, Fare [trained]
    ## Mode imputation for Embarked [trained]
    ## Variable mutation for Survived, Pclass, Sex, Embarked [trained]
    ## Variable mutation for ~SibSp + Parch + 1 [trained]
    ## Variables removed SibSp, Parch [trained]
    ## Dummy variables from Pclass, Sex, Embarked [trained]
    ## Centering and scaling for Age, Fare, Travelers, Pclass_X2, Pclass_X3, Sex... [trained]

``` r
final_fit %>%
  extract_fit_parsnip()
```

    ## parsnip model object
    ## 
    ## Ranger result
    ## 
    ## Call:
    ##  ranger::ranger(x = maybe_data_frame(x), y = y, num.trees = ~1000,      num.threads = 1, verbose = FALSE, seed = sample.int(10^5,          1), probability = TRUE) 
    ## 
    ## Type:                             Probability estimation 
    ## Number of trees:                  1000 
    ## Sample size:                      891 
    ## Number of independent variables:  8 
    ## Mtry:                             2 
    ## Target node size:                 10 
    ## Variable importance mode:         none 
    ## Splitrule:                        gini 
    ## OOB prediction error (Brier s.):  0.1273232

We will make predictions and more in upcoming Quartos.
