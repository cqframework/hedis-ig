---
layout: default
title: BCS
---

---

<!-- TOC  the css styling for this is \pages\assets\css\project.css under 'markdown-toc'-->

* Do not remove this line (it will not be displayed)
{:toc}

## Breast Cancer Screening (BCS)

### Measure Description

### Measurement Period

### Population Definitions

#### Initial Population

#### Exclusions

#### Denominator 

#### Numerator 

### Terminology

#### ValueSet Resources

* 

#### Direct Reference Codes

* 

**[Common Libraries](common-libraries.html)**

### Content

| Resource | Type | Description |
| --- | --- | ------ |
| [library-bcs-logic](Library-library-bcs-logic.html) | Library | FHIR Library defining the data requirements to support the evaluation of the BCS Meaure <br/> [CQL Source Code](bcs-cql.html) |
| [measure-bcs](Measure-measure-bcs.html) | Measure | FHIR Measure resource defining the structured, computable definition of the BCS Measure |
{: .list} 

### Example Data/Requests

| Description | Patient Data | Request | Expected Response |
| ------ | ---- | ------ | --- |
| lorem ipsum | | `.../Measure/measure-bcs/$evaluate-measure/...` | |
{: .list} 
