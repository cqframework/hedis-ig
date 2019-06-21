/*
Cervical Cancer Screening (CCS)
*/

library CCS_FHIR version '1.0.1'

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0'
include NCQACommon_FHIR version '3.10.000' called Common
include Participation_FHIR version '1.0.0'

/*
Description
The percentage of women 21-64 years of age who were screened for cervical
    cancer using either of the following criteria:
  * Women 21-64 years of age who had cervical cytology performed every 3 years.
  * Women 30-64 years of age who had cervical cytology/human papillomavirus
    (HPV) co-testing performed every 5 years.
*/

valueset "Absence of Cervix Value Set": '2.16.840.1.113883.3.464.1004.1123.17' // CPT
// valueset "Absence of Cervix Value Set": '2.16.840.1.113883.3.464.1004.1123.18' // ICD10CM
// valueset "Absence of Cervix Value Set": '2.16.840.1.113883.3.464.1004.1123.19' // ICD10PCS
// valueset "Absence of Cervix Value Set": '2.16.840.1.113883.3.464.1004.1123.20' // ICD9CM
// valueset "Absence of Cervix Value Set": '2.16.840.1.113883.3.464.1004.1123.21' // ICD9CMProc

valueset "Cervical Cytology Value Set": '2.16.840.1.113883.3.464.1004.1208' // Grouping
// valueset "Cervical Cytology Value Set": '2.16.840.1.113883.3.464.1004.1208.22' // CPT
// valueset "Cervical Cytology Value Set": '2.16.840.1.113883.3.464.1004.1208.23' // HCPCS
// valueset "Cervical Cytology Value Set": '2.16.840.1.113883.3.464.1004.1208.24' // LOINC
// valueset "Cervical Cytology Value Set": '2.16.840.1.113883.3.464.1004.1208.25' // RevCode

valueset "HPV Tests Value Set": '2.16.840.1.113883.3.464.1004.1265' // Grouping
//valueset "HPV Tests Value Set": '2.16.840.1.113883.3.464.1004.1265.26' // CPT
// valueset "HPV Tests Value Set": '2.16.840.1.113883.3.464.1004.1265.27' // HCPCS
// valueset "HPV Tests Value Set": '2.16.840.1.113883.3.464.1004.1265.28' // LOINC

/*
This library has an explicit parameter which is the product line.
Recognized normal arguments are {'commercial', 'medicaid', 'medicare'}.
If one of these normal arguments is given, the patient will only be
considered to be in the Initial Population if they have an appropriate
continuous enrollment in that kind of medical plan.
If instead a null argument is given, their enrollment status will have no
effect on whether they are considered to be in the Initial Population.
If instead some other argument is given (an unrecognized plan type),
the patient will unconditionally NOT be in the Initial Population.
*/

parameter "Product Line" String

/*
This library has an explicit parameter which is the measurement year.
While the actual parameter's type accepts all intervals, this library
expects it will only be given arguments corresponding exactly to one whole
calendar year, and it will not behave properly otherwise; 2017 for example:
Interval[DateTime(2017,1,1,0,0,0,0), DateTime(2018,1,1,0,0,0,0))
*/

parameter "Measurement Period" Interval<DateTime>

define "First Predecessor Year":
  Interval[start of "Measurement Period" - 1 year, end of "Measurement Period" - 1 year)

define "Second Predecessor Year":
  Interval[start of "Measurement Period" - 2 years, end of "Measurement Period" - 2 year)

define "Third Predecessor Quarter":
  Interval[start of "Measurement Period" - 2 years - 3 months, end of "Measurement Period" - 3 years)

define "Lookback Interval Two More Years":
  Interval[start of "Measurement Period" - 2 years, end of "Measurement Period")

define "Lookback Interval Four More Years":
  Interval[start of "Measurement Period" - 4 years, end of "Measurement Period")

/*
This library evaluates with respect to exactly 1 candidate patient at a time,
that patient being given by the special context parameter Patient.
*/

context Patient

/*
Initial Population
Product lines -- Commercial, Medicaid, Medicare (report each product line separately).
*/

define "Initial Population":
  "Is Female"
    and "Is Age 24 to 64 at End"
    and not Common."Has Hospice"
/*
    and "Is In Applicable Product Line"
*/

define "Is Female":
  Patient.gender = 'female'
  
define "Is Age 24 to 64 at End":
  Common.CalendarAgeInYearsAt(FHIRHelpers.ToDate(Patient.birthDate), end of "Measurement Period") between 24 and 64

/*
Administrative Specification
*/

define "Denominator":
  true

define "Numerator":
  case
    when "Is Cervical Cytology Test In Last 3 Years" then true
    when (not "Is Age 30 to 64 at End") then false
    when "Is Cervical Cytology Plus HPV Test In Last 5 Years" then true
    else false
  end

define "Is Age 30 to 64 at End":
  Common.CalendarAgeInYearsAt(FHIRHelpers.ToDate(Patient.birthDate), end of "Measurement Period") between 30 and 64

define "Is Cervical Cytology Test In Last 3 Years":
  exists (
    "Dates of Cervical Cytology Tests" WhenCC
      where WhenCC included in day of "Lookback Interval Two More Years"
  )

define "Is Cervical Cytology Plus HPV Test In Last 5 Years":
  exists (
    "Dates of Cervical Cytology Tests" WhenCC
      with "Dates of HPV Tests" WhenHPV
        such that (((difference in days between start of WhenCC and start of WhenHPV) <= 4)
          and Common.CalendarAgeInYearsAt(FHIRHelpers.ToDate(Patient.birthDate), start of WhenCC) >= 30
          and Common.CalendarAgeInYearsAt(FHIRHelpers.ToDate(Patient.birthDate), start of WhenHPV) >= 30
          and WhenCC included in day of "Lookback Interval Four More Years"
          and WhenHPV included in day of "Lookback Interval Four More Years")
  )

define "Dates of Cervical Cytology Tests":
  ([Procedure: "Cervical Cytology Value Set"] Proc
    where Proc.status = 'completed'
    return Proc.performed)
  union
  ([DiagnosticReport: "Cervical Cytology Value Set"] DiagRep
    where DiagRep.status in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
    return DiagRep.effective)
  union
  ([Observation: "Cervical Cytology Value Set"] Obs
    where Obs.status in { 'final', 'amended' }
    return Obs.effective)

define "Dates of HPV Tests":
  ([Procedure: "HPV Tests Value Set"] Proc
    where Proc.status = 'completed'
    return Proc.performed)
  union
  ([DiagnosticReport: "HPV Tests Value Set"] DiagRep
    where DiagRep.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
    return DiagRep.effective)
  union
  ([Observation: "HPV Tests Value Set"] Obs
    where Obs.status.value in { 'final', 'amended' }
    return Obs.effective)

define "Denominator Exclusion":
  "Is Hysterectomy"

define "Is Hysterectomy":
  exists (
    [Procedure: "Absence of Cervix Value Set"] Proc
      where Proc.status = 'completed'
        and Proc.performed same day or before end of "Measurement Period"
  )

/*
Hybrid Specification
TODO, if needed
*/
