## Mean Target Encoder for Binary Tree-based Models

### Encoding

Some machine learning models, e.g., logistic regression, can only work with numeric data. 
When dealing with non-numeric features, a user of such models has two options &mdash; either drop these features, potentially losing important information they may contain or map (*encode*) them into numeric space.
Over years various encoding algorithms were proposed; see, for instance, [this blogpost](https://towardsdatascience.com/benchmarking-categorical-encoders-9c322bd77ee8) or [another blogpost](https://medium.com/@darnelbolaos/target-encoding-function-with-r-8a037b219fb7).
Among them, **M**ean **T**arget **E**ncoding (MTE) attained much attention in conjunction with ML models based on decision trees&nbsp;[[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf).

### MTE
As the name suggests, the MTE encoder replaces each categorical value with the average target value among all examples of this category.
[Both](https://towardsdatascience.com/benchmarking-categorical-encoders-9c322bd77ee8) [blogposts](https://medium.com/@darnelbolaos/target-encoding-function-with-r-8a037b219fb7) and [[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf) argue that MTE in its pure form causes overfitting. 
They explain this via 'leakage' of the information about the target variable during the encoding and propose various solutions to alleviate this effect. 
Although this argumentation and the provided examples look convincing and are in line with intuition, the following questions remain:

1. How exactly does MTE cause overfitting &mdash; does it affect all categorical features equally, or some of them are more prone to overfitting than others?
2. How exactly do the proposed modifications of MTE allow to reduce/prevent overfitting?

In what follows, we address these questions.

### Binary Classification Tree Learning

The recent paper [[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf) states that categorical features 'cannot be used in binary decision trees directly' since they 'are not necessarily comparable with each other. 
This statement calls for specifying the term 'comparable'.
For instance, [one can distinguish](https://en.wikipedia.org/wiki/Level_of_measurement) different levels of measurement concerning operations possible on respective data. 
Note that [ordinal variables](https://en.wikipedia.org/wiki/Ordinal_data), while being attributed to categorical data, allow saying whether a given value is less than or greater than another. 
At the same time, [on a nominal level](https://en.wikipedia.org/wiki/Level_of_measurement#Nominal_level), one can only say whether two examples have equal values of a given nominal feature. 
However, even this information is enough for the classical decision tree learning algorithm, as we now explain.

We refer to a clear and concise description of decision trees in&nbsp;[[2]](https://hastie.su.domains/Papers/ESLII.pdf) (Section&nbsp;9.2). 
For the following, it is important that a conventional binary decision tree does *recursive binary splitting* of the feature space. 
To find a split, a decision tree learning algorithm tries different partitioning of examples into two groups based on the feature values and considers one feature at a time. 
Then, it chooses the split optimizing some heuristic criterion calculated on the target variable's statistics like Gini index or cross-entropy. 
Only the examples reaching the considered splitting node take part in the statistics calculation, hence the term *recursive*. 

How to define which splits to consider? For all feature types that can be ordered, the *order* restricts a variety of possible splits. 
In particular, for any such feature *X*, one looks for a split of the form *X<a*, where *a* is some observed value of this feature in the set of examples *reaching the considered node* of a classification tree. 

Order is not defined for nominal features. 
In this case, one tries all possible splits of the observed feature values into two non-empty sets. 
The number of possible partitions to consider scales exponentially with the number of distinct feature values, and computations become prohibitive for features of high cardinality. 
However, it was shown [[2]](https://hastie.su.domains/Papers/ESLII.pdf) (Section&nbsp;9.2.4) that encoding and ordering the values of a nominal feature with MTE does allow to find *the same* optimal split efficiently. 
In this case, MTE is a trick to speed up the decision tree learning algorithm that *does not affect the result* on its own.

#### Hypothsis 0

> Maybe considering richer typologies like the [Chrisman's](https://en.wikipedia.org/wiki/Level_of_measurement#Debate_on_Stevens's_typology) one may improve tree-based models. 
> For instance, 'cyclic' features like 'month' may deserve [special consideration](https://ianlondon.github.io/blog/encoding-cyclical-features-24hour-time/).

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
>Table [0](#table0) presents a dataset containing numeric, ordinal, and nominal features. 
>Ordinal and nominal features have the same cardinality and perfectly match each other
>However, according to their scores, *nom>num>ord*. 
>That is, the learning algorithm chooses the feature 'nom' for the first split. 
>If we limit the size of the decision tree to a single split (a decision stump), this feature leads to the best model.
>However, with the tree depth of two, on train data,
>- The accuracy of the tree obtained exclusively with the nominal feature is 0.8.
>- The accuracy of the tree obtained exclusively with the ordinal feature is 0.8.
>- The accuracy of the tree obtained with all features is 0.9.
>- The accuracy of the tree obtained exclusively with the numeric feature is 1.
>- The accuracy of the tree obtained with the numeric and ordinal features is 1.
>
> I.e., nominal feature hinders learning the best (on train data) tree of depth 2.


### Overfitting? Nominal features.

As we have explained, MTE does not change the decision tree that would have been obtained by considering all possible partitions of nominal features. 
If overfitting exists, MTE applied to nominal features is not its reason. Instead, the reason is in nominal features themselves. 
In particular, for a feature with *q* distinct values, the search space consists of *q&minus;1* partitions if it can be ordered and *2<sup>q&minus;1</sup>&minus;1* when it is nominal. 
Richer search spaces result in higher VC-dimension&nbsp;[[2]](https://hastie.su.domains/Papers/ESLII.pdf) (Section&nbsp;7.9) and require larger samples to prevent overfitting.

To get a grip on the problem, imagine one treats a numeric variable measured with high precision as nominal. In this case, encountering repeated values is unlikely. 
With MTE, such a variable will strongly correlate with the target regardless of whether there is any dependence between them &mdash; overfitting is apparent. 
Similarly, MTE itself is a cause of overfitting problem only when one uses it for splitting, not nominal features that can be ordered without MTE, i.e., categorical ordinal, numeric, or [discretized](https://towardsdatascience.com/feature-engineering-deep-dive-into-encoding-and-binning-techniques-5618d55a6b38) [numeric](https://machinelearningmastery.com/discretization-transforms-for-machine-learning/) with a large number of bins.

#### Hypothesis 1
> For ordinal features, one should use label encoding that preserves the natural order of categories.

The 'out-of-sample encoding' suggested in [this blogpost](https://towardsdatascience.com/benchmarking-categorical-encoders-9c322bd77ee8) or in&nbsp;[[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf) helps to reduce this overfitting by decreasing the correlation between the encoded and the target features. 
As a result, it lowers the 'observed' predictive power of nominal features with a significant share of poorly represented categories and tends to use (more) other features in tree construction.

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

> Out-of-sample encoding for the dataset from Table&nbsp;[1](#table1) would replace all categories with the prior target value of 0.5 (check if this is default behavior!), making the feature irrelevant for tree construction. 
> 

Another trick discussed in&nbsp;[[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf) is smoothing. Smoothing also changes the correlation between the encoded feature and the target. 
It does so by reordering encoded values so that poorly represented classes become closer to each other when ordered by encoded values. 

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
>- *a < 1*        {A,B,C}
>- *1 < a < 4/3*  {B,A,C}
>- *4/3 < a < 4*  {B,C,A}
>- *4 < a*        {C,B,A}
>
>One would select the values of the smoothing parameter *a* via hyperparameter optimization (HPO) procedure with cross-validation (CV). 
>Observe the following.
>- Many standard HPO procedures will waste time considering *a* values that do not change the ordering. For instance, for a DT algorithm learning from Table&nbsp;[2](#table2), *a=2* and *a=3* are equivalent.
>- As we have described, for a feature with cardinality *q*, the number of possible partitions is *2<sup>q&minus;1</sup>&minus;1*. The number of possible orderings of its values is *q!*, i.e., greater. This means that some orderings, e.g., any ordering with its inverse, are equivalent since they induce the same sets of possible partitions. For instance, both {A,B,C} and {C,B,A} induce two possible partitions ({A}, {B,C}) and ({A,B}, {C}). For a DT algorithm learning from Table&nbsp;[2](#table2), *a=0* and *a=5* are equivalent. (Well, this is stupid example, because the table is an excerpt. For the complete dataset smoothing can not invert order. TODO: come up with a valid example.)
>- Some orderings are not achievable with smoothing. For instance, there is no *a* value for the above table, that would result in orderings {C,A,B} or {A,C,B}. 
>- With CV, orderings of categories appearing in some folds for some *a* values might not be achievable in others.

#### Hypothesis 2
> (A) Designing an intelligent procedure for optimization of the smoothing parameter *a* may save time.
> 
> (B) Perhaps, even more straightforward, faster, and maybe a better way to deal with nominal features of high cardinality is to replace all poorly represented values with a single 'pseudo-category' before applying MTE. See, e.g., [[3]](https://link.springer.com/article/10.1007/s10994-018-5724-2) (Section&nbsp;4.2) or [this blogpost](https://towardsdatascience.com/dealing-with-features-that-have-high-cardinality-1c9212d7ff1b).

### Underfitting? MTE as preprocessing.

Can MTE be a reason for underfitting? Yes! The authors of [both](https://towardsdatascience.com/benchmarking-categorical-encoders-9c322bd77ee8) [blogposts](https://medium.com/@darnelbolaos/target-encoding-function-with-r-8a037b219fb7), and of&nbsp;[[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf) report that one often uses MTE as a *preprocessing* step, whereas building a decision tree is a *recursive* process, as we described. 
That is, one often sticks to *the same* encoding for splitting in each node of a tree instead of computing it based on a subset of training data reaching that node (see also [this blogpost](https://medium.com/data-design/visiting-categorical-features-and-encoding-in-decision-trees-53400fa65931)). 
Consequently, nominal features with high predictive power in subtrees may not be recognized. 
In other words, MTE as a preprocessing step may result in losing important information about *feature interaction*. Note that some implementations of ML algorithms have native support for categorical features &mdash; [python example](https://scikit-learn.org/stable/modules/ensemble.html#categorical-support-gbdt), [R example](https://www.gormanalysis.com/blog/decision-trees-in-r-using-rpart/). 

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

>Consider data from Table&nbsp;[3](#table3) that illustrates a particular case of the phenomenon just described when encoding reduces the feature cardinality.
>- If one applies MTE recursively (node-wise) as in conventional decision tree, they will learn the structure p(1|AC) = 1, p(1|AD) = 0, p(1|BC) = 0, p(1|BD) = 1 
>- If one uses MTE as a pre-processing step, both values C and D of cat2 are replaced with 0.5, and cat2 is not used for tree construction. The resulting tree is then p(1|A) = 2/3, p(1|B) =1/3 

Feature cardinality reduction is not an indicator of underfitting or, in general, any problem with the encoding. To see this, observe that MTE applied to the data from Table&nbsp;[1](#table1) reduces cardinality and leads to overfitting. 


#### Hypothesis 3
> Perhaps, the success of CatBoost can be partially explained by the fact that it does not use encoding as a preprocessing step but does it recursively (see section 'Feature combinations' in&nbsp;[[1]](http://learningsys.org/nips17/assets/papers/paper_11.pdf)) in a way a conventional decision tree learning algorithm suggests.

### R examples

<div align="center">
<a name="figure1"></a> 

![DT obtained with MTE recursive](/rpart_demo/dt_f_edited.jpg)
![DT obtained with MTE as preprocessing](/rpart_demo/dt_te_edited.jpg)

Figure 1: Different ways to use MTE with 'rpart' R package.

</div>

R package 'rpart' provides a decision tree learner and can handle categorical data if one specifies them as a 'factor' data type. 
So we used this package to demonstrate the effect of different ways to use MTE. Figure [1](#figure1) presents the decision trees [learned](https://github.com/Arzik1987/Mean_Target_Encoder/tree/main/rpart_demo) from kick dataset:
- Plot (A) is the decision tree learned with 'rpart' when categorical features have a 'factor' data type.
- In plot (B), MTE is a preprocessing step.

(B) differs from (A) because of the effect we described in Example 3 &mdash; some information about feature interactions is lost when MTE is a *preprocessing* step. 

### Conclusion

A combination of hypotheses 0&ndash;3, if not yet tried out, might result in a state-of-the-art algorithm for learning boosted trees.

