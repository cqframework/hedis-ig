---
layout: default
title: PVS
---

---

<!-- TOC  the css styling for this is \pages\assets\css\project.css under 'markdown-toc'-->

* Do not remove this line (it will not be displayed)
{:toc}

## Pneumococcal Vaccination Status of Older Adults (PVS)

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
| [library-pvs-logic](Library-library-pvs-logic.html) | Library | FHIR Library defining the data requirements to support the evaluation of the PVS Meaure <br/> [CQL Source Code](pvs-cql.html) |
| [measure-pvs](Measure-measure-pvs.html) | Measure | FHIR Measure resource defining the structured, computable definition of the PVS Measure |
{: .list} 

### Example Data/Requests

| Description | Patient Data | Request | Expected Response |
| ------ | ---- | ------ | --- |
| lorem ipsum |  | `.../Measure/measure-pvs/$evaluate-measure/...` |  |
{: .list} 
