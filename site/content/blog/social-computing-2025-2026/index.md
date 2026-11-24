---
title: Social Computing (2025/2026)
subtitle: Internet of Things, Big Data, Machine Learning · University of Udine
summary: Students designed a task in which participants rated public statements and reported how confident they were in each judgement.
date: '2026-09-28T10:00:00+02:00'
course_updated: '2026-11-24'
draft: false
url: /post/social-computing/2025-2026/
course_parent: /post/social-computing/
course_edition: '2025/2026'
course_hidden: true
authors: [admin]
---

## About this edition

I taught the lecture on crowdsourcing. It lasted two hours and included a practical exercise with Crowd_Frame. Students designed a task in which participants assessed three political statements that PolitiFact had checked.

- **Course instructor:** [Stefano Mizzaro](https://users.dimi.uniud.it/~stefano.mizzaro/)
- **Teaching assistant:** Michael Soprano

[Course in the Uniud Course Catalogue](https://uniud.coursecatalogue.cineca.it/corsi/2023/10643/insegnamenti/2025/20578/2020/9999?coorte=2023&schemaid=12952)

## Crowdsourcing with Crowd_Frame

- **Recruiting participants and designing a task.** The lecture compared two ways to run a task: build it inside Amazon Mechanical Turk, or recruit participants through a platform and send them to a separate interface built with Crowd_Frame. In Crowd_Frame, the researcher sets the instructions, the items to assess and the response scale in JSON files.
- **Rating a claim.** For each statement, participants saw who said it and when. They chose one of six ratings on the PolitiFact scale, from “Pants on Fire” to “True”. Students then added a question asking participants to rate their confidence in each judgement on a scale of 1 to 100.
- **Reading the results.** A sample export showed what one participant had recorded for each statement: the rating, their confidence and the time they spent on it.

## Materials

The exercise used two example configurations. The first contained the three practice statements. The second came from the study [Crowdsourced Fact-checking: Does It Actually Work?](/publication/journal-paper-ipm-2024-2/). In that configuration, participants also provided evidence for their judgements.

- [Crowd_Frame source code and examples](https://github.com/Miccighel/Crowd_Frame)
- [Paper introducing Crowd_Frame](/publication/conference-paper-wsdm-2022/)
