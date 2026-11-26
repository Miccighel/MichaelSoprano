---
title: Social Computing (2024/2025)
subtitle: Internet of Things, Big Data, Machine Learning · University of Udine
summary: Students designed a crowdsourcing task using three political statements and examined how participants’ ratings appeared in the results.
date: '2026-09-28T10:00:00+02:00'
course_updated: '2026-11-24'
draft: false
url: /post/social-computing/2024-2025/
course_parent: /post/social-computing/
course_edition: '2024/2025'
course_hidden: true
authors: [admin]
---

## About this edition

I taught the lecture on crowdsourcing. It lasted two hours and included a practical exercise with Crowd_Frame, the framework I developed. Students designed a task in which participants assessed three political statements that PolitiFact had checked.

- **Course instructor:** [Stefano Mizzaro](https://users.dimi.uniud.it/~stefano.mizzaro/)
- **Teaching assistants:** Hafsa Akebli, Michele Lizzit and Michael Soprano

[Course in the Uniud Course Catalogue](https://uniud.coursecatalogue.cineca.it/corsi/2022/10643/insegnamenti/2024/20578/2020/9999?coorte=2022&schemaid=12049)

## Crowdsourcing with Crowd_Frame

- **Designing a task.** The lecture used Amazon Mechanical Turk to illustrate how a researcher builds an interface and assigns different items to participants. With Crowd_Frame, the platform can recruit participants while the researcher defines the task separately in JSON files.
- **Choosing what to measure.** Students configured the instructions and the statements to display, including who made each claim and when. Participants could rate each claim on PolitiFact’s scale of six categories. A second question asked how confident they were in their rating, on a scale of 1 to 100.
- **Reading the results.** A sample CSV file showed how to read one participant’s responses across the three statements. Each row recorded the statement, the rating, the confidence score and the time spent on that statement.

## Materials

The exercise used two example configurations. The first contained the three practice statements. The second came from the study [Crowdsourced Fact-checking: Does It Actually Work?](/publication/journal-paper-ipm-2024-2/).

- [Crowd_Frame source code and examples](https://github.com/Miccighel/Crowd_Frame)
- [Paper introducing Crowd_Frame](/publication/conference-paper-wsdm-2022/)
