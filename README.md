## Mean Target Encoder for Binary Tree-based Models

### Encoding

Some machine learning models, such as logistic regression, can only work with numeric data. 
When dealing with non-numerical features, a user of such models has two options &mdash; either drop these features, potentially losing important information they may contain, or map (*encode*) them into numerical space.
Over the years, several encoding algorithms have been proposed; see, for example, [this blog post](https://towardsdatascience.com/benchmarking-categorical-encoders-9c322bd77ee8) or [another blog post](https://medium.com/@darnelbolaos/target-encoding-function-with-r-8a037b219fb7).
Among them, **M**ean **T**arget **E**ncoding (MTE) has received much attention in conjunction with ML models based on decision trees&nbsp;[[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf).

### MTE
As the name implies, the MTE encoder replaces each category value with the average target value among all examples of that category.
[Both](https://towardsdatascience.com/benchmarking-categorical-encoders-9c322bd77ee8) [blogposts](https://medium.com/@darnelbolaos/target-encoding-function-with-r-8a037b219fb7) and [[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf) argue that MTE in its pure form causes overfitting. 
They explain this by "leakage" of information about the target variable during encoding, and propose several solutions to mitigate this effect. 
Although this argument and the examples they provide seem convincing and intuitive, the following questions remain:

1. How exactly does MTE cause overfitting; does it affect all categorical features equally, or are some more prone to overfitting than others?
2. How exactly do the proposed changes to MTE reduce/prevent overfitting?

We address these questions below.

### Binary Classification Tree Learning

The recent paper [[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf) states that categorical features "cannot be used in binary decision trees directly" because they "are not necessarily comparable with each other". 
This statement requires a specification of the term 'comparable'.
For example, [one can distinguish](https://en.wikipedia.org/wiki/Level_of_measurement) different levels of measurement in terms of possible operations on the respective data. 
Note that [ordinal variables](https://en.wikipedia.org/wiki/Ordinal_data), although associated with categorical data, make it possible to say whether a given value is less than or greater than another. 
At the same time, [at the nominal level](https://en.wikipedia.org/wiki/Level_of_measurement#Nominal_level), one can only say whether two examples have equal values of a given nominal feature. 
However, even this information is sufficient for the classical decision tree learning algorithm, as we now explain.

We refer to a clear and concise description of decision trees in&nbsp;[[2]](https://hastie.su.domains/Papers/ESLII.pdf) (section&nbsp;9.2). 
For the following, it is important to note that a conventional binary decision tree performs a *recursive binary splitting* of the feature space. 
To find a split, a decision tree learning algorithm tries different splits of the examples into two groups based on the feature values, considering one feature at a time. 
It then chooses the split that optimizes some heuristic criterion calculated on the statistics of the target variable, such as the Gini index or the cross entropy. 
Only the examples that reach the splitting node in question take part in the statistics calculation, hence the term *recursive*. 

How does one determine which splits to consider? For all feature types that can be ordered, the *order* constrains a variety of possible splits. 
In particular, for any such feature *X*, one looks for a partition of the form *X<a*, where *a* is any observed value of that feature in the set of examples *reaching the considered node* of a classification tree. 

For nominal features, the order is not defined. 
In this case, all possible partitions of the observed feature values into two non-empty sets are tried. 
The number of possible partitions to consider scales exponentially with the number of distinct feature values, and the computation becomes prohibitive for features of high cardinality. 
However, it has been shown [[2]](https://hastie.su.domains/Papers/ESLII.pdf) (Section&nbsp;9.2.4) that encoding and ordering the values of a nominal feature with MTE allows finding *the same* optimal partition efficiently. 
In this case, MTE is a trick to speed up the decision tree learning algorithm that *doesn't* affect the result by itself.

#### Hypothesis 0

> Perhaps considering richer typologies like [Chrisman's](https://en.wikipedia.org/wiki/Level_of_measurement#Debate_on_Stevens's_typology) can improve tree-based models. 
> For example, 'cyclic' features like 'month' may deserve [special consideration](https://ianlondon.github.io/blog/encoding-cyclical-features-24hour-time/).

### 'Feature Equality'

Before describing overfitting and underfitting problems with decision trees, let us demonstrate how a learning algorithm treats numeric, ordinal, and nominal features differently and what effect it has on the result. 
Observe that for each split, a decision tree learning algorithm selects the feature with the highest 'score' (Gini index or cross-entropy). 
This score reflects the feature's ability to separate examples with different target values with a *single* split. 

<div align="center">
<a name="table0"></a> 

| num  | ord | nom | target  |
|:-:|:-:|:-:|:-:|
| 1  | low | A | 1 |
| 2  | low | A | 1 |
| 3  | low | A | 1 |
| 4  | medium | B | 1 |
| 5  | medium | B | 0 |
| 6  | medium | B | 0 |
| 7  | medium | B | 1 |
| 8  | high | C | 1 |
| 9  | high | C | 1 |
| 10  | high | C | 1 |

Table 0: Exemplary dataset 0
</div>

#### Example 0
>Table [0](#table0) represents a data set containing numeric, ordinal, and nominal features. 
>Ordinal and nominal features have the same cardinality and match perfectly.
>However, according to their values, *nom>num>ord*. 
>That is, the learning algorithm chooses the feature 'nom' for the first split. 
>If we limit the size of the decision tree to a single split (a decision stump), this feature leads to the best model.
>However, with a tree depth of two, on training data,
>- The accuracy of the tree obtained using only the nominal feature is 0.8.
>- The accuracy of the tree obtained using only the ordinal feature is 0.8.
>- The accuracy of the tree obtained with all features is 0.9.
>- The accuracy of the tree obtained using only the numeric feature is 1.
>- The accuracy of the tree obtained with both numeric and ordinal features is 1.
>
> I.e. the nominal feature prevents learning the best (on the training data) tree of depth 2.


### Overfitting? Nominal features.

As we have explained, MTE does not change the decision tree that would have been obtained by considering all possible partitions of nominal features. 
If overfitting exists, MTE applied to nominal features is not its reason. Instead, the reason is in nominal features themselves. 
In particular, for a feature with *q* distinct values, the search space consists of *q&minus;1* partitions if it can be ordered and *2<sup>q&minus;1</sup>&minus;1* when it is nominal. 
Richer search spaces result in higher VC-dimension&nbsp;[[2]](https://hastie.su.domains/Papers/ESLII.pdf) (Section&nbsp;7.9) and require larger samples to prevent overfitting.

To get a handle on the problem, imagine treating a numerical variable that is measured with high precision as nominal. In this case, the occurrence of repeated values is unlikely. 
With MTE, such a variable will be strongly correlated with the target, regardless of whether there is any dependency between them &mdash; overfitting is obvious. 
Similarly, MTE itself is only a source of overfitting problems when used for splitting, not for nominal features that can be ordered without MTE, i.e., categorical ordinal, numeric, or [discretized](https://towardsdatascience.com/feature-engineering-deep-dive-into-encoding-and-binning-techniques-5618d55a6b38) [numeric](https://machinelearningmastery.com/discretization-transforms-for-machine-learning/) with a large number of bins.

#### Hypothesis 1
> Label encoding that preserves the natural order of categories should be used for ordinal features.

The 'out-of-sample encoding' proposed in [this blogpost](https://towardsdatascience.com/benchmarking-categorical-encoders-9c322bd77ee8) or in&nbsp;[[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf) helps to reduce this overfitting by reducing the correlation between the encoded and target features. 
As a result, it reduces the 'observed' predictive power of nominal features with a significant proportion of poorly represented categories, and tends to use (more) other features in the tree construction.

<div align="center">
<a name="table1"></a> 

| cat  | target   |
|:-:|:-:|
| A  | 1  |
| B  | 1  |
| C  | 0  |
| D  | 0  |

Table 1: Exemplary dataset 1
</div>

#### Example 1

> Out-of-sample encoding the data set from Table&nbsp;[1](#table1) would replace all categories with the previous target value of 0.5 (check if this is the default behavior!), making the feature irrelevant for tree construction. 

Another trick discussed in&nbsp;[[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf) is smoothing. Smoothing also changes the correlation between the encoded feature and the target. 
It does this by reordering the encoded values so that poorly represented classes are "closer" together. 

<div align="center">
<a name="table2"></a> 

| cat  | target   |
|:-:|:-:|
| A  | 1  |
| B  | 1  |
| B  | 1  |
| B  | 1  |
| B  | 1  |
| B  | 0  |
| C  | 1  |
| C  | 1  |
| C  | 1  |
| C  | 1  |
| C  | 1  |
| C  | 1  |
| C  | 0  |
| C  | 0  |
| ...| ...|

Table 2: Exemplary dataset 2. The excerpt containing all examples with values of category in {A,B,C}.
</div>

#### Example 2

>Table&nbsp;[2](#table2) contains the excerpt from some perfectly balanced (i.e., containing equal number of 0 and 1 in the column 'target') dataset. 
>Assume that this excerpt contains all examples with category values in {A,B,C}. 
>The corresponding MTE values are {1,0.8,0.75} that orders these values as {A,B,C} (hereafter &mdash; descending). 
>Let us now apply MTE with smoothing controlled by parameter *a* as in Equation (1) in&nbsp;[[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf). 
>Prior *P=0.5* for balanced data. In what follows, we describe how the smoothing parameter *a* affects the ordering of categories.
>- *a < 1* {A,B,C}
>- *1 < a < 4/3* {B,A,C}
>- *4/3 < a < 4* {B,C,A}
>- *4 < a* {C,B,A}
>
>One would select the values of the smoothing parameter *a* via hyperparameter optimization (HPO) procedure with cross-validation (CV). 
>Observe the following.
>- Many standard HPO procedures will waste time considering *a* values that do not change the ordering. For instance, for a DT algorithm learning from Table&nbsp;[2](#table2), *a=2* and *a=3* are equivalent.
>- As we have described, for a feature with cardinality *q*, the number of possible partitions is *2<sup>q&minus;1</sup>&minus;1*. The number of possible orders of its values is *q!*, i.e. greater. This means that some orderings, e.g. any order and its inverse, are equivalent, since they induce the same sets of possible partitions. For example, both {A,B,C} and {C,B,A} induce two possible partitions ({A}, {B,C}) and ({A,B}, {C}). For a DT algorithm learning from table&nbsp;[2](#table2), *a=0* and *a=5* are equivalent. (Well, this is a silly example, because the table is an excerpt. For the whole data set, smoothing cannot invert the order. TODO: come up with a valid example).
>- Some orders are not possible with smoothing. For example, in the table above, there is no *a* value that would result in orders {C,A,B} or {A,C,B}. 
>- With CV, the order of categories appearing in some folds for some *a* values may not be achievable in others.

#### Hypothesis 2
> (A) Designing an intelligent method to optimize the smoothing parameter *a* can save time.
> 
> (B) Perhaps an even simpler, faster, and perhaps better way to deal with high cardinality nominal features is to replace all poorly represented values with a single "pseudo-category" before applying MTE. See for example [[3]](https://link.springer.com/article/10.1007/s10994-018-5724-2) (section&nbsp;4.2) or [this blogpost](https://towardsdatascience.com/dealing-with-features-that-have-high-cardinality-1c9212d7ff1b).

### Underfitting? MTE as preprocessing.

Can MTE cause underfitting? Yes, it can! The authors of [both](https://towardsdatascience.com/benchmarking-categorical-encoders-9c322bd77ee8) [blogposts](https://medium.com/@darnelbolaos/target-encoding-function-with-r-8a037b219fb7), and of&nbsp;[[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf) report that one often uses MTE as a *preprocessing* step, whereas building a decision tree is a *recursive* process, as we have described. 
That is, one often sticks to *the same* encoding for splitting in each node of a tree instead of computing it based on a subset of the training data reaching that node (see also [this blogpost](https://medium.com/data-design/visiting-categorical-features-and-encoding-in-decision-trees-53400fa65931)). 
As a result, nominal features with high predictive power in subtrees may not be detected. 
In other words, MTE as a preprocessing step may result in losing important information about *feature interaction*. Note that some implementations of ML algorithms have native support for categorical features; [Python example](https://scikit-learn.org/stable/modules/ensemble.html#categorical-support-gbdt), [R example](https://www.gormanalysis.com/blog/decision-trees-in-r-using-rpart/). 

<div align="center">
<a name="table3"></a> 

| cat1  | cat2 | target   | 
|:-:|:-:|:-:|
| A  |C| 1  |
| A  |C| 1  |
| A  |D| 0  |
| B  |C| 0  |
| B  |C| 0  |
| B  |D| 1  |

Table 3: Exemplary dataset 3.
</div>

#### Example 3

>Consider data from Table&nbsp;[3](#table3), which illustrates a particular case of the phenomenon just described when encoding reduces feature cardinality.
>- If one applies MTE recursively (node-wise) as in conventional decision tree, they will learn the structure p(1|AC) = 1, p(1|AD) = 0, p(1|BC) = 0, p(1|BD) = 1 
>- If MTE is used as a preprocessing step, both values C and D of cat2 are replaced by 0.5, and cat2 is not used for tree construction. The resulting tree is then p(1|A) = 2/3, p(1|B) =1/3. 

Feature cardinality reduction is not an indicator of underfitting or, in general, any problem with the encoding. To see this, observe that MTE applied to the data from table&nbsp;[1](#table1) reduces the cardinality and leads to overfitting. 


#### Hypothesis 3
> Perhaps the success of CatBoost can be partially explained by the fact that it does not use encoding as a preprocessing step, but does it recursively (see section 'Feature Combinations' in&nbsp;[[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf)) in a way that a conventional decision tree learning algorithm would suggest.

### R examples

<div align="center">
<a name="figure1"></a> 

![DT obtained with MTE recursive](/rpart_demo/dt_f_edited.jpg)
![DT obtained with MTE as preprocessing](/rpart_demo/dt_te_edited.jpg)

Figure 1: Different ways to use MTE with "rpart" R package.

</div>

The R package "rpart" provides a decision tree learner and can handle categorical data if you specify it as a "factor" data type. 
So we used this package to demonstrate the effect of different ways of using MTE. Figure [1](#figure1) shows the decision trees [learned](https://github.com/Arzik1987/Mean_Target_Encoder/tree/main/rpart_demo) from the kick dataset:
- Plot (A) is the decision tree learned with 'rpart' when categorical features have a 'factor' data type.
- In plot (B), MTE is a preprocessing step.

(B) differs from (A) because of the effect we described in Example 3 &mdash; some information about feature interactions is lost when MTE is a *preprocessing* step. 

### Conclusion

A combination of hypotheses 0&ndash;3, if not yet tried, could lead to a state-of-the-art algorithm for learning boosted trees.

