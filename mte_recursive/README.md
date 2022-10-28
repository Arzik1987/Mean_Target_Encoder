## Comparing (shallow) DTs with MTE as Preprocessing and Recursive MTE

Here we extend the [example](https://github.com/Arzik1987/Mean_Target_Encoder/tree/main/rpart_demo) to more datasets and calculate quality measures. 
In particular, we experiment with nine datasets used in [CatBoost](https://proceedings.neurips.cc/paper/2018/hash/14491b756b3a51daac41c24863285549-Abstract.html) paper:

- kick
- upselling
- internet
- churn
- appetency
- epsilon
- click
- amazon
- adult

For each dataset we build two decision trees &mdash; one using MTE recursively and another with MTE as a pre-processing step.
We compute accuracy of both trees using 5-fold cross-validation. 
That is, we train five models for each dataset, 45 models in total.
We experiment with different dasaset sizes (by subsampling original datasets) and with different tree depths.
The following tables contain the results: **w**, **d**, and **l** indicate hom many of decision trees learned with 'recursive MTE' achieve better, the same, or lower quality than decision trees learned with MTE as a pre-processing step.

<div align="center">

|          |  w|  d|  l|
|:---------|--:|--:|--:|
|depth = 2 | 13| 16| 16|
|depth = 4 | 16| 11| 18|
|depth = 6 | 16| 12| 17|

N = 1000

|          |  w|  d|  l|
|:---------|--:|--:|--:|
|depth = 2 | 14| 10| 21|
|depth = 4 |  9|  4| 32|
|depth = 6 | 10|  2| 33|

N = 2000

|          |  w|  d|  l|
|:---------|--:|--:|--:|
|depth = 2 | 15|  6| 24|
|depth = 4 | 14|  1| 30|
|depth = 6 | 10|  1| 34|

N = 5000

|          |  w|  d|  l|
|:---------|--:|--:|--:|
|depth = 2 | 24| 11| 10|
|depth = 4 | 17|  2| 26|
|depth = 6 | 14|  0| 31|

Full data

</div>

These experiments do not separate the effects of (1) overfitting caused by high-cardinality categorical features and (2) underfitting caused by using MTE as a pre-processing step. 
Intuitively, the overfitting effect should be more prominent for deeper trees learned with 'recursive MTE' on smaller datasets. 
This is visible to some extent from the columns **l**:
The number of 'recursive MTE' trees that have lower accuracy (column **l**) than the competing models grows with the tree depth.
Also, with the tree depth decreases the number of cases when both decision trees coincide &mdash; see columns **d**.



To reproduce the experiments, clone the whole repository and execute `mte_vs_factor_experiment.R`.