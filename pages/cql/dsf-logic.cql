/*
Depression Screening and Follow-Up for Adolescents and Adults (DSF)
*/

library DSF_FHIR version '1.0.0'

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

/*
Measure Description
The percentage of members 12 years of age and older who were screened for
		clinical depression using a standardized tool and, if screened positive,
		who received appropriate follow-up care. Two rates are reported.
	1. Depression Screening. The percentage of members who were screened for
		clinical depression using a standardized tool.
	2. Follow-Up on Positive Screen. The percentage of members who screened
		positive for depression and received appropriate follow-up care within 30 days.
*/

valueset "Major Depression and Dysthymia": 'urn:oid:2.16.840.1.113883.3.464.1003.105.12.1151' // Grouping Value Set
valueset "Bipolar Disorder": 'urn:oid:2.16.840.1.113883.3.464.1004.1044' // Grouping Value Set
valueset "Bipolar Disorder ECDS": 'urn:oid:2.16.840.1.113883.3.464.1004.1346' // Grouping Value Set
valueset "Other Bipolar Disorder": 'urn:oid:2.16.840.1.113883.3.464.1004.1399' // Grouping Value Set
valueset "Behavioral Health Encounter": 'urn:oid:2.16.840.1.113883.3.464.1004.1383' // Grouping Value Set
valueset "Case Management Encounter": 'urn:oid:2.16.840.1.113883.3.464.1004.1389' // Grouping Value Set
valueset "ECDS Follow-Up Visit Encounter": 'urn:oid:2.16.840.1.113883.3.464.1004.1385' // Grouping Value Set
valueset "Depression Screen": 'urn:oid:2.16.840.1.113883.3.464.1004.1384' // Grouping Value Set
valueset "Positive Depression Screen": 'urn:oid:2.16.840.1.113883.3.464.1004.1387' // Grouping Value Set
valueset "Negative Depression Screen": 'urn:oid:2.16.840.1.113883.3.464.1004.1386' // Grouping Value Set
valueset "Antidepressant Medication": 'TODO' // not in spec Data Criteria

/*
This library has an explicit parameter which is the measurement year.
While the actual parameter's type accepts all intervals, this library
expects it will only be given arguments corresponding exactly to one whole
calendar year, and it will not behave properly otherwise; 2015 for example:
Interval[DateTime(2015,1,1,0,0,0,0), DateTime(2016,1,1,0,0,0,0))
*/

parameter "Measurement Period" Interval<DateTime>

define "First Predecessor Year":
	Interval[start of "Measurement Period" - 1 year, start of "Measurement Period")

define "Lookback Interval One More Year":
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
	AgeInYearsAt(start of "Measurement Period") >= 12

/*
Exclusions
*/

define "Denominator Exclusion":
	exists (
		"Bipolar Disorder Reports" BD
			where BD.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and ChoiceToIntervalOfDT(BD.effective) overlaps "Lookback Interval One More Year"
	)
	or
	exists (
		[DiagnosticReport: "Major Depression and Dysthymia"] MDD
			where MDD.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and ChoiceToIntervalOfDT(MDD.effective) overlaps "First Predecessor Year"
	)

define "Bipolar Disorder Reports":
	[DiagnosticReport: "Bipolar Disorder"]
		union [DiagnosticReport: "Bipolar Disorder ECDS"]
		union [DiagnosticReport: "Other Bipolar Disorder"]

/*
Denominators and Numerators
*/

// Depression Screening
define "Denominator 1":
	"Initial Population"

// Depression Screening
define "Numerator 1":
	"Initial Population"
	and
	exists (
		[Observation: "Depression Screen"] DepressionScreen
			where DepressionScreen.status.value in { 'final', 'amended' }
				and ChoiceToIntervalOfDT(DepressionScreen.effective) overlaps "Measurement Period"
	)

// Positive Follow-Up
define "Denominator 2":
	"Initial Population"
	and exists ("Positive Depression Screen During Follow-Up Period")

// Positive Follow-Up
define "Numerator 2":
	"Initial Population"
	and
	(
		exists ("Dispensed Antidepressant Within 31 Days")
		or exists ("Follow-Up Encounter Within 31 Days")
		or exists ("Same Day Behavioral Encounter")
		or exists ("Negative Depression Screen Within 31 Days")
	)

define "Positive Depression Screen During Follow-Up Period":
	[Observation: "Positive Depression Screen"] PositiveScreen
		where PositiveScreen.status.value in { 'final', 'amended' }
			and ChoiceToIntervalOfDT(PositiveScreen.effective) overlaps "Measurement Period"

define "First Positive Depression Screen During Follow-Up Period":
	{First(
		"Positive Depression Screen During Follow-Up Period" Obs
			sort by start of ChoiceToIntervalOfDT(effective)
	)}

define "Follow-Up Care Encounters":
	distinct (
		[Encounter: "Behavioral Health Encounter"]
		union
		(
			[Encounter: "ECDS Follow-Up Visit Encounter"] E
				with [DiagnosticReport: "Major Depression and Dysthymia"] D
					such that E.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
						and D.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
						and ChoiceToIntervalOfDT(D.effective) overlaps PeriodToIntervalOfDT(E.period)
		)
		union
		[Encounter: "Case Management Encounter"]
	) Enc
		where Enc.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }

define "Same Day Behavioral Encounter":
	[Encounter: "Behavioral Health Encounter"] BehavioralEncounter
		with "First Positive Depression Screen During Follow-Up Period" PositiveScreen
			such that BehavioralEncounter.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and start of PeriodToIntervalOfDT(BehavioralEncounter.period) same day as start of ChoiceToIntervalOfDT(PositiveScreen.effective)
	return BehavioralEncounter

define "Dispensed Antidepressant Within 31 Days":
	// NOTE: Missing the valueset: "Antidepressant Medication"
	// OR
	// TODO: Check for Medications outlined in table AMM-C in the spec
	[MedicationDispense: "Antidepressant Medication"] Antidepressants
		with "First Positive Depression Screen During Follow-Up Period" PositiveScreen
			such that Antidepressants.status.value = 'completed'
				and days between Antidepressants.whenHandedOver.value and start of ChoiceToIntervalOfDT(PositiveScreen.effective) <= 31
	return Antidepressants

define "Follow-Up Encounter Within 31 Days":
	"Follow-Up Care Encounters" FollowUps
		with "First Positive Depression Screen During Follow-Up Period" PositiveScreen
			such that days between start of PeriodToIntervalOfDT(FollowUps.period) and start of ChoiceToIntervalOfDT(PositiveScreen.effective) >= 1
				and days between start of PeriodToIntervalOfDT(FollowUps.period) and start of ChoiceToIntervalOfDT(PositiveScreen.effective) <= 31
	return FollowUps

define "Negative Depression Screen Within 31 Days":
	[Observation: "Negative Depression Screen"] NegativeScreen
		with "First Positive Depression Screen During Follow-Up Period" PositiveScreen
			such that NegativeScreen.status.value in { 'final', 'amended' }
				and days between start of ChoiceToIntervalOfDT(NegativeScreen.effective) and start of ChoiceToIntervalOfDT(PositiveScreen.effective) <= 31
	return NegativeScreen

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
