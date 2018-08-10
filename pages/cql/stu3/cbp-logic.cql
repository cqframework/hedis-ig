library CBP version '2'

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

valueset "Diabetes Medications List": 'DiabetesMedicationsList' // NDC Codes

code "Blood Pressure": '55284-4' from "LOINC" display 'Blood pressure'
code "Systolic Blood Pressure": '8480-6' from "LOINC" display 'Systolic blood pressure'
code "Diastolic Blood Pressure": '8462-4' from "LOINC" display 'Diastolic blood pressure'

parameter "Measurement Period" default Interval[@2018-01-01, @2019-01-01)

context Patient

define "First 6 Months of Measurement Period":
  Interval[start of "Measurement Period", DateTime(year from start of "Measurement Period", 6, 30)]

define "Initial Population":
  "In Demographic" and "Event Diagnosis"

/*
    TODO: Members in hospice are excluded from the eligible population.
      If a member is found to be in hospice or using hospice services during medical record review,
      the member is removed from the sample and replaced by a member from the oversample.
      Refer to General Guideline 20: Members in Hospice.
*/

// TODO: Product lines - Commercial, Medicaid, Medicare (report each product line separately).
// TODO: Continuous enrollment - The measurement year.

/*
    TODO: Allowable gap	No more than one gap in continuous enrollment of up to 45 days during the measurement year.
      To determine continuous enrollment for a Medicaid beneficiary for whom enrollment is verified monthly,
      the member may not have more than a 1-month gap in coverage (i.e., a member whose coverage lapses for
      2 months [60 days] is not considered continuously enrolled).
*/

/*
    TODO: Required exclusion	Exclude Medicare members age 65 and older as of January 1 of the measurement year who are:
      Enrolled in an Institutional SNP (I-SNP) any time during the measurement year.
      Living long-term in an institution any time during the measurement year.
      Organizations may use the LTI flag in the Medicare Part C monthly membership file.
*/

// Ages	18–85 years as of December 31 of the measurement year.
define "In Demographic":
  AgeInYearsAt(DateTime(year from start of "Measurement Period", 12, 31)) in Interval[18, 85]

/*
    Members are identified as hypertensive if there is at least one outpatient visit (Outpatient Without UBREV Value Set)
    with a diagnosis of hypertension (Essential Hypertension Value Set) during the first six months of the measurement year.
*/
define "Outpatient Encounters Without UBREV":
  [Encounter: "Outpatient Without UBREV"] Encounters
    where Encounters.status = 'finished'
      and Encounters.period."start" in day of "First 6 Months of Measurement Period"

define "Hypertension Diagnosis":
  [Condition: "Essential Hypertension"] HTDiagnosis
    where HTDiagnosis.clinicalStatus = 'active'
      and HTDiagnosis.verificationStatus = 'confirmed'
      and HTDiagnosis.assertedDate in day of "First 6 Months of Measurement Period"
        sort by assertedDate desc

define "Event Diagnosis":
  AnyTrue( { "Event Diagnosis Context Match", "Event Diagnosis Date Match" } )

// one way - match context reference to Encounter id
define "Event Diagnosis Context Match":
  exists(
    "Outpatient Encounters Without UBREV" Encounters with "Hypertension Diagnosis" HTDiagnosis
      such that EndsWith(HTDiagnosis."context".reference, Encounters.id)
  )

// another way - if they occur on the same day
define "Event Diagnosis Date Match":
  exists(
    "Outpatient Encounters Without UBREV" Encounters with "Hypertension Diagnosis" HTDiagnosis
      such that HTDiagnosis.assertedDate in day of Encounters.period
  )

/*
    After the Eligible Population is identified, assign each member either a diabetic
    or not diabetic flag using only administrative data and the steps below. The flag
    is used to determine the appropriate BP threshold to use during numerator assessment
    (the threshold for members with diabetes is different than the threshold for members without diabetes).
*/

/*
    Step 1:
      Assign a flag of diabetic to members identified as diabetic using *** claim/encounter data *** or
      *** pharmacy data ***. The organization must use both methods to assign the diabetes flag, but a
      member only needs to be identified by one method. Members may be identified as having diabetes during
      the measurement year or the year prior to the measurement year.
*/

define "Lookback Period Year Prior to End of Measurement Period":
  Interval[
    start of "Measurement Period" - 1 year,
    end of "Measurement Period"
  ]

define "Step 1 Is Diabetic Flag":
  "Is Diabetic Using Claim and Encounter Data?"
    or "Is Diabetic Using Pharmacy Data"

/*
    Claim/encounter data. Members who met any of the following criteria during the measurement year
    or the year prior to the measurement year (count services that occur over both years):
      - At least two outpatient visits (Outpatient Value Set), observation visits (Observation Value Set),
        ED visits (ED Value Set) or nonacute inpatient encounters (Nonacute Inpatient Value Set) on different
        dates of service, with a diagnosis of diabetes (Diabetes Value Set). Visit type need not be the same
        for the two visits.
      - At least one acute inpatient encounter (Acute Inpatient Value Set) with a diagnosis of diabetes (Diabetes Value Set).
*/

/*
    TODO - determine best method to use for Claim data
      Current best guess:
      Claim during "Lookback Period Year Prior to End of Measurement Period" with Diabetes diagnosis (see "Get Concept from Claim Diagnosis" function)
        AND (
          At least two outpatient visits,
            observation visits,
            ED visits
            or nonacute inpatient encounters
              on different dates of service
          OR At least one acute inpatient encounter
        )
*/

define "Is Diabetic Using Claim and Encounter Data?":
  if exists("Diabetes Condition")
    then ("Count Encounters with Diabetes Diagnosis on Different Dates of Service" >= 2
      or "Count Acute Encounters with Diabetes Diagnosis" >= 1)
  else false

// TODO - Hmmm... need to verify that this method is valid
define "Diabetes Condition":
  [Condition: code in "Diabetes"] DiabetesCondition
    where DiabetesCondition.clinicalStatus = 'active'
      and DiabetesCondition.verificationStatus = 'confirmed'
      and exists(
        DiabetesCondition.category CategoryConcepts
          where exists(
            CategoryConcepts.coding ConceptCodes
              where ConceptCodes.code = 'encounter-diagnosis'
          )
      )
      and DiabetesCondition.assertedDate in day of "Lookback Period Year Prior to End of Measurement Period"

define "Count Encounters with Diabetes Diagnosis on Different Dates of Service":
  Count(
    "Encounters with Diabetes Diagnosis" DiabetesDiagnosisEncounters
      return distinct(DiabetesDiagnosisEncounters.period)
  )

define "Count Acute Encounters with Diabetes Diagnosis":
  Count(
    "Acute Encounters with Diabetes Diagnosis" DiabetesDiagnosisEncounters
  )

define "Encounters with Diabetes Diagnosis":
  (
    "Outpatient Encounters"
      union "Observation Encounters"
      union "ED Encounters"
      union "Nonacute Inpatient Encounters"
  ) Encounters
      with "Diabetes Condition" DiabetesCondition
        such that EndsWith(Encounters.diagnosis.condition.reference, DiabetesCondition.id)
          or EndsWith(DiabetesCondition."context".reference, Encounters.id)
      return Encounters

define "Acute Encounters with Diabetes Diagnosis":
  "Acute Inpatient Encounters" Encounters
    with "Diabetes Condition" DiabetesCondition
      such that EndsWith(Encounters.diagnosis.condition.reference, DiabetesCondition.id)
        or EndsWith(DiabetesCondition."context".reference, Encounters.id)
    return Encounters

define "Outpatient Encounters":
  [Encounter: type in "Outpatient"] OutpatientEncounters
    where OutpatientEncounters.status = 'finished'
      and OutpatientEncounters.period during day of "Lookback Period Year Prior to End of Measurement Period"
        sort by period."start" desc

define "Observation Encounters":
  [Encounter: type in "Observation"] ObservationEncounters
    where ObservationEncounters.status = 'finished'
      and ObservationEncounters.period during day of "Lookback Period Year Prior to End of Measurement Period"
        sort by period."start" desc

define "ED Encounters":
  [Encounter: type in "ED"] EDEncounters
    where EDEncounters.status = 'finished'
      and EDEncounters.period during day of "Lookback Period Year Prior to End of Measurement Period"
        sort by period."start" desc

define "Nonacute Inpatient Encounters":
  [Encounter: type in "Nonacute Inpatient"] NonacuteEncounters
    where NonacuteEncounters.status = 'finished'
      and NonacuteEncounters.period during day of "Lookback Period Year Prior to End of Measurement Period"
        sort by period."start" desc

define "Acute Inpatient Encounters":
  [Encounter: type in "Nonacute Inpatient"] AcuteEncounters
    where AcuteEncounters.status = 'finished'
      and AcuteEncounters.period during day of "Lookback Period Year Prior to End of Measurement Period"
        sort by period."start" desc

/*
    Pharmacy data. Members who were dispensed insulin or hypoglycemics/ antihyperglycemics
      on an ambulatory basis during the measurement year or the year prior to the
      measurement year (Diabetes Medications List).
*/

define "Is Diabetic Using Pharmacy Data":
  exists( "Members Dispensed Diabetes Medications During Step 1 Period" )

define "Members Dispensed Diabetes Medications During Step 1 Period":
  [MedicationDispense: medicationCodeableConcept in "Diabetes Medications List"] DiabetesMedicationDispense
    where DiabetesMedicationDispense.status = 'completed'
      and DiabetesMedicationDispense.whenHandedOver in day of "Lookback Period Year Prior to End of Measurement Period"


/*
    Step 2:
      From the members identified in step 1, assign a flag of not diabetic to members who
        do not have a diagnosis of diabetes (Diabetes Value Set), in any setting, during the
        measurement year or year prior to the measurement year and who had a diagnosis of
        gestational diabetes or steroid-induced diabetes (Diabetes Exclusions Value Set),
        in any setting, during the measurement year or the year prior to the measurement year.
      Note: Members classified as diabetic in step 1 based on pharmacy data alone and who had
        a diagnosis of gestational or steroid-induced diabetes as specified above are reclassified
        as not diabetic in this step.
*/

define "Step 2 Is Diabetic Flag":
  not (
    (
      not "Diabetes Diagnosis in Any Setting"
        or (
          "Is Diabetic Using Pharmacy Data"
            and not exists("Encounters with Diabetes Diagnosis")
        )
    )
    and exists("Has Diagnosis of Gestational or Steroid-Induced Diabetes")
  )

define "Diabetes Diagnosis in Any Setting":
  exists(
    [Encounter] Encounters
      with "Diabetes Condition" DiabetesCondition
        such that EndsWith(Encounters.diagnosis.condition.reference, DiabetesCondition.id)
          or EndsWith(DiabetesCondition."context".reference, Encounters.id)
      return Encounters
  )

define "Has Diagnosis of Gestational or Steroid-Induced Diabetes":
  [Condition: code in "Diabetes Exclusions"] InducedDiabetesCondition
    where InducedDiabetesCondition.clinicalStatus = 'active'
      and InducedDiabetesCondition.verificationStatus = 'confirmed'
      and InducedDiabetesCondition.assertedDate in day of "Lookback Period Year Prior to End of Measurement Period"

/*
    Step 3:
      Assign a flag of not diabetic to members who were not assigned a flag in step 1 or step 2.
*/

define "Step 3 Is Diabetic Flag":
  if ( "Step 1 Is Diabetic Flag" is null and "Step 2 Is Diabetic Flag" is null )
    then false
  else "Step 1 Is Diabetic Flag" or "Step 2 Is Diabetic Flag"

/*
    Denominator:
      To confirm the diagnosis of hypertension, the organization must find notation of one of
        the following in the medical record anytime during the member’s history on or before
        June 30 of the measurement year:
          - Hypertension
          - HTN
          - High BP (HBP)
          - Elevated BP (BP)
          - Borderline HTN
          - Intermittent HTN
          - History of HTN
          - Hypertensive vascular disease (HVD)
          - Hyperpiesia
          - Hyperpiesis
          - A diagnosis code for hypertension documented in the medical record
      It does not matter if hypertension was treated or is currently being treated.
        The notation indicating a diagnosis of hypertension may be recorded in any
        of the following documents:
          - Problem list (this may include a diagnosis prior to June 30 of the measurement year
              or an undated diagnosis that is not part of the office visit note; see the Note at
              the end of this section)
          - Office note
          - Subjective, Objective, Assessment, Plan (SOAP) note
          - Encounter form
          - Diagnostic report
          - Hospital discharge summary

      * If the diagnosis of hypertension cannot be confirmed, the member is excluded and replaced
        by the next member from the oversample.
*/

define "Denominator":
  true

/*
    Use one medical record for both the confirmation of the diagnosis of hypertension and the
      representative BP. All eligible BP measurements recorded in the record must be considered.
      NOTE - If an organization cannot find the medical record, the member remains in the measure
      denominator and is considered noncompliant for the numerator.
*/

/*
    Step 1:
      Identify the member’s PCP
        If the member had more than one PCP for the time period, identify the PCP who most recently
        provided care to the member
*/

define "Member's PCP":
  if ( Length("Patient General Practitioners") = 1 )
    then "Patient General Practitioners"[0].reference
  else "Get PCP Who Most Recently Provided Care".reference

define "Patient General Practitioners":
  Patient.generalPractitioner practitioners
    where practitioners.reference is not null

// NOTE - using Encounters to determine PCP who most recently provided care
define "Get PCP Who Most Recently Provided Care":
  (
    [Encounter] Encounters
      where Encounters.participant is not null
        and Encounters.status = 'finished'
        and Encounters.period during day of "Measurement Period"
          sort by period."start" desc
  ) MostRecentEncounters
      return First(
        MostRecentEncounters.participant participants
          where participants.individual is not null
            and participants.individual.reference is not null
            return participants.individual
      )

/*
    Step 2:
      Use one medical record to both confirm the diagnosis for the denominator and identify the
        representative BP level for the numerator.
      TODO - account for cirumstances when 2 records are needed to either confirm the diagnosis or obtain the BP reading
*/

// TODO

/*
    Numerator:
    The number of members in the denominator whose most recent BP (both systolic and diastolic) is adequately
      controlled during the measurement year based on the following criteria:
        - Members 18–59 years of age as of December 31 of the measurement year whose BP was <140/90 mm Hg.
        - Members 60–85 years of age as of December 31 of the measurement year who were flagged with a
          diagnosis of diabetes and whose BP was <140/90 mm Hg.
        - Members 60–85 years of age as of December 31 of the measurement year who were flagged as not having
          a diagnosis of diabetes and whose BP was <150/90 mm Hg.
      To determine if the member’s BP is adequately controlled, the representative BP must be identified.
*/

/*
    Step 1:
    Identify the most recent BP reading noted during the measurement year. The reading must occur after the
      date when the diagnosis of hypertension was confirmed.
    Do not include BP readings: TODO
      - Taken during an acute inpatient stay or an ED visit.
      - Taken on the same day as a diagnostic test or diagnostic or therapeutic procedure that requires a
        change in diet or change in medication on or one day before the day of the test or procedure, with
        the exception of fasting blood tests.
      - Reported by or taken by the member.
    If multiple readings were recorded for a single date, use the lowest systolic and lowest diastolic BP
      on that date as the representative BP. The systolic and diastolic results do not need to be from
      the same reading. TODO
*/

define "Most Recent BP Readings":
  [Observation: "Blood Pressure"] BPObservation
    where BPObservation.effective in day of "Measurement Period"
      and (BPObservation.effective as dateTime) after day of First("Hypertension Diagnosis").assertedDate
        sort by effective desc

/*
    Step 2:
      Determine numerator compliance using the criteria in the Numerator secition above.
      The member is not compliant if the BP reading does not meet the specified threshold or is missing,
        if there is no BP reading during the measurement year or if the reading is incomplete
        (e.g., the systolic or diastolic level is missing).
*/

/*
    NOTE
    I can imagine a couple of different ways an Observation could represent blood pressure values:
      - Observation with a valueRatio (Systolic/Diastolic)
      - Observation with component values for Systolic and Diastolic
*/



/*

    Helper functions

*/

define function "Get Concept from Claim Diagnosis"(value Choice<FHIR.CodeableConcept, FHIR.Reference>):
  if value is FHIR.CodeableConcept
    then value
  else (
    "Diabetes Condition" DC
      where EndsWith(value.reference, DC.id)
      return DC.code
  )
