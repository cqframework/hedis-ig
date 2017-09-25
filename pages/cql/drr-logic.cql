/*
Depression Remission or Response for Adolescents and Adults (DRR)
*/

library DRR_FHIR version '1.0.0'

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

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

valueset "Major Depression and Dysthymia": 'urn:oid:2.16.840.1.113883.3.464.1003.105.12.1151' // Grouping Value Set
valueset "Personality Disorder": 'urn:oid:2.16.840.1.113883.3.67.1.101.1.246' // Grouping Value Set
valueset "Pervasive Developmental Disorder": 'urn:oid:2.16.840.1.113883.3.464.1003.105.12.1152' // User Defined QDM Value Set
valueset "Bipolar Disorder": 'urn:oid:2.16.840.1.113883.3.67.1.101.1.128' // Grouping Value Set
valueset "Psychotic Disorder": 'urn:oid:2.16.840.1.113883.3.464.1003.105.12.1153' // User Defined QDM Value Set
valueset "Interactive Outpatient Encounter": 'urn:oid:2.16.840.1.113883.3.464.1003.101.12.1074'
valueset "PHQ-9 Tool": 'urn:oid:2.16.840.1.113883.3.67.1.101.11.723' // Grouping Value Set
valueset "PHQ-9 Modified Score": 'urn:oid:2.16.840.1.113883.3.464.1003.105.12.1154' // Grouping Value Set

/*
This library has an explicit parameter which is the measurement year.
While the actual parameter's type accepts all intervals, this library
expects it will only be given arguments corresponding exactly to one whole
calendar year, and it will not behave properly otherwise; 2015 for example:
Interval[DateTime(2015,1,1,0,0,0,0), DateTime(2016,1,1,0,0,0,0))
*/

parameter "Measurement Period" Interval<DateTime>

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
		and exists ("DRR Encounter")
		and exists ("Depression Diagnosis Overlaps DRREncounter")

define "DRR Encounter":
	[Encounter: "Interactive Outpatient Encounter"] DRR
		where DRR.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
			and start of PeriodToIntervalOfDT(DRR.period) same day or before start of "Measurement Period"
			and months between start of PeriodToIntervalOfDT(DRR.period) and start of "Measurement Period" <= 6
			or start of "Measurement Period" before day of start of PeriodToIntervalOfDT(DRR.period)
				and months between start of "Measurement Period" and end of PeriodToIntervalOfDT(DRR.period) <= 5

define "Depression Diagnosis Overlaps DRREncounter":
	[DiagnosticReport: "Major Depression and Dysthymia"] DepressionDiagnosis
		with "DRR Encounter" DRR
			such that DepressionDiagnosis.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and ChoiceToIntervalOfDT(DepressionDiagnosis.effective) overlaps PeriodToIntervalOfDT(DRR.period)
		return DepressionDiagnosis

/*
Exclusions
*/

define "Denominator Exclusion":
	exists ("Exclusion Diagnoses Overlapping Measurement Period")
		or exists ("Exclusion Diagnoses 6 Months Before Measurement Period")

define "Exclusion Diagnoses":
	distinct (
		[DiagnosticReport: "Bipolar Disorder"]
		union [DiagnosticReport: "Personality Disorder"]
		union [DiagnosticReport: "Psychotic Disorder"]
		union [DiagnosticReport: "Pervasive Developmental Disorder"]
	) D
		where D.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }

define "Exclusion Diagnoses Overlapping Measurement Period":
	"Exclusion Diagnoses" ED
		where ChoiceToIntervalOfDT(ED.effective) overlaps "Measurement Period"

define "Exclusion Diagnoses 6 Months Before Measurement Period":
	"Exclusion Diagnoses" ED
		where start of ChoiceToIntervalOfDT(ED.effective) before day of start of "Measurement Period"
			and months between start of ChoiceToIntervalOfDT(ED.effective) and start of "Measurement Period" <= 6

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
	"PHQ-9 Assessments" PHQ
		with "Depression Index" DI
			such that ChoiceToIntervalOfDT(PHQ.effective) after day of ChoiceToIntervalOfDT(DI.effective)
				and days between start of ChoiceToIntervalOfDT(DI.effective) and start of ChoiceToIntervalOfDT(PHQ.effective) >= 150
				and days between start of ChoiceToIntervalOfDT(DI.effective) and start of ChoiceToIntervalOfDT(PHQ.effective) <= 210
	return PHQ

// Depression Remission
define "Denominator 2":
	"Denominator 1"

// Depression Remission
define "Numerator 2":
	"PHQ-9 Assessments" PHQ
		with "Depression Index" DI
			such that (PHQ.value as Quantity).value.value < 5
				and ChoiceToIntervalOfDT(PHQ.effective) after day of ChoiceToIntervalOfDT(DI.effective)
				and days between start of ChoiceToIntervalOfDT(DI.effective) and start of ChoiceToIntervalOfDT(PHQ.effective) >= 150
				and days between start of ChoiceToIntervalOfDT(DI.effective) and start of ChoiceToIntervalOfDT(PHQ.effective) <= 210
	return PHQ

// Depression Response
define "Denominator 3":
	"Denominator 1"

// Depression Response
define "Numerator 3":
	"PHQ-9 Assessments" PHQ
		with "Depression Index" DI
			such that (PHQ.value as Quantity).value.value <= (DI.value as Quantity).value.value / 2
				and ChoiceToIntervalOfDT(PHQ.effective) after day of ChoiceToIntervalOfDT(DI.effective)
				and days between start of ChoiceToIntervalOfDT(DI.effective) and start of ChoiceToIntervalOfDT(PHQ.effective) >= 150
				and days between start of ChoiceToIntervalOfDT(DI.effective) and start of ChoiceToIntervalOfDT(PHQ.effective) <= 210
	return PHQ

define "Depression Index":
	First (
		"PHQ-9 Assessments" PHQ
			with "DRR Encounter" DRR
				such that (PHQ.value as Quantity).value.value > 9
					and ((ChoiceToIntervalOfDT(PHQ.effective) same day or before start of PeriodToIntervalOfDT(DRR.period)
							and days between start of ChoiceToIntervalOfDT(PHQ.effective) and start of PeriodToIntervalOfDT(DRR.period) <= 15)
						or (ChoiceToIntervalOfDT(PHQ.effective) same day or after start of PeriodToIntervalOfDT(DRR.period)
							and days between start of PeriodToIntervalOfDT(DRR.period) and start of ChoiceToIntervalOfDT(PHQ.effective) <= 15))
		return PHQ
	)

define "PHQ-9 Assessments":
	distinct (
		([Observation: "PHQ-9 Tool"] PHQ
			where PHQ.status.value in { 'final', 'amended' }
				and PHQ.value is not null)
		union
		([Observation: "PHQ-9 Modified Score"] PHQMOD
			where PHQMOD.status.value in { 'final', 'amended' }
				and PHQMOD.value is not null)
	)

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
