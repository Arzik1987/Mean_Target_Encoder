## Instructions to Reproduce the Experiment with 'rpart'

R package [`rpart`](https://cran.r-project.org/web/packages/rpart/index.html) [can handle](https://www.gormanalysis.com/blog/decision-trees-in-r-using-rpart/#dataset-1) `factor` data type and treats features of this type as categorical (ordinal or nominal depending on whether the `ordered` flag is TRUE). 
Hence, we use this package to demonstrate how using MTE before learning a decision tree changes the result.
To reproduce our result, you need to install [R](https://www.r-project.org/) and do the following steps.

- Install additional packages `rpart` and `OpenML`.
- Launch R and execute `R_experiment_TE.R`.

This sequence of steps outputs tree structures without the names of the features used for each split. 
The splitting variables are visible from the R console.