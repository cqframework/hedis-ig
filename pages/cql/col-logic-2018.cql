/*
Colorectal Cancer Screening (COL)
*/

library COL_FHIR version '1.0.0'

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
The percentage of members 50–75 years of age who had appropriate screening for colorectal cancer.
*/

valueset "Colonoscopy Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1064.29' // CPT
// valueset "Colonoscopy Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1064.30' // HCPCS
// valueset "Colonoscopy Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1064.31' // ICD9CMProc

valueset "Colorectal Cancer Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1065.32' // ICD10CM
// valueset "Colorectal Cancer Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1065.33' // ICD10CM

valueset "CT Colonography Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1421.34' // CPT

valueset "FIT-DNA Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1420.35' // CPT
// valueset "FIT-DNA Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1420.36' // HCPCS
// valueset "FIT-DNA Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1420.37' // LOINC

valueset "Flexible Sigmoidoscopy Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1102.38' // CPT
// valueset "Flexible Sigmoidoscopy Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1102.39' // HCPCS
// valueset "Flexible Sigmoidoscopy Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1102.40' // ICD9CMProc

valueset "FOBT Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1093.41' // CPT
// valueset "FOBT Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1093.42' // HCPCS
// valueset "FOBT Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1093.43' // ICD9CMProc

valueset "Total Colectomy Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1250.44' // CPT
// valueset "Total Colectomy Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1250.45' // ICD10PCS
// valueset "Total Colectomy Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1250.46' // ICD9CMProc

define "Lookback Interval Two More Years":
	Interval[start of HFC."Measurement Period" - 2 years, end of HFC."Measurement Period")

define "Lookback Interval Four More Years":
	Interval[start of HFC."Measurement Period" - 4 years, end of HFC."Measurement Period")

define "Lookback Interval Nine More Years":
	Interval[start of HFC."Measurement Period" - 9 years, end of HFC."Measurement Period")

/*
This library evaluates with respect to exactly 1 candidate patient at a time,
that patient being given by the special context parameter Patient.
*/

context Patient

/*
Eligible Population
Product lines -- Commercial, Medicare (report each product line separately).
*/

define "Is In Eligible Population":
	"Is Age 51 to 75 at End"
		and (not HFC."Is In Hospice")
		and HFC."Is In Applicable Product Line"

define "Is Age 51 to 75 at End":
	AgeInYearsAt(end of HFC."Measurement Period") between 51 and 75


/*
Administrative Specification
*/

define "Is In Denominator":
	"Is In Eligible Population"

define "Is In Numerator":
	"Is In Eligible Population"
		and "Is Colorectal Cancer Screening"

define "Is Colorectal Cancer Screening":
	"Is Fecal Occult Blood Test In Last Year"
		or "Is Flexible Sigmoidoscopy In Last Five Years"
		or "Is Colonoscopy In Last Ten Years"
		or "Is CT Colonography In Last Five Years"
		or "Is FIT-DNA Test In Last Three Years"

define "Is Fecal Occult Blood Test In Last Year":
	exists(
		[Observation: "FOBT Value Set"] Obs
			where Obs.status.value in { 'final', 'amended' }
				and IncludedIn(HFC.ChoiceToIntervalOfDT(Obs.effective), HFC."Measurement Period")
	)

define "Is Flexible Sigmoidoscopy In Last Five Years":
	exists(
		[DiagnosticReport: "Flexible Sigmoidoscopy Value Set"] DiagRep
			where DiagRep.status.value in { 'final', 'appended', 'corrected' }
				and IncludedIn(HFC.ChoiceToIntervalOfDT(DiagRep.effective), "Lookback Interval Four More Years")
	)

define "Is Colonoscopy In Last Ten Years":
	exists(
		[DiagnosticReport: "Colonoscopy Value Set"] DiagRep
			where DiagRep.status.value in { 'final', 'appended', 'corrected' }
				and IncludedIn(HFC.ChoiceToIntervalOfDT(DiagRep.effective), "Lookback Interval Nine More Years")
	)

define "Is CT Colonography In Last Five Years":
	exists(
		[DiagnosticReport: "CT Colonography Value Set"] DiagRep
			where DiagRep.status.value in { 'final', 'appended', 'corrected' }
				and IncludedIn(HFC.ChoiceToIntervalOfDT(DiagRep.effective), "Lookback Interval Four More Years")
	)

define "Is FIT-DNA Test In Last Three Years":
	exists(
		[Observation: "FIT-DNA Value Set"] Obs
			where Obs.status.value in { 'final', 'amended' }
				and IncludedIn(HFC.ChoiceToIntervalOfDT(Obs.effective), "Lookback Interval Two More Years")
	)

define "Is In Administrative Exclusions":
	"Is Colorectal Cancer"
		or "Is Total Colectomy"

define "Is Colorectal Cancer":
	exists(
		[Condition: "Colorectal Cancer Value Set"] Cond
			where Cond.verificationStatus.value = 'confirmed'
				and Cond.assertedDate.value before end of HFC."Measurement Period"
	)

define "Is Total Colectomy":
	exists(
		[Procedure: "Total Colectomy Value Set"] Proc
			where Proc.status.value = 'completed'
				and end of HFC.ChoiceToIntervalOfDT(Proc.performed) before end of HFC."Measurement Period"
	)

/*
Hybrid Specification
TODO, if needed
*/
