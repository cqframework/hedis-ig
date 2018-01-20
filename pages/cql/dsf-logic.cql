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

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED": 'http://snomed.info/sct'
codesystem "CQFramework": 'http://cqframework.info/codesystem/placeholder'

// valueset "Bipolar Disorder": 'urn:oid:2.16.840.1.113883.3.464.1004.1044' // Grouping Value Set
// valueset "Bipolar Disorder ECDS": 'urn:oid:2.16.840.1.113883.3.464.1004.1346' // Grouping Value Set
// valueset "Other Bipolar Disorder": 'urn:oid:2.16.840.1.113883.3.464.1004.1399' // Grouping Value Set
// valueset "Behavioral Health Encounter": 'urn:oid:2.16.840.1.113883.3.464.1004.1383' // Grouping Value Set
// valueset "Depression Case Management Encounter": 'urn:oid:2.16.840.1.113883.3.464.1004.1389' // Grouping Value Set
// valueset "ECDS Follow-Up Visit": 'urn:oid:2.16.840.1.113883.3.464.1004.1385' // Grouping Value Set
// valueset "Depression Screen": 'urn:oid:2.16.840.1.113883.3.464.1004.1384' // Grouping Value Set
// valueset "Positive Depression Screen": 'urn:oid:2.16.840.1.113883.3.464.1004.1387' // Grouping Value Set
// valueset "Negative Depression Screen": 'urn:oid:2.16.840.1.113883.3.464.1004.1386' // Grouping Value Set
// valueset "Antidepressant Medication": 'TODO' // not in spec Data Criteria

// update
valueset "Behavioral Health Encounter": '2.16.840.1.113883.3.464.1004.1383'
valueset "Bipolar Disorder": '2.16.840.1.113883.3.464.1004.1044'
valueset "Bipolar Disorder ECDS": '2.16.840.1.113883.3.464.1004.1346'
valueset "Depression": '2.16.840.1.113883.3.464.1004.1390'
valueset "Depression Case Management Encounter": '2.16.840.1.113883.3.464.1004.1389'
valueset "Depression Screen": '2.16.840.1.113883.3.464.1004.1384'
valueset "ECDS Follow-Up Visit": '2.16.840.1.113883.3.464.1004.1385'
// valueset "Hospice": '2.16.840.1.113883.3.464.1004.1418'
valueset "Mental Illness": '2.16.840.1.113883.3.464.1004.1179'
valueset "Mental Illness SNOMED": '2.16.840.1.113883.3.464.1004.1453'
valueset "Negative Depression Screen": '2.16.840.1.113883.3.464.1004.1386'
valueset "Other Bipolar Disorder": '2.16.840.1.113883.3.464.1004.1399'
valueset "Positive Depression Screen": '2.16.840.1.113883.3.464.1004.1387'
valueset "Major Depression and Dysthymia": '2.16.840.1.113883.3.464.1004.1351'

code "Antidepressant Medication": '00001' from "CQFramework"
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
				and PeriodToIntervalOfDT(BD.effective) overlaps "Lookback Interval One More Year"
	)
	or
	exists (
		[DiagnosticReport: "Major Depression and Dysthymia"] MDD
			where MDD.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and PeriodToIntervalOfDT(MDD.effective) overlaps "First Predecessor Year"
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
				and DepressionScreen.effective.value in "Measurement Period"
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
			and PositiveScreen.effective.value in "Measurement Period"

define "First Positive Depression Screen During Follow-Up Period":
	{First(
		"Positive Depression Screen During Follow-Up Period" Obs
			sort by effective.value
	)}

define "Follow-Up Care Encounters":
	distinct (
		[Encounter: "Behavioral Health Encounter"]
		union
		(
			[Encounter: "ECDS Follow-Up Visit"] E
				with [DiagnosticReport: "Major Depression and Dysthymia"] D
					such that E.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
						and D.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
						and PeriodToIntervalOfDT(D.effective) overlaps PeriodToIntervalOfDT(E.period)
		)
		union
		[Encounter: "Depression Case Management Encounter"]
	) Enc
		where Enc.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }

define "Same Day Behavioral Encounter":
	[Encounter: "Behavioral Health Encounter"] BehavioralEncounter
		with "First Positive Depression Screen During Follow-Up Period" PositiveScreen
			such that BehavioralEncounter.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and start of PeriodToIntervalOfDT(BehavioralEncounter.period) same day as PositiveScreen.effective.value
	return BehavioralEncounter

define "Dispensed Antidepressant Within 31 Days":
	[MedicationDispense: medication in "Antidepressant Medication"] Antidepressants
		with "First Positive Depression Screen During Follow-Up Period" PositiveScreen
			such that Antidepressants.status.value = 'completed'
				and days between Antidepressants.whenHandedOver.value and PositiveScreen.effective.value <= 31
	return Antidepressants

define "Follow-Up Encounter Within 31 Days":
	"Follow-Up Care Encounters" FollowUps
		with "First Positive Depression Screen During Follow-Up Period" PositiveScreen
			such that days between start of PeriodToIntervalOfDT(FollowUps.period) and PositiveScreen.effective.value >= 1
				and days between start of PeriodToIntervalOfDT(FollowUps.period) and PositiveScreen.effective.value <= 31
	return FollowUps

define "Negative Depression Screen Within 31 Days":
	[Observation: "Negative Depression Screen"] NegativeScreen
		with "First Positive Depression Screen During Follow-Up Period" PositiveScreen
			such that NegativeScreen.status.value in { 'final', 'amended' }
				and days between NegativeScreen.effective.value and PositiveScreen.effective.value <= 31
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

define function PeriodToIntervalOfDT(value FHIR.Period):
	Interval[value."start".value, value."end".value]
