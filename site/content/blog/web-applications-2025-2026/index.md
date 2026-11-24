---
title: Web Applications (2025/2026)
subtitle: Management Engineering · University of Udine
summary: HTTP, accessible interfaces and database access with Express and SQLite. The final project was ConversAI, a chat application with a simulated assistant.
date: '2026-09-28T10:00:00+02:00'
course_updated: '2026-11-24'
draft: false
url: /post/web-applications/2025-2026/
course_parent: /post/web-applications/
course_edition: '2025/2026'
course_hidden: true
authors: [admin]
---

## About this edition

I used a chat application to explain what happens when someone sends a message: the browser sends a request, the server checks and stores the message, and the page shows the result. Students studied each part of this exchange and brought them together in the final project.

- **Degree:** Master's Degree in Management Engineering, University of Udine
- **Course:** *Applicazioni Web* (IN1343)
- **Instructor:** Michael Soprano
- **Workload:** 6 CFU, 48 scheduled teaching hours
- **Teaching period:** 4 March to 28 May 2026

[Course in the Uniud Course Catalogue](https://uniud.coursecatalogue.cineca.it/corsi/2025/10952/insegnamenti/2025/19639/2025/1?coorte=2025&schemaid=13919)

## Programme

### Web architecture and HTTP

- **Browsers and servers.** Trace how a browser requests a resource. Read an HTTP exchange: the method states what the client wants to do, the headers describe the request or response, and the status code tells the client what happened.
- **Resource addresses.** Read the parts of a URL, resolve a relative link and encode query parameters. Use cURL and Postman to send requests, change their headers or body, and compare the responses.

### HTML and CSS

- **Page structure and content.** Use headings, lists and tables to give content a meaningful structure. Add links, responsive images and embedded media. Inspect the document tree that the browser builds from the markup.
- **Forms.** Associate labels with controls, choose input types and use the browser’s validation rules. Follow what happens to field names and values when a form is submitted.
- **Typography and layout.** Set type, colour and spacing, then use the box model to explain why an element takes up more space than its content. Use Flexbox to align items along one axis and Grid to arrange them in rows and columns. Adapt the layout to different screen widths.
- **The cascade.** When two rules affect the same element, inspect which declaration wins and why. Distinguish specificity and source order from properties inherited from a parent.

### JavaScript in the browser

- **Working with the page.** Use functions, arrays and objects to organise data. Select elements in the document object model (DOM) and update their text, attributes or classes without rebuilding the page.
- **Responding to users.** Handle clicks and form submissions, read the event data and keep the interface in step with the user’s actions. Show feedback when input is missing or invalid.

### Express and SQLite

- **Connecting the browser to a server.** Run an Express server in Node.js, define routes and return JSON. Use the Fetch API to send a request from the page and display the server’s reply.
- **Designing a REST API.** Choose URLs and HTTP methods for reading, creating and changing resources. Read route parameters and request bodies, validate input and return a useful status code when a request fails.
- **Keeping data between requests.** The final course example was a task API backed by SQLite. Its routes used SQL to read and change records so that tasks remained available after the server restarted.

### Guest seminar: Web accessibility

- **Accessibility principles.** The four principles of the Web Content Accessibility Guidelines (WCAG) explain what makes a page perceivable, operable, understandable and robust. Examples included showing product availability with text as well as colour and using headings that a screen reader can navigate.
- **Testing a page.** A demonstration compared two versions of an online shop using a keyboard and a screen reader. On the accessible version, users could tell which control had focus, hear what each form field was for and activate the purchase button without a mouse.

## Materials

Slides, recordings, sample code and exercises were shared in the course group on Microsoft Teams. The HTTP lab used cURL and Postman to inspect requests directly. In the Mozilla splash page exercise, students added links, responsive images and an embedded map. Both were practice activities, separate from the assessed project.

## Assessment

**Project: ConversAI (70%).** Students built a chat application that organised conversations into projects. When a user sent a message, the Express server stored it in SQLite, generated and saved a simulated reply, and returned the result. The browser updated the conversation without reloading the page. No external AI service was required.

Students worked individually or in groups of three. Groups had to implement at least two additional features: searching the history, marking conversations as favourites or archived, exporting a conversation, or managing reusable prompt templates.

**Oral discussion (30%).** Students demonstrated the application and explained their design choices, how the code worked and how it related to the course. Each group member had to explain their own contribution. A separate optional presentation on a paper, system or web technology could add up to three points.
