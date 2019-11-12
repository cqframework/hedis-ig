---
layout: default
title: CCS
---

---

<!-- TOC  the css styling for this is \pages\assets\css\project.css under 'markdown-toc'-->

* Do not remove this line (it will not be displayed)
{:toc}

## Cervical Cancer Screening Screening (CCS) Measure

### Measure Description

The percentage of women 21–64 years of age who were screened for cervical cancer using either of the following criteria:
* Women 21–64 years of age who had cervical cytology performed every 3 years.
* Women 30–64 years of age who had cervical cytology/human papillomavirus (HPV) co-testing
performed every 5 years.

### Measurement Period

January 1 – December 31 of the measurement year.

### Population Definitions

#### Initial Population

Women 24-64 years as of December 31 of the measurement year.

#### Denominator

The initial population.

#### Numerator

The number of women who were screened for cervical cancer, as identified in steps 1 and 2 below.
* ****Step 1:**** Identify women 24–64 years of age as of December 31 of the measurement year who had cervical cytology (Cervical Cytology Value Set) during the measurement year or the two years prior to the measurement year.
* ****Step 2:**** From the women who did not meet step 1 criteria, identify women 30–64 years of age as of December 31 of the measurement year who had cervical cytology (Cervical Cytology Value Set) and a human papillomavirus (HPV) test (HPV Tests Value Set) with service dates four or less days apart during the measurement year or the four years prior to the measurement year and who were 30 years or older on the date of both tests. For example, if the service date for cervical cytology was December 1 of the measurement year, then the HPV test must include a service date on or between November 27 and December 5 of the measurement year.

### Terminology

#### ValueSet Resources

* "Absence of Cervix Value Set (2.16.840.1.113883.3.464.1004.1123.17)"
* "Cervical Cytology Value Set (2.16.840.1.113883.3.464.1004.1208)"
* "HPV Tests Value Set (2.16.840.1.113883.3.464.1004.1265)"
* "Female (2.16.840.1.113883.3.464.1004.1457)"
* "Male (2.16.840.1.113883.3.464.1004.1458)"

### Content

| Resource | Type | Description |
| -------- | ---- | ----------- |
| [library-ccs-logic](Library-library-ccs-logic.html) | Library | CQL Library defining the data requirements to support the evaluation of the CCS Meaure |
| [measure-ccs](Measure-measure-ccs.html) | Measure | FHIR Measure resource defining the structured, computable definition of the CCS Measure |
{: .list}

### Example Data/Requests

| Description | Bundle | Request | Expected Response |
| ----------- | ------ | ------- | ----------------- |
| lorem ipsum | []() | `.../Measure/measure-ccs/$evaluate-measure/...` | []() |
{: .list}
