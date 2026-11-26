---
title: Information Analysis and Processing for Training (Master's Degree, 2025/2026)
subtitle: Science in Preventive and Adapted Physical Activity · University of Udine
summary: Data mining in sport and relational database design, with a cycling database built and queried in SQLite using DBeaver.
date: '2026-09-28T10:00:00+02:00'
course_updated: '2026-11-24'
draft: false
url: /post/information-analysis-for-training-masters/2025-2026/
course_parent: /post/information-analysis-for-training-masters/
course_edition: '2025/2026'
course_hidden: true
authors: [admin]
---

## About this edition

I focused on two questions: how can we evaluate a prediction about sports performance, and how should we organise the data we need for the analysis? I used road cycling as a case study: students recorded riders, races and results in a database and used SQL to produce a race report.

- **Degree:** Master's Degree in Science in Preventive and Adapted Physical Activity, University of Udine
- **Course:** *Sistemi di Analisi ed Elaborazione delle Informazioni per l'Allenamento* (MM2542)
- **Part of the integrated course:** *Discipline Motorie 1*
- **Instructor:** Michael Soprano
- **Workload:** 3 CFU, 24 teaching hours
- **Period:** 7 November 2025 to 30 January 2026, first teaching period of the first year
- **Language:** Italian

[Course in the Uniud Course Catalogue](https://uniud.coursecatalogue.cineca.it/corsi/2025/10996/insegnamenti/2025/21817-2/2025/9999?coorte=2025&schemaid=12813&adCodRadice=MM2549)

## Programme

An introductory review covers populations, samples, variables and measurement scales. Heart rate records, GPS tracks and athletes’ own reports illustrate what different sources can tell us about a training session.

### Module 1: Introduction to data mining

- **Defining the question.** Identify what each observation represents, such as a rider or a training session. Define the outcome and choose inputs that are available when the prediction is made.
- **Choosing a method.** Classification predicts a category, such as session intensity; regression estimates a value, such as race time. Clustering groups similar athletes without a known outcome. Other tasks include detecting unusual sensor readings and forecasting training load.
- **Testing a model.** Compare predictions with a simple baseline on data not used for training. For records collected over time, train on earlier observations and test on later ones. A confusion matrix shows how the decision threshold affects false alarms and missed cases; accuracy, precision, recall and F1 summarise different aspects of performance.
- **Interpreting results.** Missing values, outliers, unrepresentative samples and information recorded after a decision can distort an analysis. Two measurements can also appear related simply because both change over time.

### Module 2: Relational databases

- **Requirements and conceptual design.** An entity and relationship diagram describes what the database must record. For the *Pedale Udinese* cycling case, this means distinguishing riders, teams, seasons and races from events such as a rider entering a race. Topics include identifiers, cardinality, optional participation and entity hierarchies.
- **Relational design.** Translate the diagram into tables, columns and keys. A rider can enter several races and a race can have several riders, so entries need their own table. Foreign keys link each entry to an existing rider and race.
- **Normalisation.** Functional dependencies and the first three normal forms explain how to avoid repeating facts. Keeping race details separate from individual results allows a race to be recorded before it has any participants.
- **Building a database.** Create and inspect a SQLite database in DBeaver. SQL defines the tables and their constraints: for example, a race number must be unique within a cycling season.
- **Changing records.** Insert, update and delete rows using SQL and the DBeaver data grid. Foreign key rules determine whether a change is rejected, passed on to related rows or leaves an optional reference empty.
- **Queries and reports.** Filter and sort rows, join tables, calculate totals and filter groups. The race report counts distinct riders per race and uses a left join to retain races that do not belong to a competition. Results can be exported to CSV or Excel.

## Materials

Slides and recordings are available in the course group on Microsoft Teams. The cycling exercises include a requirements document, diagrams for the basic and extended designs, SQLite databases and SQL scripts for creating tables, loading sample data and running queries.

Recommended reading:

- *Data Mining: Practical Machine Learning Tools and Techniques*, fourth edition
- *Basi di dati. Progettazione concettuale, logica e SQL*, Giorgio M. Di Nunzio and Emanuele Di Buccio

## Assessment

The written exam has four open questions worth 5 points each and one exercise worth 11 points, for a total of 31 points.
