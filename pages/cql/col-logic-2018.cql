/*
Colorectal Cancer Screening (COL)
*/

library COL_FHIR version '1.0.0'

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

/*
Description
The percentage of members 50–75 years of age who had appropriate screening for colorectal cancer.
*/

valueset "FOBT Value Set": 'TODO'
valueset "Flexible Sigmoidoscopy Value Set": 'TODO'
valueset "Colonoscopy Value Set": 'TODO'
valueset "CT Colonography Value Set": 'TODO'
valueset "FIT-DNA Value Set": 'TODO'

valueset "Colorectal Cancer Value Set": 'TODO'
valueset "Total Colectomy Value Set": 'TODO'

/*
This library has a single explicit parameter which is the measurement year.
While the actual parameter's type accepts all intervals, this library
expects it will only be given arguments corresponding exactly to one whole
calendar year, and it will not behave properly otherwise; 2015 for example:
Interval[DateTime(2015,1,1,0,0,0,0), DateTime(2016,1,1,0,0,0,0))
*/

parameter "Measurement Period" Interval<DateTime>

define "Lookback Interval Two More Years":
	Interval[start of "Measurement Period" - 2 years, end of "Measurement Period")

define "Lookback Interval Four More Years":
	Interval[start of "Measurement Period" - 4 years, end of "Measurement Period")

define "Lookback Interval Nine More Years":
	Interval[start of "Measurement Period" - 9 years, end of "Measurement Period")

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
		and (not "Is In Hospice")

define "Is Age 51 to 75 at End":
	AgeInYearsAt(end of "Measurement Period") between 51 and 75

define "Is In Hospice":
	false
	// TODO: Determine properly whether the patient was in hospice during the measurement year.

define "Is In Eligible Population Commercial":
	"Is In Eligible Population"
		and "Is Continuous Enrollment Commercial"

define "Is Continuous Enrollment Commercial":
	true
	// TODO: Determine continuous enrollment over the 2 year period consisting
	// of the measurement year plus the 1 prior year.
	// Allowable gap -- No more than one gap in enrollment of up to 45 days during
	// each year of continuous enrollment.
	// See http://hl7.org/fhir/enrollmentresponse.html which is currently
	// marked as a stub / draft / incomplete.

define "Is In Eligible Population Medicare":
	"Is In Eligible Population"
		and "Is Continuous Enrollment Medicare"
		and (if "Is Age 65 Plus at Start"
			then ("Is Enrolled in Institutional SNP"
				or "Is Living Long-Term in Institution")
			else false)

define "Is Continuous Enrollment Medicare":
	true
	// TODO: Determine continuous enrollment over the 2 year period consisting
	// of the measurement year plus the 1 prior year.
	// Allowable gap -- No more than one gap in enrollment of up to 45 days during
	// each year of continuous enrollment.
	// See http://hl7.org/fhir/enrollmentresponse.html which is currently
	// marked as a stub / draft / incomplete.

define "Is Age 65 Plus at Start":
	AgeInYearsAt(start of "Measurement Period") >= 65

define "Is Enrolled in Institutional SNP":
	false
	// TODO: Determine properly whether the patient was in SNP during the measurement year.

define "Is Living Long-Term in Institution":
	false
	// TODO: Determine properly whether the patient was in LTI during the measurement year.

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
				and (Obs.effective as dateTime).value during "Measurement Period"
	)

define "Is Flexible Sigmoidoscopy In Last Five Years":
	exists(
		[DiagnosticReport: "Flexible Sigmoidoscopy Value Set"] DiagRep
			where DiagRep.status.value in { 'final', 'appended', 'corrected' }
				and (DiagRep.effective as dateTime).value during "Lookback Interval Four More Years"
	)

define "Is Colonoscopy In Last Ten Years":
	exists(
		[DiagnosticReport: "Colonoscopy Value Set"] DiagRep
			where DiagRep.status.value in { 'final', 'appended', 'corrected' }
				and (DiagRep.effective as dateTime).value during "Lookback Interval Nine More Years"
	)

define "Is CT Colonography In Last Five Years":
	exists(
		[DiagnosticReport: "CT Colonography Value Set"] DiagRep
			where DiagRep.status.value in { 'final', 'appended', 'corrected' }
				and (DiagRep.effective as dateTime).value during "Lookback Interval Four More Years"
	)

define "Is FIT-DNA Test In Last Three Years":
	exists(
		[Observation: "FIT-DNA Value Set"] Obs
			where Obs.status.value in { 'final', 'amended' }
				and (Obs.effective as dateTime).value during "Lookback Interval Two More Years"
	)

define "Is In Administrative Exclusions":
	"Is Colorectal Cancer"
		or "Is Total Colectomy"

define "Is Colorectal Cancer":
	exists(
		[Condition: "Colorectal Cancer Value Set"] Cond
			where Cond.verificationStatus.value = 'confirmed'
				and (Cond.assertedDate as dateTime).value before end of "Measurement Period"
	)

define "Is Total Colectomy":
	exists(
		[Procedure: "Total Colectomy Value Set"] Proc
			where Proc.status.value = 'completed'
				and (Proc.performed as dateTime).value before end of "Measurement Period"
	)

/*
Hybrid Specification
TODO, if needed
*/
