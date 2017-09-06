/*
Cervical Cancer Screening (CCS)
*/

library CCS_FHIR version '1.0.0'

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

/*
Library HEDIS_FHIR_Common declares these parameters on behalf of every measure:
	parameter "Product Line" String
	parameter "Measurement Period" Interval<DateTime>
See that library for more details.
*/

include HEDIS_FHIR_Common version '1.0.0' called HFC

/*
Description
The percentage of women 21–64 years of age who were screened for cervical
		cancer using either of the following criteria:
•	Women 21–64 years of age who had cervical cytology performed every 3 years.
•	Women 30–64 years of age who had cervical cytology/human papillomavirus
		(HPV) co-testing performed every 5 years.
*/

valueset "Absence of Cervix Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1123.17' // CPT
// valueset "Absence of Cervix Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1123.18' // ICD10CM
// valueset "Absence of Cervix Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1123.19' // ICD10PCS
// valueset "Absence of Cervix Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1123.20' // ICD9CM
// valueset "Absence of Cervix Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1123.21' // ICD9CMProc

valueset "Cervical Cytology Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1208.22' // CPT
// valueset "Cervical Cytology Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1208.23' // HCPCS
// valueset "Cervical Cytology Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1208.24' // LOINC
// valueset "Cervical Cytology Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1208.25' // RevCode

valueset "HPV Tests Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1265.26' // CPT
// valueset "HPV Tests Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1265.27' // HCPCS
// valueset "HPV Tests Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1265.28' // LOINC

define "Lookback Interval Two More Years":
	Interval[start of HFC."Measurement Period" - 2 years, end of HFC."Measurement Period")

define "Lookback Interval Four More Years":
	Interval[start of HFC."Measurement Period" - 4 years, end of HFC."Measurement Period")

/*
This library evaluates with respect to exactly 1 candidate patient at a time,
that patient being given by the special context parameter Patient.
*/

context Patient

/*
Eligible Population
Product lines -- Commercial, Medicaid (report each product line separately).
*/

define "Is In Eligible Population":
	"Is Female"
		and "Is Age 24 to 64 at End"
		and (not HFC."Is In Hospice")
		and HFC."Is In Applicable Product Line"

define "Is Female":
	Patient.gender.value = 'female'

define "Is Age 24 to 64 at End":
	AgeInYearsAt(end of HFC."Measurement Period") between 24 and 64


/*
Administrative Specification
*/

define "Is In Denominator":
	"Is In Eligible Population"

define "Is In Numerator":
	case
		when (not "Is In Eligible Population") then false
		when "Is Cervical Cytology Test In Last 3 Years" then true
		when (not "Is Age 30 to 64 at End") then false
		when "Is Cervical Cytology Plus HPV Test In Last 5 Years" then true
		else false
	end

define "Is Age 30 to 64 at End":
	AgeInYearsAt(end of HFC."Measurement Period") between 30 and 64

define "Is Cervical Cytology Test In Last 3 Years":
	exists(
		"Dates of Cervical Cytology Tests" WhenCC
			where IncludedIn(WhenCC, "Lookback Interval Two More Years")
	)

define "Is Cervical Cytology Plus HPV Test In Last 5 Years":
	exists(
		"Dates of Cervical Cytology Tests" WhenCC
			with "Dates of HPV Tests" WhenHPV
				such that (((difference in days between start of WhenCC and start of WhenHPV) <= 4)
					and AgeInYearsAt(start of WhenCC) >= 30
					and AgeInYearsAt(start of WhenHPV) >= 30
					and IncludedIn(WhenCC, "Lookback Interval Four More Years")
					and IncludedIn(WhenHPV, "Lookback Interval Four More Years"))
	)

define "Dates of Cervical Cytology Tests":
	([Procedure: "Cervical Cytology Value Set"] Proc
		where Proc.status.value = 'completed'
		return HFC.ChoiceToIntervalOfDT(Proc.performed))
	union
	([DiagnosticReport: "Cervical Cytology Value Set"] DiagRep
		where DiagRep.status.value in { 'final', 'appended', 'corrected' }
		return HFC.ChoiceToIntervalOfDT(DiagRep.effective))
	union
	([Observation: "Cervical Cytology Value Set"] Obs
		where Obs.status.value in { 'final', 'amended' }
		return HFC.ChoiceToIntervalOfDT(Obs.effective))

define "Dates of HPV Tests":
	([Procedure: "HPV Tests Value Set"] Proc
		where Proc.status.value = 'completed'
		return HFC.ChoiceToIntervalOfDT(Proc.performed))
	union
	([DiagnosticReport: "HPV Tests Value Set"] DiagRep
		where DiagRep.status.value in { 'final', 'appended', 'corrected' }
		return HFC.ChoiceToIntervalOfDT(DiagRep.effective))
	union
	([Observation: "HPV Tests Value Set"] Obs
		where Obs.status.value in { 'final', 'amended' }
		return HFC.ChoiceToIntervalOfDT(Obs.effective))

define "Is In Administrative Exclusions":
	exists(
		[Procedure: "Cervical Cytology Value Set"] Proc
			where Proc.status.value = 'completed'
				and end of HFC.ChoiceToIntervalOfDT(Proc.performed) before end of HFC."Measurement Period"
	)

/*
Hybrid Specification
TODO, if needed
*/
