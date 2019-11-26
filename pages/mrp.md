---
layout: default
title: MRP
---

---

<!-- TOC  the css styling for this is \pages\assets\css\project.css under 'markdown-toc'-->

* Do not remove this line (it will not be displayed)
{:toc}

## Medication Reconciliation Post-Discharge (MRP)

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
| [library-mrp-logic](Library-library-mrp-logic.html) | Library | FHIR Library defining the data requirements to support the evaluation of the MRP Meaure <br/> [CQL Source Code](mrp-cql.html) |
| [measure-mrp](Measure-measure-mrp.html) | Measure | FHIR Measure resource defining the structured, computable definition of the MRP Measure |
{: .list} 

### Example Data/Requests

| Description | Patient Data | Request | Expected Response |
| ------ | ---- | ------ | --- |
| lorem ipsum |  | `.../Measure/measure-mrp/$evaluate-measure/...` |  |
{: .list} 
