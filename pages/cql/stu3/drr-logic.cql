library DRR_FHIR version '1.0.0'

/*
Depression Remission or Response for Adolescents and Adults (DRR)
*/

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0' called FHIRHelpers

/*
Measure Description
The percentage of members 12 years of age and older with a diagnosis of
		depression and an elevated PHQ-9 score, who had evidence of
		response or remission within 5 to 7 months of the elevated score.
		Three rates are reported.
	1. Follow-Up PHQ-9. The percentage of members who have a follow-up
		PHQ-9 score documented within the five to seven months after the
		initial elevated PHQ-9 score.
	2. Depression Remission. The percentage of members who achieved remission
		within five to seven months after the initial elevated PHQ-9 score.
	3. Depression Response. The percentage of members who showed response
		within five to seven months after the initial elevated PHQ-9 score.
*/

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED": 'http://snomed.info/sct'
codesystem "CQFramework": 'http://cqframework.info/codesystem/placeholder'

// valueset "Bipolar Disorder": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.67.1.101.1.128' // Grouping Value Set
// valueset "Personality Disorder": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.67.1.101.1.246' // Grouping Value Set
// valueset "Psychotic Disorder": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1003.105.12.1153' // User Defined QDM Value Set
// valueset "Pervasive Developmental Disorder": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1003.105.12.1152' // User Defined QDM Value Set
// valueset "Interactive Outpatient Encounter": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1003.101.12.1074' // Grouping Value Set
// valueset "PHQ-9 Modified Score": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1003.105.12.1154' // User Defined QDM Value Set
// valueset "PHQ-9 Tool": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.67.1.101.11.723' // Grouping Value Set

// update
valueset "Bipolar Disorder": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1044'
valueset "Bipolar Disorder ECDS": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1346'
// valueset "Hospice": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1418'
valueset "Interactive Outpatient Encounter": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1347'
valueset "Major Depression and Dysthymia": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1351'
valueset "Other Bipolar Disorder": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1399'
valueset "Personality Disorder": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1355'
valueset "Pervasive Developmental Disorder": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1356'
valueset "PHQ-9 Total Score": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1401'
valueset "Psychotic Disorder": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1352'

// code "Major Depression and Dysthymia": '78667006' from "SNOMED"
code "PHQ-9 Modified Score": '00009' from "CQFramework"
code "PHQ-9 Tool": '44249-1' from "LOINC"

/*
This library has an explicit parameter which is the measurement year.
While the actual parameter's type accepts all intervals, this library
expects it will only be given arguments corresponding exactly to one whole
calendar year, and it will not behave properly otherwise; 2017 for example:
Interval[DateTime(2017,1,1,0,0,0,0), DateTime(2018,1,1,0,0,0,0))
*/

parameter "Measurement Period" Interval<DateTime>

// Intake Period: June 1 of the year prior to the measurement period through May 31 of the measurement period.
define "Intake Period As MP Shifted Back 7 Months":
	Interval[start of "Measurement Period" - 7 months, end of "Measurement Period" - 7 months)

define "Intake Period Union Measurement Period":
	Interval[start of "Measurement Period" - 7 months, end of "Measurement Period" - 7 months)

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
	AgeInYearsAt(start of "Measurement Period") >= 12
	and
	exists (
		"DRR Encounter" DRR
			with [DiagnosticReport: "Major Depression and Dysthymia"] DepressionDiagnosis
				such that DepressionDiagnosis.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
					and PeriodToIntervalOfDT(DepressionDiagnosis.effective) overlaps day of PeriodToIntervalOfDT(DRR.period)
	)

define "DRR Encounter":
	[Encounter: "Interactive Outpatient Encounter"] DRR
		where DRR.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
			and PeriodToIntervalOfDT(DRR.period) during day of "Intake Period As MP Shifted Back 7 Months"

/*
Exclusions
*/

define "Denominator Exclusion":
	exists (
		distinct (
			[DiagnosticReport: "Bipolar Disorder"]
					// TODO: The spec mentions 3 Bipolar valuesets, which are like
					// the ones in DSF, but it only gives OIDs for one of the 3
					// and that OID is different than any in DSF.
					// Note that DMS and DRR are in the same boat.
				union [DiagnosticReport: "Personality Disorder"]
				union [DiagnosticReport: "Psychotic Disorder"]
				union [DiagnosticReport: "Pervasive Developmental Disorder"]
		) D
			where D.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and PeriodToIntervalOfDT(D.effective) overlaps day of "Intake Period Union Measurement Period"
	)

/*
Denominators and Numerators
*/

// Depression Follow-Up
define "Denominator 1":
	"Initial Population"
		and exists ("DRR Encounter")
		and "Depression Index" is not null

// Depression Follow-Up
define "Numerator 1":
	"Initial Population"
	and
	exists (
		"PHQ-9 Assessments" PHQ
			with "Depression Index" DI
				such that PHQ.effective.value after day of DI.effective.value
					and days between DI.effective.value and PHQ.effective.value >= 150
					and days between DI.effective.value and PHQ.effective.value <= 210
		return PHQ
	)

// Depression Remission
define "Denominator 2":
	"Denominator 1"

// Depression Remission
define "Numerator 2":
	"Initial Population"
	and
	exists (
		"PHQ-9 Assessments" PHQ
			with "Depression Index" DI
				such that (PHQ.value as Quantity).value.value < 5
					and PHQ.effective.value after day of DI.effective.value
					and days between DI.effective.value and PHQ.effective.value >= 150
					and days between DI.effective.value and PHQ.effective.value <= 210
		return PHQ
	)

// Depression Response
define "Denominator 3":
	"Denominator 1"

// Depression Response
define "Numerator 3":
	"Initial Population"
	and
	exists (
		"PHQ-9 Assessments" PHQ
			with "Depression Index" DI
				such that (PHQ.value as Quantity).value.value <= (DI.value as Quantity).value.value / 2
					and PHQ.effective.value after day of DI.effective.value
					and days between DI.effective.value and PHQ.effective.value >= 150
					and days between DI.effective.value and PHQ.effective.value <= 210
		return PHQ
	)

define "Depression Index":
	First (
		"PHQ-9 Assessments" PHQ
			with "DRR Encounter" DRR
				such that (PHQ.value as Quantity).value.value > 9
					and ((PHQ.effective.value same day or before start of PeriodToIntervalOfDT(DRR.period)
							and days between PHQ.effective.value and start of PeriodToIntervalOfDT(DRR.period) <= 15)
						or (PHQ.effective.value same day or after start of PeriodToIntervalOfDT(DRR.period)
							and days between start of PeriodToIntervalOfDT(DRR.period) and PHQ.effective.value <= 15))
		return PHQ
	)

define "PHQ-9 Assessments":
	distinct (
		[Observation: "PHQ-9 Tool"]
		union
		[Observation: "PHQ-9 Modified Score"]
	) PHQ
		where PHQ.status.value in { 'final', 'amended' }
			and PHQ.value is not null

/*
Stratifiers
*/

define "Stratifier 1":
	AgeInYearsAt(start of "Measurement Period") in Interval[12, 17]

define "Stratifier 2":
	AgeInYearsAt(start of "Measurement Period") in Interval[18, 44]

define "Stratifier 3":
	AgeInYearsAt(start of "Measurement Period") in Interval[45, 64]

define "Stratifier 4":
	AgeInYearsAt(start of "Measurement Period") >= 65

/*
Utility Functions
*/

define function PeriodToIntervalOfDT(value FHIR.Period):
	Interval[value."start".value, value."end".value]
