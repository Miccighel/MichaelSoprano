---
title: Web Applications (2024/2025)
subtitle: Management Engineering · University of Udine
summary: How browsers and servers exchange data. Students built a web application to manage a collection of their choice using JavaScript and Express.
date: '2026-09-28T10:00:00+02:00'
course_updated: '2026-11-24'
draft: false
url: /post/web-applications/2024-2025/
course_parent: /post/web-applications/
course_edition: '2024/2025'
course_hidden: true
authors: [admin]
---

## About this edition

I used two familiar examples, adding a book to a catalogue and editing a workout in a training log, to explain what happens when someone submits a form. Students followed the HTTP request from the browser to the server, then chose a collection of their own for the final project.

- **Degree:** Master's Degree in Management Engineering, University of Udine
- **Course:** *Applicazioni Web*
- **Instructor:** Michael Soprano
- **Workload:** 48 teaching hours

[Course in the Uniud Course Catalogue](https://uniud.coursecatalogue.cineca.it/corsi/2024/10101/insegnamenti/2024/19639/2020/1?coorte=2024&schemaid=13031)

## Programme

### Web architecture and HTTP

- **Requests and responses.** Trace an exchange between a browser and a server. Read the method, headers, body and status code, and explain what it means for HTTP requests to be independent of one another.
- **Addresses and APIs.** Identify the path and query string in a URL and encode parameter values. Use cURL and Postman to change a request, send JSON and inspect the response.

### HTML and CSS

- **Document structure.** Mark up an article with headings, paragraphs, lists and links. Use tables for tabular data, add alternative text to images and distinguish content that belongs in the page from media embedded from another site.
- **Forms.** Choose controls for different kinds of input, associate them with labels and group related fields. Apply the browser’s validation rules before submitting the form.
- **Styles and layout.** Use selectors, inheritance and the cascade to explain which styles apply to an element. Set type and colour, use the box model to control spacing, and arrange content with Flexbox so the layout adapts to the available width.

### JavaScript in the browser

- **Requests and page updates.** Use promises and `async/await` to handle data that arrives after the page has loaded. Fetch JSON from an API and update the document object model (DOM), inserting plain text with `textContent`.
- **User interaction.** Handle clicks and form submissions. Follow an event as it travels through the document and use a listener on a parent element to handle actions on its children.

### Express and SQLite

- **Routes and middleware.** Serve static files with Express and define routes for individual resources and collections. Read request data, use middleware shared by several routes, and return JSON with an appropriate HTTP status code.
- **Persistent data.** Compare a collection held in memory with one stored in SQLite. In the course example, a GET route queried the database and returned the stored items as JSON.

### Guest seminar: Real world software development

The seminar examined how to estimate work when a client’s requirements are incomplete, and how a change in scope affects costs and the code already written. A practical demonstration introduced Flutter and Dart for building applications that run on more than one platform.

## Materials

Slides, recordings, sample code and exercises were shared in the course group on Microsoft Teams. The HTTP lab used cURL and Postman. In the Mozilla splash page exercise, students added linked images and embedded a video in an HTML page. These were practice activities, separate from the final project.

## Assessment

**Project: a collection of your choice (70%).** Students built an application for creating, listing, viewing, editing and deleting records. The browser used the Fetch API to send changes to an Express server and updated the page without reloading it. Both the browser and the server checked the input. Storage could be in memory, in a JSON file or in SQLite.

Students worked individually or in groups of three and wrote a short report explaining their design. Groups had two additional requirements: a simulated login so that only owners could change or delete their records, and a text search with results split into pages.

**Oral discussion (30%).** Students explained their implementation, justified their design choices and answered questions about the course. Each member of a group discussed their own contribution. An optional presentation on a paper, system or web technology could add up to three points.
