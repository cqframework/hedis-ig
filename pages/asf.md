---
layout: default
title: ASF
---

---

<!-- TOC  the css styling for this is \pages\assets\css\project.css under 'markdown-toc'-->

* Do not remove this line (it will not be displayed)
{:toc}

## Unhealthy Alcohol Use Screening and Follow-up (ASF) Measure

### Measure Description

The percentage of members 18 years of age and older who were screened for unhealthy alcohol use using a standardized instrument and, if screened positive, received appropriate follow-up care.

### Measurement Period

January 1 – December 31 of the measurement year.

### Population Definitions

#### Initial Population

Members that are 18 years and older at the start of the measurement period.

#### Exclusions

Exclude members with any of the following:
*  Alcohol use disorder from January 1 the year prior to the measurement year to December 31 of the measurement year.
*  History of dementia any time during the member’s history through the end of the measurement period.
*  In hospice or using hospice services during the measurement period.

#### Denominator 1 (Unhealthy Alcohol Use Screening)

The initial population, minus exclusions.

#### Numerator 1 (Unhealthy Alcohol Use Screening)

Members with a documented result for unhealthy alcohol use screening
performed between January 1 and November 1 of the measurement period.

#### Denominator 2 (Counseling or Other Follow-Up on Positive Screen)

All members in Numerator 1 with a positive finding for unhealthy alcohol use screening between January 1 and November 1 of the measurement period.

#### Numerator 2 (Counseling or Other Follow-Up on Positive Screen)

Members receiving __Alcohol Counseling or Other Follow Up Care__ on or 60 days after the date of the first positive screen (61 days total).

### Terminology

#### ValueSet Resources

* "Alcohol Use Disorder (2.16.840.1.113883.3.464.1004.1339)"
* "Dementia (2.16.840.1.113883.3.464.1004.1074)"
* "Alcohol Counseling or Other Follow up Care (2.16.840.1.113883.3.464.1004.1437)"
* "Hospice (2.16.840.1.113883.3.464.1004.1418)"
* "Female (2.16.840.1.113883.3.464.1004.1457)"
* "Male (2.16.840.1.113883.3.464.1004.1458)"

#### Direct Reference Codes

* "How often have you had five or more drinks in one day during the past year [Reported] (LOINC Code 88037-7)"
* "How often have you had four or more drinks in one day during the past year [Reported] (LOINC Code 75889-6)"
* "Total score \[AUDIT-C] (LOINC Code 75626-2)"
* "Total score \[AUDIT] (LOINC Code 75624-7)"

### Content

| Resource | Type | Description |
| -------- | ---- | ----------- |
| [library-asf-logic](Library-library-asf-logic.html) | Library | CQL Library defining the data requirements to support the evaluation of the ASF Meaure |
| [measure-asf](Measure-measure-asf.html) | Measure | FHIR Measure resource defining the structured, computable definition of the ASF Measure |
{: .list} 

### Example Data/Requests

| Description | Bundle | Request | Expected Response |
| ----------- | ------ | ------- | ----------------- |
| Patient is 18 years or older with a documented result for unhealthy alcohol use screening (Observation.code in "Total score \[AUDIT]" | [In Numerator 1](Bundle-asf-in.html) | `.../Measure/measure-asf/$evaluate-measure?patient=asf-in`<br/>`&reportType=patient&periodStart=2019-01-01&periodEnd=2019-12-31` | [ASF in Numerator 1 MeasureReport](MeasureReport-asf-in.html) |
| Patient is 18 years or older without a documented result for unhealthy alcohol use screening | [Out Numerator 1](Bundle-asf-out.html) | `.../Measure/measure-asf/$evaluate-measure?patient=asf-out`<br/>`&reportType=patient&periodStart=2019-01-01&periodEnd=2019-12-31` | [ASF out Numerator 1 MeasureReport](MeasureReport-asf-out.html) |
| Patient is 18 years or older with a documented result for unhealthy alcohol use screening (Observation.code in "Total score \[AUDIT]" and received counseling within 60 days (Observation.code in "Alcohol Counseling or Other Follow Up Care") | [In Numerator 2](Bundle-asf-in-2.html) | `.../Measure/measure-asf/$evaluate-measure?patient=asf-in-2`<br/>`&reportType=patient&periodStart=2019-01-01&periodEnd=2019-12-31` | [ASF in Numerator 2 MeasureReport](MeasureReport-asf-in-2.html) |
| Patient is 18 years or older without a documented result for unhealthy alcohol use screening | [Out Numerator 2](Bundle-asf-out-2.html) | `.../Measure/measure-asf/$evaluate-measure?patient=asf-out-2`<br/>`&reportType=patient&periodStart=2019-01-01&periodEnd=2019-12-31` | [ASF in Numerator 2 MeasureReport](MeasureReport-asf-out-2.html) |
{: .list} 
