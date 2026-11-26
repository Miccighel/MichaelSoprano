---
title: Social Computing (2020/2021)
subtitle: Internet of Things, Big Data & Web · University of Udine
summary: Students mapped follower relationships on Twitter and designed a crowdsourcing task to compare different editions of books.
date: '2026-09-28T10:00:00+02:00'
course_updated: '2026-11-24'
draft: false
url: /post/social-computing/2020-2021/
course_parent: /post/social-computing/
course_edition: '2020/2021'
course_hidden: true
authors: [admin]
---

## About this edition

The course explored how information spreads through social networks and how to collect and interpret judgements from a crowd. I taught the practical sessions and prepared two group assignments. In the first, students used Twitter data to investigate what makes an account central to a network. In the second, they designed a task to find out what readers value in a particular edition of a book.

- **Course instructor:** [Stefano Mizzaro](https://users.dimi.uniud.it/~stefano.mizzaro/)
- **Teaching assistant:** Michael Soprano

[Official Uniud course page (Moodle)](https://elearning.uniud.it/moodle/course/info.php?id=2982)

## Practical programme

- **Collecting Twitter data.** Students used Python and Tweepy to retrieve account profiles, list followers and check whether one account followed another. A separate notebook illustrated how to make requests directly to the Twitter API.
- **Analysing networks.** With NetworkX, students represented accounts as nodes and follower relationships as directed edges. They explored paths between accounts and compared different measures of centrality.
- **Designing crowdsourcing tasks.** Students explored how Amazon Mechanical Turk works and used Crowd_Frame to present items to participants, explain what to assess and collect their answers.

## First assignment: mapping a Twitter network

Each group started with five Twitter accounts. Students collected their followers and the accounts they followed, then sampled both lists to explore connections one step further. They stored profile information on each node and used PyVis to build an interactive view of the network.

Students examined connectivity, distances and small world properties. They compared measures such as degree, betweenness and PageRank to see whether the accounts with the most connections also linked different parts of the network. They used Pearson and Kendall correlations to compare the results.

## Second assignment: comparing book editions

Each group designed one experiment in Crowd_Frame and divided it into six sets. Each participant assessed one set: three different books, with one edition of each. The group placed different editions of the same title in separate sets and varied the order so that a book would not always appear first or last.

- **Collecting judgements.** Classmates answered questions about their reading habits, then saw each edition’s cover, price and publication details. They indicated whether they would buy it, rated how appropriate the price was on a scale of 1 to 10 and explained their impression in their own words.
- **Interpreting the results.** Students summarised the readers’ responses, compared price ratings across editions and books, and examined the length of the written explanations.

## Materials

The practical sessions used Jupyter notebooks with examples of Twitter API requests, graph analysis in NetworkX and exercises in Python.

- [Crowd_Frame source code and examples](https://github.com/Miccighel/Crowd_Frame)
- [Paper introducing Crowd_Frame](/publication/conference-paper-wsdm-2022/)
