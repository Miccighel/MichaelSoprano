---
title: Social Computing (2022/2023)
subtitle: Internet of Things, Big Data, Machine Learning · University of Udine
summary: Students designed a crowdsourcing task to collect judgements about claims and compare explanations written by people with those produced by models.
date: '2026-09-28T10:00:00+02:00'
course_updated: '2026-11-24'
draft: false
url: /post/social-computing/2022-2023/
course_parent: /post/social-computing/
course_edition: '2022/2023'
course_hidden: true
authors: [admin]
---

## About this edition

I taught two lectures on crowdsourcing, four hours in total, and prepared the second course assignment. The first assignment explored networks of followers on Twitter. For the second, students used Crowd_Frame, the framework I developed, to ask classmates how truthful they found a claim and how they rated the explanation for it.

- **Course instructor:** [Stefano Mizzaro](https://users.dimi.uniud.it/~stefano.mizzaro/)
- **Teaching assistants:** David La Barbera and Michael Soprano

[Course in the Uniud Course Catalogue](https://uniud.coursecatalogue.cineca.it/corsi/2021/10643/insegnamenti/2022/20578/2020/9999?coorte=2021)

## Crowdsourcing with Crowd_Frame

- **Recruiting participants.** The lectures compared Amazon Mechanical Turk and Prolific. A researcher could recruit participants through either platform while using Crowd_Frame to present the task and record responses.
- **Designing a task.** The researcher chose which items each participant would see, what to ask about each item and which response scale to use. The lectures also showed how to include items with known answers as a check on the responses.
- **Reading the results.** Crowd_Frame exported ratings, questionnaire responses and text annotations in separate CSV tables. The examples showed how to distinguish a participant’s answer from the passage they had marked in the text.

## Second assignment: assessing claims and explanations

Each group built a task around two separate questions: how truthful is a statement, and how good is the explanation for its verdict? The dataset contained statements with a verdict and explanations from two sources: people and models.

- **Preparing the task.** Each group created 12 work units. Each unit contained three items in random order: two with an explanation produced by a model and one with an explanation written by a person. Each model explanation went to three participants and each human explanation to two.
- **Collecting judgements.** Participants rated a statement on a truthfulness scale with six categories. They marked text in the explanation and rated its quality from 1 to 100. They also gave a second truthfulness rating, citing a web source and briefly explaining their answer.
- **Running the task.** Classmates from other groups completed the work units in the Amazon Mechanical Turk sandbox. Each group then downloaded the responses collected by its task.

## Materials

- [Crowd_Frame source code and examples](https://github.com/Miccighel/Crowd_Frame)
- [Paper introducing Crowd_Frame](/publication/conference-paper-wsdm-2022/)
