---
title: Information Analysis and Processing for Training
subtitle: Bachelor's Degree in Sports Science and Master's Degree in Sciences and Techniques of Preventive and Adapted Physical Activities at the University of Udine

summary: "Courses offered within the Bachelor's Degree in Sports Science and the Master's Degree in Sciences and Techniques of Preventive and Adapted Physical Activities at the University of Udine"

projects: []

date: "2024-08-07T11:00:00Z"
lastmod: "2026-06-09T13:00:00Z"
draft: false
featured: false

image:
  caption: 'Image credit: [**Unsplash**](https://unsplash.com/photos/CpkOjOcXdUY)'
  focal_point: ""
  placement: 2
  preview_only: false

authors:
  - admin

tags:
  - Data Analysis
  - Sports Science
  - Data Science
  - Data Mining
  - Microsoft Excel
  - Data Representation
  - Data Visualization
  - Compression
  - Information Theory
  - Relational Databases
  - SQL
  - SQLite
  - DBeaver
  - Teaching
  - Spreadsheet Analysis
  - PivotTables

categories:
  - teaching
---

# Aims

These courses address the analysis and processing of information for sport and training from two complementary perspectives. They share the same broad teaching area, but they are distinct courses offered at different degree levels and organized around different learning goals, tools, and assessment methods.

The **Bachelor's Degree course** introduces the foundations needed to work with data in sport contexts. Students learn what data are, how information is represented in digital systems, and how structured datasets can be prepared, analyzed, summarized, and communicated with spreadsheet tools.

The **Master's Degree course** develops a more structured and reproducible view of data work. Students learn how to frame data mining problems, design relational databases, implement them with a DBMS, and query them with SQL to obtain reusable datasets.

The two courses follow a coherent progression from **understanding and representing data** to **organizing, querying, and reusing data in controlled workflows**. Their shared goal is to help students transform raw data into meaningful information that can support interpretation and decision making in sport and training contexts.

## Courses

- **Bachelor's Degree Course**: foundational data concepts, digital representation of information, and spreadsheet based data analysis with Microsoft Excel
- **Master's Degree Course**: data mining foundations, relational database design, database implementation, and SQL querying

## Quick Access

- [Bachelor's Degree Course](#bachelors-degree-course)
- [Master's Degree Course](#masters-degree-course)

## Teacher

- **Michael Soprano** - Course Instructor

The two courses consist of 12 lectures for a total of 24 hours.

# Bachelor's Degree Course

The Bachelor's Degree course introduces the basic vocabulary and tools needed to work with data in sport and training contexts. Students first learn how to describe data, variables, and measurements. They then study how different kinds of information are represented digitally. The final part of the course focuses on Microsoft Excel as a tool for preparing, analyzing, visualizing, and summarizing structured data.

## Topics Covered

### Module 1 - Introduction to Data Science in Sport

- Data, information, knowledge, and the DIKW pyramid in sport and training contexts
- Structured and unstructured data from sport-related sources
- Sensors, SportsTech, and examples of data-driven decision making in sport
- From raw data to information through preparation, analysis, visualization, and communication
- Tables, observations, variables, and values
- Populations, samples, units of analysis, and levels of measurement
- Qualitative and quantitative variables
- Sport-related data types, including biometric, position and movement, subjective, and performance data

### Module 2 - Representation and Management of Data

- Basic computer architecture: memory, storage, peripherals, CPU, and operating system
- Data storage in the filesystem
- Files, folders, metadata, hierarchical organization, and paths
- Bits, bytes, binary code, and digital encodings
- Text: character sets, encodings, ASCII, Unicode, and UTF-8
- Images: raster graphics, vector graphics, color representation, and main file formats
- Sound: wave characteristics, sampling, quantization, channels, MIDI messages, and audio formats
- Video: sequences of images, movement, frame rate, resolution, and video formats
- The Shannon-Weaver model of communication
- Entropy and redundancy of information
- Why data compression is useful
- Lossless and lossy compression

### Module 3 - Data Analysis with Microsoft Excel

- Elements of the Excel interface, workbooks, and worksheets
- Managing cells, rows, columns, and ranges
- Entering, editing, deleting, and formatting data
- Applying numeric, date, time, text, and currency formats
- Working with contiguous, non-contiguous, and multi-sheet ranges
- Managing rows and columns and navigating large worksheets
- Relative, absolute, and mixed references
- Introduction to formulas and functions
- Formula syntax: references, operators, precedence, and common errors
- Function syntax: arguments, result types, nesting, and basic summary functions
- Practical exercise on Boston Marathon 2025 data, including data cleaning, derived columns, summary statistics, and a mini dashboard
- Importing structured data from text files, including delimiters, encodings, and common import problems
- Introduction to Power Query for importing and preparing data
- Working with Excel tables
- Creating, managing, and formatting charts
- Examples with line, scatter, and area charts
- Basic measures of correlation
- Introduction to PivotTables and PivotCharts
- Using PivotTables to summarize and explore Fitbit data

## Learning Approach

The Bachelor's Degree course is organized around foundational concepts and applied spreadsheet activities. Students first acquire the vocabulary needed to describe datasets, then study how different types of information are represented digitally, and finally practice data analysis in Excel through guided examples and exercises.

## Assessment

The Bachelor's Degree course is assessed through a written exam with multiple-choice questions.

## Reading Material

- Peter O'Donoghue, Lucy Holmes, *Data Analysis in Sport*. Routledge Studies in Sports Performance Analysis, First edition, 2014
- Michael Alexander, Dick Kusleika, *Excel 365 Bible*. Wiley, First edition, 2022

# Master's Degree Course

The Master's Degree course moves toward structured, reproducible, and technically controlled data workflows. The course connects data mining, relational modeling, database implementation, and SQL querying.

## Topics Covered

### Preparatory Recall - Data Science Foundations

- Data, information, and knowledge in reproducible data workflows
- Sport-related data types, including biometric, movement, subjective, and performance data
- Tables as representations of observations, variables, and values
- Units of analysis, variables, scales of measurement, and metadata
- Data quality, coherent types, identifiers, and first normal form
- Privacy and protection of personal and health-related data

### Module 1 - Introduction to Data Mining

- Data science as a reproducible process from data to decision
- Project workflow: understanding, preparation, exploration, modeling, interpretation, and deployment
- Populations, samples, representativeness, and sampling error
- Variables, features, targets, and units of analysis
- Problem formulation in sport-related scenarios
- Typical data mining tasks: classification, regression, clustering, association, anomaly detection, and time series analysis
- Learning paradigms: supervised, unsupervised, and other basic settings
- Baselines, training and test data, validation strategies, and evaluation on unseen data
- Metrics for model evaluation and comparison
- Methodological issues: missing values, outliers, temporal consistency, leakage, imbalance, and data quality
- Interpretability, reproducibility, and documentation of modeling choices

### Module 2 - Relational Databases

- Databases as persistent, coherent, and shared collections of data
- DBMSs and the role of persistence, scale, globality, reliability, efficiency, and privacy
- Conceptual, logical, and physical levels of database design
- Entity-Relationship modeling: entities, attributes, relationships, cardinalities, identifiers, and constraints
- Binary, recursive, and n-ary relationships
- Hierarchies and alternative modeling choices in ER schemas
- Relational model: relations, tables, tuples, attributes, domains, schemas, instances, and NULL values
- Relational constraints: domains, primary keys, uniqueness, and referential integrity
- Translation from ER schemas to relational schemas
- Many-to-many, one-to-many, one-to-one, and recursive relationships in the relational model
- Redundancy, update anomalies, insertion anomalies, and deletion anomalies
- Normalization up to 3NF as an operational method for reducing uncontrolled redundancy
- Practical case study on road cycling races, from requirements to ER schema and relational schema
- SQLite as an embedded relational DBMS based on a single database file
- DBeaver as a graphical client for exploring schemas, tables, data, and relationships
- SQL scripts and controlled population of a database
- DDL for schema definition: `CREATE TABLE`, `DROP TABLE`, `ALTER TABLE`, types, keys, and constraints
- DML for data manipulation: `INSERT`, `UPDATE`, and `DELETE`
- SQL queries for data retrieval: `SELECT`, `FROM`, `WHERE`, `ORDER BY`, `LIMIT`, `AS`, and calculated columns
- Aggregations and grouping with `COUNT`, `MIN`, `MAX`, `AVG`, `SUM`, `GROUP BY`, and `HAVING`
- Joining tables to integrate information, including `JOIN` and `LEFT JOIN`
- Exporting query results as reusable datasets for subsequent analysis and reporting

## Learning Approach

The Master's Degree course emphasizes structured and reproducible workflows. Students connect data science concepts to relational database design, SQL extraction, and reusable data preparation. The course combines conceptual modeling, database implementation, query writing, and the interpretation of database outputs as datasets for further analysis.

## Assessment

The Master's Degree course is assessed through a written exam with open-ended questions.

## Reading Material

- Ian H. Witten, Eibe Frank, Mark A. Hall, Christopher J. Pal, James R. Foulds, *Data Mining: Practical Machine Learning Tools and Techniques*. Morgan Kaufmann, Fourth edition, 2016
- Giorgio M. Di Nunzio, Emanuele Di Buccio, *Basi di dati. Progettazione concettuale, logica e SQL*. Esculapio, First edition, 2017
