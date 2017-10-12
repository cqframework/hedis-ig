/*
Unhealthy Alcohol Use Screening and Follow-up (ASF)
*/

library ASF_FHIR version '1.0.0'

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

/*
Measure Description
The percentage of members 18 years of age and older who were screened for
		unhealthy alcohol use using a standardized tool and, if screened
		positive, received appropriate follow-up care. Two rates are reported.
	1. Unhealthy Alcohol Use Screening. The percentage of members who had a
		systematic screening for unhealthy alcohol use.
	2. Counseling or Other Follow-up. The percentage of members who screened
		positive for unhealthy alcohol use and received brief counseling or
		other follow-up care within 2 months of a positive screening.
*/

codesystem "LOINC": 'http://loinc.org'

valueset "Alcohol Screening and Brief Counseling": 'urn:oid:1.1.1.1' // User Defined QDM Value Set
valueset "Five or more drinks per day": 'urn:oid:2.16.840.1.113883.3.464.1003.106.11.1035' // Value Set
valueset "Four or more drinks per day": 'urn:oid:2.16.840.1.113762.1.4.1072.14' // Value Set
valueset "Alcohol abuse or dependence": 'urn:oid:2.16.840.1.113883.3.464.1003.106.12.1010' // Grouping Value Set
	// TODO: This isn't referenced in any define.
valueset "Dementia": 'urn:oid:2.16.840.1.113883.3.464.1003.105.12.1101' // Grouping Value Set
valueset "Alcohol use disorder": 'TODO' // not in spec Data Criteria

code "AUDIT Total Score (in points)": '75624-7' from "LOINC"
code "AUDIT-C Total Score (in points)": '75626-2' from "LOINC"

/*
This library has an explicit parameter which is the measurement year.
While the actual parameter's type accepts all intervals, this library
expects it will only be given arguments corresponding exactly to one whole
calendar year, and it will not behave properly otherwise; 2015 for example:
Interval[DateTime(2015,1,1,0,0,0,0), DateTime(2016,1,1,0,0,0,0))

ADDENDUM: Unlike with most measures, this ASF measure is special such that
the effective "Measurement Period" actually extends 2 months earlier;
for cross-measure consistency, we keep the actual "Measurement Period"
parameter with its customary one-calendar-year meaning and internally use
a 14 month period starting on November 1 of the prior year.
*/

parameter "Measurement Period" Interval<DateTime>

define "Fourteen Month Measurement Period":
	Interval[start of "Measurement Period" - 2 months, end of "Measurement Period")

define "Intake Period":
	Interval[start of "Measurement Period" - 2 months, end of "Measurement Period" - 2 months)

define "Lookback Interval Total Two Years":
	Interval[start of "Measurement Period" - 1 year, end of "Measurement Period")

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
	AgeInYearsAt(start of "Fourteen Month Measurement Period") >= 18

/*
Exclusions
*/

define "Denominator Exclusion":
	exists (
		[DiagnosticReport: "Alcohol use disorder"] D
			where D.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and ChoiceToIntervalOfDT(D.effective) overlaps "Lookback Interval Total Two Years"
	)
	or
	exists (
		[DiagnosticReport: "Dementia"] D
			where D.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and ChoiceToIntervalOfDT(D.effective) overlaps "Intake Period"
	)

/*
Denominators and Numerators
*/

// Unhealthy Alcohol Use Screening
define "Denominator 1":
	"Initial Population"

// Unhealthy Alcohol Use Screening
define "Numerator 1":
	"Initial Population"
	and
	(
		exists ("AUDIT-C Assessment")
		or exists ("AUDIT Assessment")
		or ("Patient is Male" and exists ("Five or more drinks per day Assessment"))
		or ("Patient is Female" and exists ("Four or more drinks per day Assessment"))
		or ("Patient is over 65" and exists ("Four or more drinks per day Assessment"))
			// Note: The spec doesn't include the over 65 test here but does in dependent N/D 2.
	)

define "AUDIT-C Assessment":
	[Observation: "AUDIT-C Total Score (in points)"] A
		where A.status.value in { 'final', 'amended' }
			and ChoiceToIntervalOfDT(A.effective) during "Intake Period"
			and A.value is not null

define "AUDIT Assessment":
	[Observation: "AUDIT Total Score (in points)"] A
		where A.status.value in { 'final', 'amended' }
			and ChoiceToIntervalOfDT(A.effective) during "Intake Period"
			and A.value is not null

define "Patient is Male":
	Patient.gender.value = 'male'

define "Five or more drinks per day Assessment":
	[Observation: "Five or more drinks per day"] A
		where A.status.value in { 'final', 'amended' }
			and ChoiceToIntervalOfDT(A.effective) during "Intake Period"
			and A.value is not null

define "Patient is Female":
	Patient.gender.value = 'female'

define "Patient is over 65":
	AgeInYearsAt(start of "Fourteen Month Measurement Period") >= 65

define "Four or more drinks per day Assessment":
	[Observation: "Four or more drinks per day"] A
		where A.status.value in { 'final', 'amended' }
			and ChoiceToIntervalOfDT(A.effective) during "Intake Period"
			and A.value is not null

// Counseling or Other Follow-Up on Positive Screen
define "Denominator 2":
	"Initial Population"
	and
	exists "Positive Assessment for Unhealthy Alcohol Use"

// Counseling or Other Follow-Up on Positive Screen
define "Numerator 2":
	"Initial Population"
	and
	exists (
		"Initial Positive Assessment for Unhealthy Alcohol Use" A
			with "Followup Screening" F such that ChoiceToIntervalOfDT(F.effective) starts 2 months or less after end of ChoiceToIntervalOfDT(A.effective)
	)

define "Positive Assessment for Unhealthy Alcohol Use":
	(
		"AUDIT Assessment" A
			where (A.value as Quantity).value.value >= 8
	)
	union
	(
		"AUDIT-C Assessment" A
			where ("Patient is Male" and (A.value as Quantity).value.value >= 4)
				or ("Patient is Female" and (A.value as Quantity).value.value >= 3)
	)
	union
	(
		"Five or more drinks per day Assessment" A
			where "Patient is Male" and (A.value as Quantity).value.value >= 2
	)
	union
	(
		"Four or more drinks per day Assessment" A
			where ("Patient is Female" or "Patient is over 65")
				and (A.value as Quantity).value.value >= 2
	)

define "Followup Screening":
	[Observation: "Alcohol Screening and Brief Counseling"] Obs
		where Obs.status.value in { 'final', 'amended' }

define "Initial Positive Assessment for Unhealthy Alcohol Use":
	{First(
		"Positive Assessment for Unhealthy Alcohol Use" A
			sort by start of ChoiceToIntervalOfDT(effective)
	)}

/*
Stratifiers
*/

define "Stratifier 1":
	AgeInYearsAt(start of "Fourteen Month Measurement Period") in Interval[18, 25]

define "Stratifier 2":
	AgeInYearsAt(start of "Fourteen Month Measurement Period") in Interval[26, 44]

define "Stratifier 3":
	AgeInYearsAt(start of "Fourteen Month Measurement Period") in Interval[45, 64]

define "Stratifier 4":
	AgeInYearsAt(start of "Fourteen Month Measurement Period") >= 65

/*
Utility Functions
*/

define function ChoiceToIntervalOfDT(value Choice<FHIR.dateTime, FHIR.Period>):
	if value is FHIR.dateTime then
		Interval[value.value, value.value]
	else
		Interval[value."start".value, value."end".value]

define function PeriodToIntervalOfDT(value FHIR.Period):
	Interval[value."start".value, value."end".value]

define function CodingToCode(coding FHIR.Coding):
	System.Code {
		code: coding.code.value,
		system: coding.system.value,
		version: coding.version.value,
		display: coding.display.value
	}
	// From FHIRHelpers
