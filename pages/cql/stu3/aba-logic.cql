library ABA_FHIR version '1'

/*

Adult BMI Assessment (ABA)

*/

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0' called FHIRHelpers

valueset "Outpatient": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1202'
valueset "Pregnancy": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1219'
valueset "BMI": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1037'
valueset "BMI Percentile": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1038'

parameter "Measurement Period" Interval<DateTime>

context Patient

/*

Eligible Population:
18 years as of January 1 of the year prior to the measurement year to 74 years as of December 31 of the measurement year.

*/
define "Initial Population":
  AgeInYearsAt(start of "Measurement Period" - 1 year) >= 18
    and AgeInYearsAt(end of "Measurement Period") <= 74

define "Denominator":
  "Initial Population"

/*

Numerator:
For members 20 years of age or older on the date of service, BMI (BMI Value Set)
  during the measurement year or the year prior to the measurement year.

For members younger than 20 years of age on the date of service, BMI percentile
  (BMI Percentile Value Set) during the measurement year or the year prior to
    the measurement year.

*/
define "Numerator":
  if AgeInYearsAt(start of "Most Recent Outpatient Encounter".period) >= 20
    then exists({ "Last BMI during the measurement year or the year prior to the measurement year" })
    else exists({ "Last BMI percentile during the measurement year or the year prior to the measurement year" })


// TODO: Using this as the "date of service" - need to verify
define "Most Recent Outpatient Encounter":
  Last(
    [Encounter: "Outpatient"] OutpatientEncounter
      where OutpatientEncounter.status ~ 'finished'
    sort by start of period
  )

define "Last BMI during the measurement year or the year prior to the measurement year":
  Last(
    [Observation: "BMI"] BMIObservation
      where BMIObservation.status in { 'final', 'amended' }
    sort by effective
  )

define "Last BMI percentile during the measurement year or the year prior to the measurement year":
  Last(
    [Observation: "BMI Percentile"] BMIPercentileObservation
      where BMIPercentileObservation.status in { 'final', 'amended' }
    sort by effective
  )

  // TODO: Exclusions - In hospice care or pregnant
