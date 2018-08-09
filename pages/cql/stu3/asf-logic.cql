/*
Unhealthy Alcohol Use Screening and Follow-up (ASF)
*/library ASF_FHIR version '1.0.0'

//using FHIR version '3.0.1'

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0' called FHIRHelpers

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
codesystem "CQFramework": 'http://cqframework.info/codesystem/placeholder'

// valueset "Alcohol Screening and Brief Counseling": 'urn:oid:1.1.1.1' // User Defined QDM Value Set
// valueset "Five or more drinks per day": 'urn:oid:2.16.840.1.113883.3.464.1003.106.11.1035' // Value Set
// valueset "Four or more drinks per day": 'urn:oid:2.16.840.1.113762.1.4.1072.14' // Value Set
// valueset "Alcohol abuse or dependence": 'urn:oid:2.16.840.1.113883.3.464.1003.106.12.1010' // Grouping Value Set
// valueset "Dementia": 'urn:oid:2.16.840.1.113883.3.464.1003.105.12.1101' // Grouping Value Set
// valueset "Alcohol use disorder": 'TODO' // not in spec Data Criteria

// Update

valueset "Alcohol Counseling and Treatment": '2.16.840.1.113883.3.464.1004.1437'
valueset "Alcohol Screening": '2.16.840.1.113883.3.464.1004.1337'
valueset "Alcohol use disorder": '2.16.840.1.113883.3.464.1004.1339'
valueset "Dementia": '2.16.840.1.113883.3.464.1004.1074'
// valueset "Hospice": '2.16.840.1.113883.3.464.1004.1418'

code "Five or more drinks per day": '00005' from "CQFramework"
code "Four or more drinks per day": '00004' from "CQFramework"
code "AUDIT Total Score (in points)": '75624-7' from "LOINC"
code "AUDIT-C Total Score (in points)": '75626-2' from "LOINC"

/*
This library has an explicit parameter which is the measurement year.
While the actual parameter's type accepts all intervals, this library
expects it will only be given arguments corresponding exactly to one whole
calendar year, and it will not behave properly otherwise; 2017 for example:
Interval[DateTime(2017,1,1,0,0,0,0), DateTime(2018,1,1,0,0,0,0))
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
	AgeInYearsAt(start of "Measurement Period") >= 18

/*
Exclusions
*/

define "Denominator Exclusion":
	exists (
	    [Condition: "Alcohol use disorder"] AlcoholUse
			where AlcoholUse.clinicalStatus in { 'active', 'recurrence' }
            and AlcoholUse.assertedDate during day of Interval[start of "Measurement Period" - 1 year, end of "Measurement Period"]
	)
    or exists (
        [Condition: "Dementia"] D
            where D.clinicalStatus in { 'active', 'recurrence' }
            and D.assertedDate during day of Interval[start of "Measurement Period", end of "Measurement Period" - 60 days]
    )

/*
Denominators and Numerators
*/

// Unhealthy Alcohol Use Screening

define "Denominator 1":
	// "Initial Population"
	true

// Unhealthy Alcohol Use Screening

define "Numerator 1":
	// "Initial Population"
	exists ( "AUDIT-C Assessment" )
    or exists ( "AUDIT Assessment" )
    or (
        "Patient is Male"
        and exists ( "Five or more drinks per day Assessment" )
    )
    or (
        "Patient is Female"
        and (
            exists ( "Four or more drinks per day Assessment" )
            or exists ( "Five or more drinks per day Assessment" )
        )
    )
    or (
        "Patient is 65 or Over"
            and (
                exists ( "Four or more drinks per day Assessment" )
                or exists ( "Five or more drinks per day Assessment" )
            )
    )
   // Note: The spec doesn't include the over 65 test here but does in dependent N/D 2.

define "AUDIT-C Assessment":
	[Observation: "AUDIT-C Total Score (in points)"] A
		where A.status.value in { 'final', 'amended', 'corrected' }
			and A.effective.value in day of "Measurement Period"
			and A.value is not null

define "AUDIT Assessment":
	[Observation: "AUDIT Total Score (in points)"] A
		where A.status.value in { 'final', 'amended', 'corrected' }
			and A.effective.value in day of "Measurement Period"
			and A.value is not null

define "Patient is Male":
	Patient.gender.value = 'male'

define "Five or more drinks per day Assessment":
	[Observation: "Five or more drinks per day"] A
		where A.status.value in { 'final', 'amended', 'corrected' }
			and A.effective.value in day of "Measurement Period"
			and A.value is not null

define "Patient is Female":
	Patient.gender.value = 'female'

define "Patient is 65 or Over":
	AgeInYearsAt(start of "Measurement Period")>= 65

define "Four or more drinks per day Assessment":
	[Observation: "Four or more drinks per day"] A
		where A.status.value in { 'final', 'amended', 'corrected' }
			and A.effective.value in day of "Measurement Period"
			and A.value is not null

// Counseling or Other Follow-Up on Positive Screen

/*
Initial Population
Product lines -- Commercial, Medicaid, Medicare (report each product line separately).
*/

define "Denominator 2":
	// "Initial Population"
	exists "Positive Assessment for Unhealthy Alcohol Use"

// Counseling or Other Follow-Up on Positive Screen

define "Numerator 2":
	// "Initial Population"
    exists (
        "Initial Positive Assessment for Unhealthy Alcohol Use" A
            with "Followup After Positive Screen" F
                such that
                if F is Observation then F.effective.value 2 months or less on or after day of A.effective.value
                else F.performed."end".value 2 months or less on or after day of A.effective.value
    )

define "Positive Assessment for Unhealthy Alcohol Use":
	(
	    "AUDIT Assessment" A
			where ( A.value as Quantity ).value.value >= 8
	)
    union (
        "AUDIT-C Assessment" A
            where
                (
                    "Patient is Male"
                        and ( A.value as Quantity ).value.value >= 4
                )
				or (
				    "Patient is Female"
                        and ( A.value as Quantity ).value.value >= 3
                )
    )
    union (
        "Five or more drinks per day Assessment" A
            where "Patient is Male"
            and ( A.value as Quantity ).value.value >= 1
    )
    union (
        "Four or more drinks per day Assessment" A
            where (
                "Patient is Female"
                    or "Patient is 65 or Over"
            )
            and ( A.value as Quantity ).value.value >= 1
    )

define "Followup After Positive Screen":
	(
	    [Procedure: "Alcohol Counseling and Treatment"] Proc
			where Proc.status.value = 'completed'
	)
    union (
        [Observation: "Alcohol Counseling and Treatment"] Obs
            where Obs.status.value in { 'final', 'amended', 'corrected' }
    )
    union (
        [Procedure: "Alcohol Screening"] Proc
            where Proc.status.value = 'completed'
    )
    union (
        [Observation: "Alcohol Screening"] Obs
            where Obs.status.value in { 'final', 'amended', 'corrected' }
    )

define "Initial Positive Assessment for Unhealthy Alcohol Use":
	{
	    First(
	        "Positive Assessment for Unhealthy Alcohol Use" A
			    sort by effective.value
        )
    }

/*
Stratifiers
*/

define "Stratifier 1":
	AgeInYearsAt(start of "Measurement Period")in Interval[18, 44]

define "Stratifier 2":
	AgeInYearsAt(start of "Measurement Period")in Interval[45, 64]

define "Stratifier 3":
	AgeInYearsAt(start of "Measurement Period")>= 65


/*
Utility Functions
*/

define function PeriodToIntervalOfDT(value FHIR.Period):
	Interval[value."start".value, value."end".value]
