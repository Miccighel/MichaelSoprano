---
# Documentation: https://wowchemy.com/docs/managing-content/

title: 'How Many Crowd Workers Do I Need? On Statistical Power When Crowdsourcing Relevance Judgments'
subtitle: ''
summary: ''
authors:
- Kevin Roitero
- David La Barbera 
- Michael Soprano
- Gianluca Demartini
- Stefano Mizzaro
- Tetsuya Sakai
tags: 
- relevance judgments 
- statistical analysis 
- crowdsourcing
categories: []
date: '2023-05-22'
lastmod: 2023-05-22T15:00:00+01:00
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
publishDate: '2021-09-15T15:00:00+01:00'
publication_types:
- '2'
abstract: 'To scale the size of Information Retrieval collections, crowdsourcing has become a common way to collect relevance judgments at scale. Crowdsourcing experiments usually employ 100-10,000 workers, but such a number is often decided in a heuristic way. The downside is that the resulting dataset does not have any guarantee of meeting predefined statistical requirements as, for example, have enough statistical power to be able to distinguish in a statistically significant way between the relevance of two documents. We propose a methodology adapted from literature on sound topic set size design, based on t-test and ANOVA, which aims at guaranteeing the resulting dataset to meet a predefined set of statistical requirements. We validate our approach on several public datasets. Our results show that we can reliably estimate the recommended number of workers needed to achieve statistical power, and that such estimation is dependent on the topic, while the effect of the relevance scale is limited. Furthermore, we found that such estimation is dependent on worker features such as agreement. Finally, we describe a set of practical estimation strategies that can be used to estimate the worker set size, and we also provide results on the estimation of document set sizes.'
publication: '*ACM Transactions on Information Systems. Journal Ranks: Journal Ranks: Journal Citation Reports (JCR) Q1 (2021), Scimago (SJR) Q1 (2021).*'
doi: 10.1145/3597201
---
