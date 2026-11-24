---
title: Information Analysis and Processing for Training (Master's Degree, 2026/2027)
subtitle: Science in Preventive and Adapted Physical Activity · University of Udine
summary: Data quality, relational database design and SQL for sport, with examples from football and road cycling.
date: '2026-09-28T10:00:00+02:00'
course_updated: '2026-11-24'
draft: false
url: /post/information-analysis-for-training-masters/2026-2027/
course_parent: /post/information-analysis-for-training-masters/
course_edition: '2026/2027'
course_hidden: true
authors: [admin]
---

## About this edition

I start with a question about training logs: does one row represent an athlete, a session or a single measurement? Students first learn to interpret and check these records. They then design a database for a football championship and learn how SQL can answer questions about sports data. Familiarity with spreadsheets and basic descriptive statistics is useful.

- **Degree:** Master's Degree in Science in Preventive and Adapted Physical Activity, University of Udine
- **Course:** *Sistemi di Analisi ed Elaborazione delle Informazioni per l'Allenamento* (MM2542)
- **Part of the integrated course:** *Discipline Motorie 1*
- **Instructor:** Michael Soprano
- **Workload:** 3 CFU, 24 teaching hours
- **Period:** 5 November to 17 December 2026, first teaching period of the first year
- **Language:** Italian

[Course in the Uniud Course Catalogue](https://uniud.coursecatalogue.cineca.it/corsi/2026/10996/insegnamenti/2026/21817-2/2026/9999?coorte=2026&schemaid=13835&adCodRadice=MM2549)

## Programme

### Module 1: Data quality and organisation

- **Interpreting a dataset.** Decide what one row represents: an athlete, a session or a measurement. Distinguish the population from the sample and check what each variable measures, on which scale and in which units.
- **Checking data quality.** Check units, formats and metadata before deciding whether a value is missing, duplicated or simply unusual. Keep the original measurements and document corrections so another person can repeat them.
- **Organising records.** Store athlete details separately from training sessions and link them with identifiers. This avoids having to update the same information in several rows.

### Module 2: Relational database design

- **Databases and conceptual design.** Define what the database needs to record and what its management system (DBMS) does. In an entity and relationship (ER) diagram, distinguish entities, their attributes and the identifiers that tell instances apart.
- **Relationships and cardinality.** Specify how many times an entity can participate in a relationship and whether participation is optional. In a football championship, minutes played describe a player’s participation in a particular match, not the player or match alone. Other examples cover roles, recursive relationships and relationships involving three entities.
- **Hierarchies.** Model different types of training session. A specific type inherits the attributes of a session. Two separate questions determine the constraints: must every session have a type, and can it have more than one?
- **The relational model.** Distinguish a table’s schema from the rows it currently contains. Define allowed values and constraints, interpret `NULL`, choose a primary key and use foreign keys to refer to existing records.
- **Translating an ER diagram into tables.** Apply the mapping rules to entities, attributes, relationships and hierarchies. In the championship database, a foreign key can link a player to a team, while a separate table records which players took part in which matches.
- **Normalisation.** Examine what goes wrong when a participation record repeats facts about a match, player or team. Use functional dependencies and the first three normal forms to separate those facts, then check that the original information can be reconstructed.
- **Database design exercise.** In the next exercise, students read a short description of what a database must record. They identify the entities and relationships, draw an ER diagram and turn it into tables with primary and foreign keys. They then check the design against the first three normal forms and use sample records to test the requirements. For example, if the same person can take part in several events, the tables should record each participation without repeating the person’s details.

### Module 3: Managing and querying databases

This module follows the design exercise. The planned topics are:

- **Working with SQLite.** Use DBeaver to create and inspect tables, define keys and constraints, and insert, update or delete records.
- **Answering questions with SQL.** Filter and sort results, count entries per race with `GROUP BY` and filter those counts with `HAVING`. Compare `JOIN` and `LEFT JOIN`: the choice matters when a report should also include races with no entries.

## Materials

Students can find slides, recordings and exercises in the course group on Microsoft Teams. The design materials also include the *Pedale Udinese* cycling club’s requirements and an example ER diagram. SQL scripts and sample SQLite databases are planned for the practical module.

For further reading, the recommended book is *Basi di dati. Progettazione concettuale, logica e SQL* by Giorgio M. Di Nunzio and Emanuele Di Buccio. The official SQLite and DBeaver documentation are useful references for practical work.

## Assessment

The written exam lasts two hours. It has four open questions on the theory and one ER design exercise. Each theory answer is marked out of 10; the combined mark is then halved, so the four answers contribute up to 20 points. The design exercise is worth 11 points. A total of 31 points earns 30/30 with honours.
