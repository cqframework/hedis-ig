---
layout: default
title: COL
---

---

<!-- TOC  the css styling for this is \pages\assets\css\project.css under 'markdown-toc'-->

* Do not remove this line (it will not be displayed)
{:toc}

## Colorectal Cancer Screening (COL) Measure

### Measure Description

The percentage of members 50–75 years of age who had appropriate screening for colorectal cancer.

### Measurement Period

January 1 – December 31 of the measurement year.

### Population Definitions

#### Initial Population

Members that are 51–75 years as of December 31 of the measurement year.

#### Exclusions

Exclude members with any of the following:
*  Alcohol use disorder from January 1 the year prior to the measurement year to December 31 of the measurement year.
*  History of dementia any time during the member’s history through the end of the measurement period.
*  In hospice or using hospice services during the measurement period.

Exclude members who meet any of the following criteria:
* Medicare members 66 years of age and older as of December 31 of the measurement year who meet either of the following:
  * Enrolled in an Institutional SNP (I-SNP) any time during the measurement year.
  * Living long-term in an institution any time during the measurement year as identified by the LTI flag in the Monthly Membership Detail Data File. Use the run date of the file to determine if a member had an LTI flag during the measurement year
* Members 66 years of age and older as of December 31 of the measurement year (all product lines) with frailty (Frailty Value Set) and advanced illness during the measurement year. To identify members with advanced illness, any of the following during the measurement year or the year prior to the measurement year (count services that occur over both years), meet criteria:
  * At least two outpatient visits (Outpatient Value Set), observation visits (Observation Value Set), ED visits (ED Value Set) or nonacute inpatient encounters (Nonacute Inpatient Value Set) on different dates of service, with an advanced illness diagnosis (Advanced Illness Value Set). Visit type need not be the same for the two visits.
  * At least one acute inpatient encounter (Acute Inpatient Value Set) with an advanced illness diagnosis (Advanced Illness Value Set).
  * A dispensed dementia medication (Dementia Medications List).

#### Denominator

The eligible population.

#### Numerator (Screening for Colorectal Cancer)
One or more screenings for colorectal cancer. Any of the following meet criteria:
* Fecal occult blood test (FOBT Value Set) during the measurement year. For administrative data, assume the required number of samples were returned, regardless of FOBT type.
* Flexible sigmoidoscopy (Flexible Sigmoidoscopy Value Set) during the measurement year or the four years prior to the measurement year.
* Colonoscopy (Colonoscopy Value Set) during the measurement year or the nine years prior to the measurement year.
* CT colonography (CT Colonography Value Set) during the measurement year or the four years prior to the measurement year.
* FIT-DNA test (FIT-DNA Value Set) during the measurement year or the two years prior to the measurement year.

### Terminology

#### ValueSet Resources

* "Colonoscopy Value Set (2.16.840.1.113883.3.464.1004.1064)"
* "Colorectal Cancer Value Set (2.16.840.1.113883.3.464.1004.1065)"
* "CT Colonography Value Set (2.16.840.1.113883.3.464.1004.1421)"
* "FIT-DNA Value Set (2.16.840.1.113883.3.464.1004.1420)"
* "Flexible Sigmoidoscopy Value Set (2.16.840.1.113883.3.464.1004.1102)"
* "FOBT Value Set (2.16.840.1.113883.3.464.1004.1093)"
* "Total Colectomy Value Set (2.16.840.1.113883.3.464.1004.1250)"

### Content

| Resource | Type | Description |
| -------- | ---- | ----------- |
| [library-col-logic](Library-library-col-logic.html) | Library | CQL Library defining the data requirements to support the evaluation of the COL Meaure |
| [measure-col](Measure-measure-col.html) | Measure | FHIR Measure resource defining the structured, computable definition of the COL Measure |
{: .list}

### Example Data/Requests

| Description | Bundle | Request | Expected Response |
| ----------- | ------ | ------- | ----------------- |
| lorem ipsum | []() | `.../Measure/measure-col/$evaluate-measure/...` | []() |
{: .list}
