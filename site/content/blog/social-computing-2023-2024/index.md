---
title: Social Computing (2023/2024)
subtitle: Internet of Things, Big Data, Machine Learning · University of Udine
summary: Students designed a crowdsourcing task to assess the quality of Amazon product reviews and tested it with classmates.
date: '2026-09-28T10:00:00+02:00'
course_updated: '2026-11-24'
draft: false
url: /post/social-computing/2023-2024/
course_parent: /post/social-computing/
course_edition: '2023/2024'
course_hidden: true
authors: [admin]
---

## About this edition

I taught two lectures on crowdsourcing, four hours in total, and prepared the second course assignment. The first assignment focused on networks of coauthors. For the second, students used Crowd_Frame, the framework I developed, to collect judgements about the quality of Amazon product reviews.

- **Course instructor:** [Stefano Mizzaro](https://users.dimi.uniud.it/~stefano.mizzaro/)
- **Teaching assistants:** David La Barbera and Michael Soprano

[Course in the Uniud Course Catalogue](https://uniud.coursecatalogue.cineca.it/corsi/2021/10643/insegnamenti/2023/20578/2020/9999?coorte=2021&schemaid=11683)

## Crowdsourcing with Crowd_Frame

- **Recruiting participants.** The lectures compared Amazon Mechanical Turk and Prolific. The Mechanical Turk sandbox showed both sides of a task: a researcher publishes a batch of work, and a participant accepts and completes one unit.
- **Designing a task.** In Crowd_Frame, the researcher defines which items each participant sees, the instructions they receive and the scales they use. An example showed how items with known answers can help check the quality of responses.
- **Reading the results.** Crowd_Frame exports responses as CSV tables. The lectures distinguished tables with one row per participant from those that record each answer, so a researcher can link a judgement to the item that prompted it.

## Second assignment: assessing product reviews

Each group built a task in Crowd_Frame for classmates to judge the quality of Amazon reviews. The subject of each judgement was the review itself: for example, could a reader trust what the reviewer wrote, and did the review give enough information about the product?

- **Preparing the reviews.** Each group selected 15 reviews from its assigned dataset. Students wrote a Jupyter notebook to give each of 15 participants five different reviews. This way, five people judged each review independently, without anyone having to read all 15.
- **Designing the rating form.** The form showed the product name and brand alongside the review text and date. Participants rated six aspects of the review: reliability, neutrality, clarity, precision, completeness and informativeness. For each aspect, they chose one of five answers ranging from complete disagreement to complete agreement. They then rated their confidence in their own judgement from 1 to 100 and explained why.
- **Running the task.** Each group published its task in the Amazon Mechanical Turk sandbox, a test environment. Students from other groups took part as reviewers and completed their assigned set of five reviews.

## Materials

- [Crowd_Frame source code and examples](https://github.com/Miccighel/Crowd_Frame)
- [Paper introducing Crowd_Frame](/publication/conference-paper-wsdm-2022/)
