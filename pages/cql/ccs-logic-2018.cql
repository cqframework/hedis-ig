/*
Cervical Cancer Screening (CCS)
*/

library CCS_FHIR version '1.0.0'

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

/*
Description
The percentage of women 21–64 years of age who were screened for cervical
		cancer using either of the following criteria:
•	Women 21–64 years of age who had cervical cytology performed every 3 years.
•	Women 30–64 years of age who had cervical cytology/human papillomavirus
		(HPV) co-testing performed every 5 years.
*/

valueset "Cervical Cytology Value Set": 'TODO'
valueset "HPV Tests Value Set": 'TODO'
valueset "Absence of Cervix Value Set": 'TODO'

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
		and "Is Age 24 to 64"
		and "Is Not In Hospice"

define "Is Female":
	Patient.gender.value = 'female'

define "Is Age 24 to 64":
	AgeInYearsAt(end of "Measurement Period") between 24 and 64

define "Is Not In Hospice":
	true
	// TODO: Determine properly whether the patient was in hospice during the measurement year.

define "Is In Eligible Population Commercial":
	"Is In Eligible Population"
		and "Is Continuous Enrollment Commercial"

define "Is Continuous Enrollment Commercial":
	true
	// TODO: Determine continuous enrollment over the 3 year period consisting
	// of the measurement year plus the 2 prior years.
	// Allowable gap -- No more than one gap in enrollment of up to 45 days during
	// each year of continuous enrollment.
	// See http://hl7.org/fhir/enrollmentresponse.html which is currently
	// marked as a stub / draft / incomplete.

define "Is In Eligible Population Medicaid":
	"Is In Eligible Population"
		and "Is Continuous Enrollment Medicaid"

define "Is Continuous Enrollment Medicaid":
	true
	// TODO: Determine continuous enrollment over the measurement year.
	// Allowable gap -- No more than one gap in enrollment of up to 45 days during
	// each year of continuous enrollment. To determine continuous enrollment
	// for a Medicaid beneficiary for whom enrollment is verified monthly, the
	// member may not have more than a 1-month gap in coverage (i.e., a member
	// whose coverage lapses for 2 months [60 days] is not considered continuously enrolled).
	// See http://hl7.org/fhir/enrollmentresponse.html which is currently
	// marked as a stub / draft / incomplete.

/*
Administrative Specification
*/

define "Is In Denominator":
	"Is In Eligible Population"

define "Is In Numerator":
	case
		when (not "Is In Eligible Population") then false
		when "Is Cervical Cytology Test In Last 3 Years" then true
		when (not "Is Age 30 to 64") then false
		when "Is Cervical Cytology Plus HPV Test In Last 5 Years" then true
		else false
	end

define "Is Age 30 to 64":
	AgeInYearsAt(end of "Measurement Period") between 30 and 64

define "Is Cervical Cytology Test In Last 3 Years":
	exists(
		"Dates of Cervical Cytology Tests" WhenCC
			where WhenCC.value during "Lookback Interval Two More Years"
	)

define "Is Cervical Cytology Plus HPV Test In Last 5 Years":
	exists(
		"Dates of Cervical Cytology Tests" WhenCC
			with "Dates of HPV Tests" WhenHPV
				such that ((difference in days between WhenCC.value and WhenHPV.value) <= 4)
			where WhenCC.value during "Lookback Interval Four More Years"
	)

define "Dates of Cervical Cytology Tests":
	([Procedure: "Cervical Cytology Value Set"] Proc
		where Proc.status.value = 'completed'
		return Proc.performed)
	union
	([DiagnosticReport: "Cervical Cytology Value Set"] DiagRep
		where DiagRep.status.value = 'final'
		return DiagRep.effective)
	union
	([Observation: "Cervical Cytology Value Set"] Obs
		where Obs.status.value in { 'final', 'amended' }
		return Obs.effective)

define "Dates of HPV Tests":
	([Procedure: "HPV Tests Value Set"] Proc
		where Proc.status.value = 'completed'
		return Proc.performed)
	union
	([DiagnosticReport: "HPV Tests Value Set"] DiagRep
		where DiagRep.status.value = 'final'
		return DiagRep.effective)
	union
	([Observation: "HPV Tests Value Set"] Obs
		where Obs.status.value in { 'final', 'amended' }
		return Obs.effective)

define "Is In Denominator Exclusions":
	exists(
		[Procedure: "Cervical Cytology Value Set"] Proc
			where Proc.status.value = 'completed'
				and Proc.performed.value before end of "Measurement Period"
	)

/*
Hybrid Specification
TODO, if needed
*/
