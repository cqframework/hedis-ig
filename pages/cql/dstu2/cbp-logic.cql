library CBP version '1'


using FHIR version '1.8'


include FHIRHelpers version '1.8' called FHIRHelpers


/*
Blood Pressure		value providing blood pressure
"Systolic  Less Than 140"
"Systolic Greater Than/Equal To 140"
"Diastolic Less Than 80"
"Diastolic 80-89"
"Diastolic Greater Than/Equal To 90"
CPT
1 year

Hx HTN	Earliest date practice was aware of hypertension
"Essential Hypertension"
ICD10CM
3 years

*/


/*
// These are valuesets containing CPT codes indicating these concepts
valueset "Systolic Less Than 140": '2.16.840.1.113883.3.464.1004.1243'
valueset "Systolic Greater Than/Equal To 140": '2.16.840.1.113883.3.464.1004.1242'
valueset "Diastolic Less Than 80": '2.16.840.1.113883.3.464.1004.1084'
valueset "Diastolic 80-89": '2.16.840.1.113883.3.464.1004.1082'
valueset "Diastolic Greater Than/Equal To 90": '2.16.840.1.113883.3.464.1004.1083'
*/


// Using the DAF profiles, we could also communicate the requirement with value-based filtering
//valueset "Blood Pressure": 'Blood Pressure' // TODO: LOINC 55284-4
valueset "Systolic Blood Pressure": '2.16.840.1.113883.3.526.3.1032' //'Systolic Blood Pressure' // TODO: LOINC 8480-6
valueset "Diastolic Blood Pressure": '2.16.840.1.113883.3.526.3.1033' //'Diastolic Blood Pressure' // TODO: LOINC 8462-4
valueset "Essential Hypertension": '2.16.840.1.113883.3.464.1003.104.12.1011'
valueset "Outpatient Without UBREV": '2.16.840.1.113883.3.464.1004.1203'
valueset "End Stage Renal Disease": '2.16.840.1.113883.3.526.3.353'
valueset "Kidney Transplant": '2.16.840.1.113883.3.464.1003.109.12.1012'
valueset "Inpatient Stay": '2.16.840.1.113883.3.464.1004.1395'
valueset "Insulin or Hypo-/Antihyper-glycemics": 'Insulin or Hypo-/Antihyper-glycemics'
valueset "Pregnancy": '2.16.840.1.113883.3.600.1622'
valueset "Gestational or Steroid-induced Diabetes": 'Gestational or Steroid-induced Diabetes'


parameter MeasurementPeriod Interval<DateTime>


context Patient


define "Lookback Interval One Year":
  Interval[start of MeasurementPeriod, end of MeasurementPeriod]

//probably  not needed
define "Lookback Interval Three Years":
  Interval[start of MeasurementPeriod - 3 years, end of MeasurementPeriod]


// TODO: Need to verify the demographic here
define "In Demographic":
    AgeInYearsAt(end of MeasurementPeriod) >= 18 and
    AgeInYearsAt(end of MeasurementPeriod) <= 85


// Blood Pressure


/*
// Using NCQA CPT Code Groupings
define "BP: Systolic Less Than 140":
    [Observation: "Systolic Less Than 140"] O
        where O.status.value in { 'final', 'amended' }
            and O.effectiveDateTime.value during day of "Lookback Interval One Year"

define "BP: Systolic Greater Than/Equal To 140":
    [Observation: "Systolic Greater Than/Equal To 140"] O
        where O.status.value in { 'final', 'amended' }
            and O.effectiveDateTime.value during day of "Lookback Interval One Year"

define "BP: Diastolic Greater Less Than 80":
    [Observation: "Diastolic Less Than 80"] O
        where O.status.value in { 'final', 'amended' }
            and O.effectiveDateTime.value during day of "Lookback Interval One Year"

define "BP: Diastolic 80-89":
    [Observation: "Diastolic 80-89"] O
        where O.status.value in { 'final', 'amended' }
            and O.effectiveDateTime.value during day of "Lookback Interval One Year"

define "BP: Diastolic Greater Than/Equal To 90":
    [Observation: "Diastolic Greater Than/Equal To 90"] O
        where O.status.value in { 'final', 'amended' }
            and O.effectiveDateTime.value during day of "Lookback Interval One Year"

*/


define "BP: Systolic":
  [Observation: "Systolic Blood Pressure"] O
    where O.status.value in { 'final', 'amended' }
      //and O.effectiveDateTime.value during day of "Lookback Interval One Year"
      // w/ FHIRHelpers
      //and O.effectiveDateTime during day of "Lookback Interval One Year"
      // w/ FHIR Choice Types
      and O.effective during "Lookback Interval One Year"


define "BP: Diastolic":
  [Observation: "Diastolic Blood Pressure"] O
    where O.status.value in { 'final', 'amended' }
      and O.effective during day of "Lookback Interval One Year"


// Using DAF Profiles (LOINC Code)
/*define "Blood Pressure Observations":
  [Observation: "Blood Pressure"] O
    where O.status.value in { 'final', 'amended' }
      and O.effective during day of "Lookback Interval One Year"

define "BP: Systolic":
  "Blood Pressure Observations" O
    return singleton from (O.component C where C.code in "Systolic Blood Pressure")

define "BP: Diastolic":
  "Blood Pressure Observations" O
    return singleton from (O.component C where C.code in "Diastolic Blood Pressure")*/


define "BP: Systolic Less Than 140":
    "BP: Systolic" S
        // So, this is ugly...
        //where S.value.value.value < 140
        // Not sure this is better
        where (S.value as Quantity).value.value < 140


define "BP: Systolic Greater Than/Equal To 140":
    "BP: Systolic" S
        where (S.value as Quantity).value.value >= 140


define "BP: Diastolic Less Than 80":
    "BP: Diastolic" D
        where (D.value as Quantity).value.value < 80


define "BP: Diastolic 80-89":
    "BP: Diastolic" D
        where (D.value as Quantity).value.value between 80 and 89


define "BP: Diastolic Greater Than/Equal To 90":
    "BP: Diastolic" D
        where (D.value as Quantity).value.value >= 90


// Exclude Patients with a Diagnosis of Essential Hypertension
// Hx HTN
define "Hypertension Diagnosis":
  [Condition: "Essential Hypertension"] H
    where H.clinicalStatus = 'active'
        and H.verificationStatus = 'confirmed'
        and H.onset during day of "Lookback Interval Three Years"


// Date of first diagnosis of Hypertension
define "Hx HTN":
  First("Hypertension Diagnosis" D sort by (onset as dateTime)).assertedDate


// Outpatient Encounters with a diagnosis of Essential Hypertension during the first 6 months of the measurement period
/*define "Outpatient Encounter":
  [Encounter: "Outpatient Without UBREV"] E
    where E.period."start" during day of Interval[start of MeasurementPeriod, start of MeasurementPeriod + 6 months]*/


// End-Stage Renal Disease (ESRD)
// Kidney Transplant


define "End Stage Renal Disease Diagnosis":
  [Condition: "End Stage Renal Disease"] C
    where C.clinicalStatus = 'active'
      and C.verificationStatus = 'confirmed'
      and C.onset same day or before end of MeasurementPeriod


define "Kidney Transplant Procedure":
  [Procedure: "Kidney Transplant"] P
    where P.status = 'completed'
      and P.performed same day or before end of MeasurementPeriod


// Pregnancy


define "Pregnancy Condition":
  [Condition: "Pregnancy"] P
    where P.verificationStatus = 'confirmed'
      and Interval[P.onset as dateTime, P.abatement as dateTime] overlaps day of MeasurementPeriod


// Non-Acute Inpatient Admission


/*define "Non-Acute Inpatient Admission":
  [Encounter: "Inpatient Stay"] E
    where E.status = 'finished'
      and E.period."end" during day of MeasurementPeriod*/


// Identify Diabetic patients


/*define "Outpatient Encounter":
  [Encounter: "Outpatient"] E
    where E.status = 'finished'
      and E.period."start" during day of "Lookback Interval One Year"*/


/*define "Non-Acute Inpatient Admission":
  [Encounter: "Nonacute Inpatient"] E
    where E.status = 'finished'
      and E.period."start" during day of "Lookback Interval One Year"*/


define "MedicationDispense":
  [MedicationDispense: "Insulin or Hypo-/Antihyper-glycemics"] M
    where M.status = 'completed'
      and M.whenHandedOver during day of "Lookback Interval One Year"


define "Any Setting Encounter":
  [Encounter] E
    where E.status = 'finished'
      and E.period."start" during day of "Lookback Interval One Year"


define "Gestational or Steroid-induced Diabetes Condition":
  [Condition: "Gestational or Steroid-induced Diabetes"] C
    where C.clinicalStatus = 'active'
      and C.verificationStatus = 'confirmed'
      and C.onset during day of "Lookback Interval One Year"


// TODO: Determine the member's Primary Care Provider
// This mechanism is used to limit the blood pressure observations to a single provider

// TODO: Exclude readings taken during acute inpatient stay, self-reported readings,
// and readings taken as part of a visit for a major diagnostic or surgical Procedure
