---
title: Social Computing (2021/2022)
subtitle: Internet of Things, Big Data & Web · University of Udine
summary: Students built a network of Twitter accounts, then selected tweets from that network and asked classmates to annotate them.
date: '2026-09-28T10:00:00+02:00'
course_updated: '2026-11-24'
draft: false
url: /post/social-computing/2021-2022/
course_parent: /post/social-computing/
course_edition: '2021/2022'
course_hidden: true
authors: [admin]
---

## About this edition

I taught the practical sessions on Twitter data collection, network analysis and crowdsourcing, and prepared the course assignments. The two assignments used the same data for different questions: who follows whom on Twitter, and how consistently do people interpret the tweets those accounts publish?

- **Course instructor:** [Stefano Mizzaro](https://users.dimi.uniud.it/~stefano.mizzaro/)
- **Teaching assistant:** Michael Soprano
- **Planned practical teaching:** 6 sessions, 12 hours in total

[Official Uniud course page (Moodle)](https://elearning.uniud.it/moodle/course/info.php?id=3774)

## Practical programme

- **Collecting social media data.** Students used Python notebooks to request profiles, tweets and follower lists. They used Tweepy and also sent requests directly to version 2 of the Twitter API, selecting fields and retrieving results across multiple pages.
- **Representing a network.** With NetworkX, students represented accounts as nodes and used directed edges to record who followed whom. They attached profile data to nodes, examined connections and drew graphs.
- **Crowdsourcing with Crowd_Frame.** Students learned to assign items to participants, write instructions, define response scales and download the answers. The Amazon Mechanical Turk sandbox let classmates try a task as participants.

## First assignment: mapping a Twitter network

Each group started with two Twitter accounts. For each account, students sampled five followers and five accounts it followed, then repeated the process for the sampled accounts. They stored profile information and recent tweets alongside the network.

Students compared the full graph with two subgraphs, one for follower relationships and one for following relationships. They visualised all three with PyVis and examined connectivity, clustering and distances. They also compared centrality measures to see whether different ways of identifying important accounts gave similar rankings.

## Second assignment: annotating tweets

Each group selected 15 tweets from the first assignment, one per author, and built a task in Crowd_Frame. Participants saw only the tweet text. Each participant assessed five different tweets, and each tweet went to five participants.

- **Designing the questions.** Participants indicated whether a tweet expressed an opinion and whether it mentioned a place, a person, an event or something else. They explained their classification, counted the words and answered one further question chosen by the group. Each set included a tweet with a known word count as a quality check.
- **Comparing judgements.** Classmates completed the task in the Mechanical Turk sandbox. Students calculated percentage agreement separately for the opinion question and the topic question. They used the reported word counts to estimate average tweet length and a short questionnaire to describe participants’ use of Twitter.

## Materials

The practical exercises used Jupyter notebooks for Python, access to Twitter data and graph analysis with NetworkX.

- [Crowd_Frame source code and examples](https://github.com/Miccighel/Crowd_Frame)
- [Paper introducing Crowd_Frame](/publication/conference-paper-wsdm-2022/)
