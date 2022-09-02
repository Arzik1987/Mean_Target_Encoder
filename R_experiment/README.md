## Instructions to Reproduce the Experiment with 'rpart'

NOTE: the data preprocessing procedure (the first three items below) is still pending. The script `R_experiment_TE.R` is working. You may run it on a custom dataset by changing 'kick.csv' in the code to the path to your file with data. Make sure the names of categorical columns follow the template 'cat_X' where 'X' is any text/number.

- Download the [kick](https://www.kaggle.com/c/DontGetKicked/data) dataset; both training and test files.
- This step is to be clarified. Need to remember where did we get the target for test data from.
- Execute `data_preparation.R` (not yet finished, requires clarification of the previous step).
- Execute `R_experiment_TE.R`.

This sequence of steps outputs tree structures without the names of the features used for each split. We have edited the output manually by typing these names. To check the correctness of our edits, one may uncomment and execute `rpart.plot` functions in `R_experiment_TE.R` and let them output decision tree plots in high resolution.