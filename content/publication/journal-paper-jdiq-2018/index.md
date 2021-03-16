---
# Documentation: https://wowchemy.com/docs/managing-content/

title: 'Reproduce and Improve: An Evolutionary Approach to Select a Few Good Topics
  for Information Retrieval Evaluation'
subtitle: ''
summary: ''
authors:
- Kevin Roitero
- Michael Soprano
- Andrea Brunello
- Stefano Mizzaro
tags: 
- topic selection strategy 
- evolutionary algorithms 
- reproducibility 
- test collection
- few topics
- topic sets
categories: []
date: '2018-01-01'
lastmod: 2021-03-15T15:36:39+01:00
featured: false
draft: false

# Featured image
# To use, add an image named `featured.jpg/png` to your page's folder.
# Focal points: Smart, Center, TopLeft, Top, TopRight, Left, Right, BottomLeft, Bottom, BottomRight.
image:
  caption: ''
  focal_point: ''
  preview_only: false

# Projects (optional).
#   Associate this post with one or more of your projects.
#   Simply enter your project's folder or file name without extension.
#   E.g. `projects = ["internal-project"]` references `content/project/deep-learning/index.md`.
#   Otherwise, set `projects = []`.
projects: []
publishDate: '2021-03-15T14:36:38.653339Z'
publication_types:
- '2'
abstract: 'Effectiveness evaluation of information retrieval systems by means of a test collection is a widely used methodology. However, it is rather expensive in terms of resources, time, and money; therefore, many researchers have proposed methods for a cheaper evaluation. One particular approach, on which we focus in this article, is to use fewer topics: in TREC-like initiatives, usually system effectiveness is evaluated as the average effectiveness on a set of n topics (usually, n=50, but more than 1,000 have been also adopted); instead of using the full set, it has been proposed to find the best subsets of a few good topics that evaluate the systems in the most similar way to the full set. The computational complexity of the task has so far limited the analysis that has been performed. We develop a novel and efficient approach based on a multi-objective evolutionary algorithm. The higher efficiency of our new implementation allows us to reproduce some notable results on topic set reduction, as well as perform new experiments to generalize and improve such results. We show that our approach is able to both reproduce the main state-of-the-art results and to allow us to analyze the effect of the collection, metric, and pool depth used for the evaluation. Finally, differently from previous studies, which have been mainly theoretical, we are also able to discuss some practical topic selection strategies, integrating results of automatic evaluation approaches.'
publication: '*ACM Journal of Data and Information Quality - Special Issue on Reproducibility
  in IR: Evaluation Campaigns, Collections and Analyses (JDIQ), 10(3):12:1–12:21,
  September 2018. Journal Rank: Scimago Q2 (2018)*'
doi: 10.1145/3239573
---
