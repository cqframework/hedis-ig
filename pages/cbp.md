---
layout: default
title: CBP
---

---

<!-- TOC  the css styling for this is \pages\assets\css\project.css under 'markdown-toc'-->

* Do not remove this line (it will not be displayed)
{:toc}

## Controlling High Blood Pressure (CBP)

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
| [library-cbp-logic](Library-library-wcc-aba-logic.html) | Library | FHIR Library defining the data requirements to support the evaluation of the CBP Meaure <br/> [CQL Source Code](cbp-cql.html) |
| [measure-cbp](Measure-measure-wcc-aba.html) | Measure | FHIR Measure resource defining the structured, computable definition of the CBP Measure |
{: .list} 

### Example Data/Requests

| Description | Patient Data | Request | Expected Response |
| ------ | ---- | ------ | --- |
| lorem ipsum |  | `.../Measure/measure-cbp/$evaluate-measure/...` |  |
{: .list} 
