library CBP version '1'

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0' called FHIRHelpers

/*

Description:
The percentage of members 18–85 years of age who had a diagnosis of hypertension (HTN)
  and whose BP was adequately controlled during the measurement year
  based on the following criteria:
    - Members 18–59 years of age whose BP was <140/90 mm Hg.
    - Members 60–85 years of age with a diagnosis of diabetes whose BP was <140/90 mm Hg.
    - Members 60–85 years of age without a diagnosis of diabetes whose BP was <150/90 mm Hg.
Note: Use the Hybrid Method for this measure. A single rate is reported and is the sum of all three groups.

*/

/*
// These are valuesets containing CPT codes indicating these concepts
valueset "Systolic Less Than 140": '2.16.840.1.113883.3.464.1004.1243'
valueset "Systolic Greater Than/Equal To 140": '2.16.840.1.113883.3.464.1004.1242'
valueset "Diastolic Less Than 80": '2.16.840.1.113883.3.464.1004.1084'
valueset "Diastolic 80-89": '2.16.840.1.113883.3.464.1004.1082'
valueset "Diastolic Greater Than/Equal To 90": '2.16.840.1.113883.3.464.1004.1083'
*/

codesystem "LOINC": 'http://loinc.org'

valueset "Acute Inpatient": '2.16.840.1.113883.3.464.1004.1017'
valueset "Diabetes": '2.16.840.1.113883.3.464.1004.1077'
valueset "Diabetes Exclusions": '2.16.840.1.113883.3.464.1004.1105'
valueset "Diabetes Medications List": 'TODO'
valueset "ED": '2.16.840.1.113883.3.464.1004.1086'
valueset "ESRD": '2.16.840.1.113883.3.464.1004.1089'
valueset "ESRD Obsolete": '2.16.840.1.113883.3.464.1004.1090'
valueset "Essential Hypertension": '2.16.840.1.113883.3.464.1004.1122'
valueset "Inpatient Stay": '2.16.840.1.113883.3.464.1004.1395'
valueset "Kidney Transplant": '2.16.840.1.113883.3.464.1004.1141'
valueset "Nonacute Inpatient": '2.16.840.1.113883.3.464.1004.1189'
valueset "Nonacute Inpatient Stay": '2.16.840.1.113883.3.464.1004.1398'
valueset "Observation": '2.16.840.1.113883.3.464.1004.1191'
valueset "Outpatient": '2.16.840.1.113883.3.464.1004.1202'
valueset "Outpatient Without UBREV": '2.16.840.1.113883.3.464.1004.1203'
valueset "Pregnancy": '2.16.840.1.113883.3.464.1004.1219'

code "Blood Pressure": Code '55284-4' from "LOINC" display 'Blood pressure'
code "Systolic Blood Pressure": Code '8480-6' from "LOINC" display 'Systolic blood pressure'
code "Diastolic Blood Pressure": Code '8462-4' from "LOINC" display 'Diastolic blood pressure'

parameter MeasurementPeriod Interval<DateTime>

context Patient

define "Lookback Interval One Year":
  Interval[start of MeasurementPeriod, end of MeasurementPeriod]

define "First 6 Months of MeasurementPeriod":
  Interval[start of MeasurementPeriod, start of MeasurementPeriod + 6 months]

define "Eligible Population":
  "In Demographic" and "Event Diagnosis"

// TODO: Members in hospice are excluded from the eligible population.
// If a member is found to be in hospice or using hospice services during medical record review,
// the member is removed from the sample and replaced by a member from the oversample.
// Refer to General Guideline 20: Members in Hospice.
// TODO: Product lines - Commercial, Medicaid, Medicare (report each product line separately).
// Ages	18–85 years as of December 31 of the measurement year.
// TODO: Continuous enrollment - The measurement year.
// TODO: Allowable gap	No more than one gap in continuous enrollment of up to 45 days during the measurement year.
//       To determine continuous enrollment for a Medicaid beneficiary for whom enrollment is verified monthly,
//       the member may not have more than a 1-month gap in coverage (i.e., a member whose coverage lapses for
//       2 months [60 days] is not considered continuously enrolled).
// TODO: Required exclusion	Exclude Medicare members age 65 and older as of January 1 of the measurement year who are:
// Enrolled in an Institutional SNP (I-SNP) any time during the measurement year.
// Living long-term in an institution any time during the measurement year.
// Organizations may use the LTI flag in the Medicare Part C monthly membership file.

define "In Demographic":
    AgeInYearsAt(DateTime(year from MeasurementPeriod, 12, 31)) in Interval[18, 85]

// Members are identified as hypertensive if there is at least one outpatient visit (Outpatient Without UBREV Value Set)
// with a diagnosis of hypertension (Essential Hypertension Value Set) during the first six months of the measurement year.
define "Outpatient Encounters":
  [Encounter: "Outpatient Without UBREV"] Encounters
    where Encounters.period."start" during day of "First 6 Months of MeasurementPeriod"

define "Hypertension Diagnosis":
  [Condition: "Essential Hypertension"] HTDiagnosis
    where HTDiagnosis.clinicalStatus = 'active'
      and HTDiagnosis.verificationStatus = 'confirmed'
      and HTDiagnosis.assertedDate

define "Event Diagnosis":
  AnyTrue( { "Event Diagnosis Context Match", "Event Diagnosis Date Match" } )

// one way - match context reference to Encounter id
define "Event Diagnosis Context Match":
  exists (
    "Outpatient Encounters" Encounters with "Hypertension Diagnosis" HTDiagnosis
      such that HTDiagnosis.context.reference = ReplaceMatches(Encounters.id, 'Encounter/', '')
  )

// another way - if they occur on the same day
define "Event Diagnosis Date Match":
  exists (
    "Outpatient Encounters" Encounters with "Hypertension Diagnosis" HTDiagnosis
      such that HTDiagnosis.assertedDate in day of Encounters.period
  )

// TODO: Required exclusion	Exclude Medicare members age 65 and older as of January 1 of the measurement year who are:
// Enrolled in an Institutional SNP (I-SNP) any time during the measurement year.
// Living long-term in an institution any time during the measurement year.
// Organizations may use the LTI flag in the Medicare Part C monthly membership file.
