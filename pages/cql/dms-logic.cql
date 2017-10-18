/*
Utilization of the PHQ-9 to Monitor Depression Symptoms for Adolescents and Adults (DMS)
*/

library DMS_FHIR version '1.0.0'

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

/*
Measure Description
The percentage of members 12 years of age and older with a diagnosis of major
depression or dysthymia, who had an outpatient encounter with a PHQ-9 score
present in their record in the same assessment period as the encounter.
*/

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED": 'http://snomed.info/sct'
codesystem "CQFramework": 'http://cqframework.info/codesystem/placeholder'

// valueset "Bipolar Disorder": 'urn:oid:2.16.840.1.113883.3.67.1.101.1.128' // Grouping Value Set
// valueset "Personality Disorder": 'urn:oid:2.16.840.1.113883.3.67.1.101.1.246' // Grouping Value Set
// valueset "Psychotic Disorder": 'urn:oid:2.16.840.1.113883.3.464.1003.105.12.1153' // User Defined QDM Value Set
// valueset "Pervasive Developmental Disorder": 'urn:oid:2.16.840.1.113883.3.464.1003.105.12.1152' // User Defined QDM Value Set
// valueset "Interactive Outpatient Encounter": 'urn:oid:2.16.840.1.113883.3.464.1003.101.12.1074' // Grouping Value Set
// valueset "PHQ-9 Modified Score": 'urn:oid:2.16.840.1.113883.3.464.1003.105.12.1154' // User Defined QDM Value Set
// valueset "PHQ-9 Tool": 'urn:oid:2.16.840.1.113883.3.67.1.101.11.723' // Grouping Value Set

// update
valueset "Bipolar Disorder": '2.16.840.1.113883.3.464.1004.1044'
valueset "Bipolar Disorder ECDS": '2.16.840.1.113883.3.464.1004.1346'
valueset "Hospice": '2.16.840.1.113883.3.464.1004.1418'
valueset "Interactive Outpatient Encounter": '2.16.840.1.113883.3.464.1004.1347'
valueset "Major Depression and Dysthymia": '2.16.840.1.113883.3.464.1004.1351'
valueset "Other Bipolar Disorder": '2.16.840.1.113883.3.464.1004.1399'
valueset "Personality Disorder": '2.16.840.1.113883.3.464.1004.1355'
valueset "Pervasive Developmental Disorder": '2.16.840.1.113883.3.464.1004.1356'
valueset "PHQ-9 Total Score": '2.16.840.1.113883.3.464.1004.1401'
valueset "Psychotic Disorder": '2.16.840.1.113883.3.464.1004.1352'

// code "Major Depression and Dysthymia": '78667006' from "SNOMED"
code "PHQ-9 Modified Score": '00009' from "CQFramework"
code "PHQ-9 Tool": '44249-1' from "LOINC"

/*
This library has an explicit parameter which is the measurement year.
While the actual parameter's type accepts all intervals, this library
expects it will only be given arguments corresponding exactly to one whole
calendar year, and it will not behave properly otherwise; 2015 for example:
Interval[DateTime(2015,1,1,0,0,0,0), DateTime(2016,1,1,0,0,0,0))
*/

parameter "Measurement Period" Interval<DateTime>

/*
The measurement period is segmented to establish regular utilization of the PHQ
assessment tool in the management of depression. The first qualifying encounter
in each period determines the denominator events for the performance measure.
The measurement period is divided into three assessment periods with specific dates of service:
	• Assessment Period One. January 1–April 30 of the measurement period.
	• Assessment Period Two. May 1–August 31 of the measurement period.
	• Assessment Period Three. September 1–December 31 of the measurement period.
*/

define "Assessment Period One":
	Interval[start of "Measurement Period"           , end of "Measurement Period" - 8 months)

define "Assessment Period Two":
	Interval[start of "Measurement Period" + 4 months, end of "Measurement Period" - 4 months)

define "Assessment Period Three":
	Interval[start of "Measurement Period" + 8 months, end of "Measurement Period"           )

/*
This library evaluates with respect to exactly 1 candidate patient at a time,
that patient being given by the special context parameter Patient.
*/

context Patient

/*
Initial Population
Product lines -- Commercial, Medicaid, Medicare (report each product line separately).
*/

// NOTE: The initial population is described as "members", but the measure is encounter-based...
define "Initial Population":
	AgeInYearsAt(start of "Measurement Period") >= 12
		and exists (
			[Encounter: "Interactive Outpatient Encounter"] E
				where E.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
					and PeriodToIntervalOfDT(E.period) during "Measurement Period"
		)
		and exists (
			[DiagnosticReport: "Major Depression and Dysthymia"] D
				where D.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
					and D.effective.value in "Measurement Period"
		)

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
				and D.effective.value in "Measurement Period"
	)

/*
Denominators and Numerators
*/

define "Denominator 1":
	{First(
		"Depression Encounters" E
			where PeriodToIntervalOfDT(E.period) during "Assessment Period One"
			sort by start of PeriodToIntervalOfDT(period)
	)}

define "Denominator 2":
	{First(
		"Depression Encounters" E
			where PeriodToIntervalOfDT(E.period) during "Assessment Period Two"
			sort by start of PeriodToIntervalOfDT(period)
	)}

define "Denominator 3":
	{First(
		"Depression Encounters" E
			where PeriodToIntervalOfDT(E.period) during "Assessment Period Three"
			sort by start of PeriodToIntervalOfDT(period)
	)}

define "Depression Encounters":
	[Encounter: "Interactive Outpatient Encounter"] E
		with [DiagnosticReport: "Major Depression and Dysthymia"] D
			such that E.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and D.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and D.effective.value in PeriodToIntervalOfDT(E.period)

define "PHQ-9 Score":
	distinct (
		[Observation: "PHQ-9 Tool"]
		union
		[Observation: "PHQ-9 Modified Score"]
	) A
		where A.status.value in { 'final', 'amended' }
			and A.value is not null

define "Numerator 1":
	"Denominator 1" E
		with "PHQ-9 Score" A
			such that A.effective.value in "Assessment Period One"

define "Numerator 2":
	"Denominator 2" E
		with "PHQ-9 Score" A
			such that A.effective.value in "Assessment Period Two"

define "Numerator 3":
	"Denominator 3" E
		with "PHQ-9 Score" A
			such that A.effective.value in "Assessment Period Three"

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
