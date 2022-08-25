## Mean Target Encoder for Binary Tree-based Models

The authors of [this blogpost](https://towardsdatascience.com/benchmarking-categorical-encoders-9c322bd77ee8), [another blogpost](https://medium.com/@darnelbolaos/target-encoding-function-with-r-8a037b219fb7), and of this [NeurIPS paper](http://learningsys.org/nips17/assets/papers/paper_11.pdf) argue that there is an overfitting problem with **M**ean **T**arget **E**ncoding (MTE). They explain this via 'leakage' of the information about the target variable during the encoding and propose various solutions alleviating this effect. Although this argumentation and the provided examples look convincing and in line with intuition, the following questions remain:

1. How exactly does this overfitting reduces the model's performance on test data? This is especially not obvious in general case of medium-sized and big datasets, since the effects of MTE are explained on small toy datasets with few examples having a given categorical value.
2. How exactly do the proposed solutions allow to overcome this overfitting problem?

Below we explain our view on this problem.

The recent [NeurIPS paper](http://learningsys.org/nips17/assets/papers/paper_11.pdf) states that categorical features 'cannot be used in binary decision trees directly' since they 'are not necessary comparable with each other'. This statement calls for specifying the term 'comparable'. For instance, [one can distinguish](https://en.wikipedia.org/wiki/Level_of_measurement) different levels of measurement with respect to operations possible on repective data. Note that [ordinal variables](https://en.wikipedia.org/wiki/Ordinal_data), while being attributed to categorical data, do allow to say whether a given value is less than or greater than another. At the same time, [on a nominal level](https://en.wikipedia.org/wiki/Level_of_measurement#Nominal_level), one can only say whether two examples have equal values of a given nominal feature. However, even this information is enough for classical decision tree learning algorithm, as we now explain.


### Binary Classification Tree Learning

We refer to a very clear and concise description of decision trees in [The Elements of Statistical Learning](https://hastie.su.domains/Papers/ESLII.pdf) (Section 9.2). For the following it is important that a conventional binary decision tree does *recursive binary splitting* of the feature space. To find a split, a decision tree learning algorithm tries different partitioning of examples into two groups based on the feature values and considering one afeature at-a-time. Then, it chooses the split optimizing some heuristic criterion calculated on the target variable's statistics like Gini index or cross-entropy. Only the examples reaching the considered splitting node take part in the statstics calculation, hence the term *recursive*. 

How to define which splits to consider? For all feature types except nominal, the *order* of observed values restricts a variety of possible splits. In particular, for any not nominal feature *X* one looks for a split of the form *X<a*, where *a* is some observed value of this feature in the set of examples *reaching the considered node* of classification tree. 

Order is not defined for nominal features. In this case, one tries all possible splits of the observed feature values into two non-empty sets. The number of possible partitions to consider scales exponentially with the number of distincs feature values and computations become prohibitive for features of high cardinality. However, it [was shown](https://hastie.su.domains/Papers/ESLII.pdf) (Section 9.2.4) that encoding and ordering the values of a nominal feature with MTE does allow to find *the same* optimal split efficiently. In this case, one can see MTE as a trick to speed up the decision tree learning algorithm that *does not affect the result*.

#### Hypothsis 0

*Maybe considering richer topologies like the [Chrisman's](https://en.wikipedia.org/wiki/Level_of_measurement#Debate_on_Stevens's_typology) one, may improve tree based models*


### Overfitting? Nominal and not nominal features.

As we have explained, MTE does not change the decision tree that would have been obtained with considering all possible partitions of nominal features. If overfitting exists, MTE applied to nominal features is not its reason. Rather, the reason is in nominal features themselves. In particular, for a feature with *q* distinct values the search space consists of *q-1* partitions if it can be ordered and of *2<sup>q-1</sup>-1* when it is nominal. Richer search spaces result in higher [VC-dimension](https://hastie.su.domains/Papers/ESLII.pdf) (Section 7.9) and require larger samples to prevent overfiting. 

To get a grip on the problem, imagine one treats a numeric variable measured with high precision as nominal. In this case, encountering repeated values is unlikely to improbable. With MTE such a variable will stronly correlate with target regardless whether there is any dependence between them &mdash; overfiting is obvious. 
Similarly, MTE itself is a casuse of overfiting problem only when one uses it for spliting not nominal features that can be ordered withoit MTE, i.e., categorical ordinal, numeric, or [discretized](https://towardsdatascience.com/feature-engineering-deep-dive-into-encoding-and-binning-techniques-5618d55a6b38) [numeric](https://machinelearningmastery.com/discretization-transforms-for-machine-learning/) with a large number of bins.

#### Hypothesis 1
*For ordinal features one should use label encoding that preserves the natural order of categories*



The 'out-of-sample encoding' suggested in [this blogpost](https://towardsdatascience.com/benchmarking-categorical-encoders-9c322bd77ee8) or this [NeurIPS paper](http://learningsys.org/nips17/assets/papers/paper_11.pdf) helps to reduce this overfitting by decreasing the correlation between the encoded and the target features. As a result, it lowers the 'observed' predictive power of nominal features with a big share of poorly represented categorues and tends to use [more] other features in tree construction.

#### Example 1

| cat  | target   |
|-|-|
| A  | 1  |
| B  | 1  |
| C  | 0  |
| D  | 0  |

Out-of-sample encoding for the above dataset would replace all categories with the prior target value 0.5 (check if this is default behavior!) making the feature irrelevant for tree construcion.


Another trick, dicussed in this [NeurIPS paper](http://learningsys.org/nips17/assets/papers/paper_11.pdf) is smoothing. Smoothing also changes correlation between the encoded feature and the target. It does so by reordering encoded values so that poorly represented classes become closer to each other when ordered by encoded values. 

#### Example 2

| cat  | target   |
|-|-|
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

Consider the above excerpt from some perfectly balanced (i.e., containing equal number of 0 and 1 in the column 'target') dataset. Assume that this excerpt contains all examples with category (column 'cat') values in {A,B,C}. The corresponding MTE values are {1,0.8,0.75} that orders these values descending as {A,B,C}. Let us now apply MTE with smoothing controlled by parameter *a* as in Equation (1) in [NeurIPS paper](http://learningsys.org/nips17/assets/papers/paper_11.pdf). Prior *P=1/2* for a perfectly balanced data. In what follows, we describe how does the parameter *a* affect the ordering of categories (descending).
- *a<1*, {A,B,C}
- *1<a<4/3*, {B,A,C}
- *4/3<a<4*, {B,C,A}
- *4<a*, {C,B,A}
One would select the values of the smoothing parameter *a* via hyperparameter optimization procedure with cross-validation (CV). Observe the following.
- many standard HPO procedures will waste time by considering *a* values that do not change the ordering. For a DT algorithm learning from the above table, *a=2* and *a=3* are equivalent.
- the number of all possible orders of a nominal feature is higher than the one achievable with smoothing. For instance, there is no *a* value for the above table, that would result in rankings {C,A,B} or {A,C,B}. 
- with CV, rankings of categories appearing in some folds for some *a* values might be forbidden in others.

#### Hypothesis 2
*(A) Perhaps, even more straightforward, faster, and maybe a better way to deal with nominal features of high cardinality is to replace all poorly represented values with a singe 'pseudo-category' before applying MTE.*

*(B) designing an intelligent procedure for optimization of the smoothing parameter may save time*

### Underfiting? MTE as preprocessing.

Can MTE be a reason of underfiting? Yes! The authors of [this blogpost](https://towardsdatascience.com/benchmarking-categorical-encoders-9c322bd77ee8), [another blogpost](https://medium.com/@darnelbolaos/target-encoding-function-with-r-8a037b219fb7), and of this [NeurIPS paper](http://learningsys.org/nips17/assets/papers/paper_11.pdf) argue that one often uses MTE as a *preprocessing* step, whereas building a decision tree is a *recursive* process, as we described. That is, one often sticks to *the same* encoding for splitting in each node of a tree instead of computing it only based on a subset of training data reaching that node. As a consecuence, nominal features that have high predictive power in subtrees may not be recognized as such. In another words, MTE as a preprocessing step may result in a loss of important information about *feature interaction*. Note, that some implementations of ML algorithms have native support for categorical features &mdash; [python example](https://scikit-learn.org/stable/modules/ensemble.html#categorical-support-gbdt), [R example](https://www.gormanalysis.com/blog/decision-trees-in-r-using-rpart/).

#### Example 3

| cat1  | cat2 | target   | 
|-|-|-|
| A  |C| 1  |
| A  |C| 1  |
| A  |D| 0  |
| B  |C| 0  |
| B  |C| 0  |
| B  |D| 1  |

The above table illustrates a special case of the phenomenon just described when encoding reduces the feature cardinality. 
- If one applies MTE recursively (node-wise) as in conventional decision tree, they will learn the structure p(1|AC) = 1, p(1|AD) = 0, p(1|BC) = 0, p(1|BD) = 1 
- If one uses MTE as a pre-processing step, both values C and D of cat2 are replaced with 0.5, and cat2 is not used for tree construction. The resulting tree is then p(1|A) = 2/3, p(1|B) =1/3 

We warn from using feature cardinality reduction as indicator of underfitting or, in general, of any problem with the encoding. To see this, observe that MTE applied to the table from Example 1 reduces cardinality and leads to overfitting. 


#### Hypothesis 3
*Perhaps, the success of CatBoost can be partially explained by te fact that it does not use encoding as a preprocessing step but does it recursively (see section **Feature combinations** in [NeurIPS paper](http://learningsys.org/nips17/assets/papers/paper_11.pdf)) in a way a conventional tre learning algorithm suggests*

### R examples



### Conclusion

Combination of hypotheses 0&ndash;3, if not yet tried out, might result in a state-of-the-art algorithm for learnig boosted trees.


