---
layout: default
title: Home
---

---

<!-- TOC  the css styling for this is \pages\assets\css\project.css under 'markdown-toc'-->

* Do not remove this line (it will not be displayed)
{:toc}

## 1 HEDIS® Implementation Guide
{: #hedis-implementation-guide}

NCQA's Healthcare Effectiveness Data and Information Set (HEDIS) is a tool used by more than 90 percent of America's 
health plans to measure performance on important dimensions of care and service. Altogether, HEDIS consists of 81 
measures across 5 domains of care. Because so many plans collect HEDIS data, and because the measures are so 
specifically defined, HEDIS makes it possible to compare the performance of health plans on an "apples-to-apples" basis.

Modern value-based care involves calculating payer-relation quality measures. This calculation relies on access to 
patient information, which is (for this guide) represented using 
[Fast Healthcare Interoperability Resources]({{site.data.fhir.path}}) (FHIR). FHIR's secure, RESTful, standards-based 
services for accessing patient information streamlines this process. By combining FHIR with shareable knowledge 
artifacts, we significantly reduce the amount of engineering effort required to implement and maintain useful HEDIS 
quality measure calculations for payers. Healthcare providers also experience reduced effort, as responding to quality 
reporting requests is greatly simplified with this approach.

### 1.1 Overview
{: #overview}

The [Clinical Reasoning module]({{site.data.fhir.path}}clinicalreasoning-module.html) of the FHIR specification defines 
resources and operations to support decision support and quality measurement. In particular, FHIR's 
[Quality Reporting]({{site.data.fhir.path}}cqif/cqif-quality-reporting.html) section describes 
[Measure]({{site.data.fhir.path}}measure.html) and [MeasureReport]({{site.data.fhir.path}}measurereport.html) resources, 
which define quality measures and reporting measurement results, including the patient information involved in 
performing the calculations.

### 1.2 How To Read This Guide
{: #how-to-read-this-guide}

This guide is divided into several pages which are listed at the top of each page in the menu bar:

-  **[Home](index.html)**: The home page provides an overview and list of HEDIS measures covered in this guide
-  **[Libraries](libraries.html)**: The libraries page provides a list of FHIR Library resources that contain the 
metadata and CQL logic for the HEDIS measures covered in this guide 
-  **[Measures](measures.html)**: The measures page provides a list of FHIR Measure resources that contain the 
metadata and provide the structured computable definitions for the HEDIS measures covered in this guide 
-  **[Profiles](profiles.html)**: The profiles page provides a list of FHIR profiles that define the data requirements,
constraints and extensions used in the HEDIS measures covered in this guide
-  **[Terminologies](terminologies.html)**: The terminologies page provides a list of FHIR ValueSet resources that 
define the coded, structured data used by the FHIR profiles defined in this guide
-  **[Documentation](documentation.html)**: The documentation page provides guidance (from a technical perspective) for 
the implementation and evaluation of the artifacts outlined in this guide
-  **[Downloads](downloads.html)**: This page provides links to downloadable artifacts for implementations

### 1.3 Measures
{: #measures}

This guide provides FHIR-based specifications for the following HEDIS payer measures:

| Measure | Description |
|:---|:-----------------|
| [ABA](aba.html) | Adult BMI Assessment |
| [ASF](asf.html) | Unhealthy Alcohol Use Screening and Follow-up |
| [BCS](bcs.html) | Breast Cancer Screening |
| [CBP](cbp.html) | Controlling High Blood Pressure |
| [CCS](ccs.html) | Cervical Cancer Screening |
| [CDC](cdc.html) | Comprehensive Diabetes Care |
| [COL](col.html) | Colorectal Cancer Screening |
| [DMS](dms.html) | Utilization of the PHQ-9 to Monitor Depression Symptoms for Adolescents and Adults |
| [DRR](drr.html) | Depression Remission or Response for Adolescents and Adults |
| [DSF](dsf.html) | Depression Screening and Follow-Up for Adolescents and Adults |
| [MRP](mrp.html) | Medication Reconciliation Post Discharge |
| [PVS](pvs.html) | Pneumococcal Vaccination Status of Older Adults |
{: .list}

### 1.4 NCQA Copyright Notice and Disclaimer
{: #ncqa-copyright-notice-and-disclaimer}

The HEDIS measure specifications were developed by and are owned by NCQA. The HEDIS measure specifications are not 
clinical guidelines and do not establish a standard of medical care. NCQA makes no representations, warranties, or 
endorsement about the quality of any organization or physician that uses or reports performance measures and NCQA has no 
liability to anyone who relies on such measure specifications. These materials may not be modified by anyone other than 
NCQA. Anyone desiring to use or reproduce the materials without modification for a non-commercial purpose may do so 
without obtaining any approval from NCQA. **Any commercial use (including but not limited to vendors using the measure 
specifications with a product or service, including calculation of measure results) must be approved by NCQA and are 
subject to a license at the discretion of NCQA.**  &copy; 2019 NCQA, all rights reserved.

Limited proprietary coding is contained in the measure specifications for convenience. NCQA disclaims all liability for 
use or accuracy of any third-party code values contained in the specifications.

The American Medical Association holds a copyright to the CPT&reg; codes contained in the measure specifications.

The American Hospital Association holds a copyright to the Uniform Billing Codes (<q>UB</q>) contained in the measure 
specifications. The UB Codes in the HEDIS specifications are included with the permission of the AHA. The UB Codes 
contained in the HEDIS specifications may be used by health plans and other health care delivery organizations for the 
purpose of calculating and reporting HEDIS measure results or using HEDIS measure results for their internal quality 
improvement purposes. All other uses of the UB Codes require a license from the AHA. Anyone desiring to use the UB Codes 
in a commercial product to generate HEDIS results, or for any other commercial use, must obtain a commercial use license 
directly from the AHA. To inquire about licensing, contact ub04@aha.org.

