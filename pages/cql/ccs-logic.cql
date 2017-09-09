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

valueset "Absence of Cervix Value Set": '2.16.840.1.113883.3.464.1004.1123.17' // CPT
// valueset "Absence of Cervix Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1123.18' // ICD10CM
// valueset "Absence of Cervix Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1123.19' // ICD10PCS
// valueset "Absence of Cervix Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1123.20' // ICD9CM
// valueset "Absence of Cervix Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1123.21' // ICD9CMProc

valueset "Cervical Cytology Value Set": '2.16.840.1.113883.3.464.1004.1208.22' // CPT
// valueset "Cervical Cytology Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1208.23' // HCPCS
// valueset "Cervical Cytology Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1208.24' // LOINC
// valueset "Cervical Cytology Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1208.25' // RevCode

valueset "HPV Tests Value Set": '2.16.840.1.113883.3.464.1004.1265.26' // CPT
// valueset "HPV Tests Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1265.27' // HCPCS
// valueset "HPV Tests Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1265.28' // LOINC

/*
valueset "Hospice Value Set": 'TODO'

valueset "Encounter Inpatient": 'urn:oid:2.16.840.1.113883.3.666.5.307' version 'urn:hl7:version:eCQM%20Update%202017-05-05'
valueset "Discharged to Home for Hospice Care": 'urn:oid:2.16.840.1.113883.3.117.1.7.1.209' version 'urn:hl7:version:eCQM%20Update%202017-05-05'
valueset "Discharged to Health Care Facility for Hospice Care": 'urn:oid:2.16.840.1.113883.3.117.1.7.1.207' version 'urn:hl7:version:eCQM%20Update%202017-05-05'
valueset "Hospice care ambulatory": 'urn:oid:2.16.840.1.113762.1.4.1108.15' version 'urn:hl7:version:eCQM%20Update%202017-05-05'

valueset "X Commercial Coverage Value Set": 'TODO'
valueset "X Medicaid Coverage Value Set": 'TODO'
valueset "X Medicare Coverage Value Set": 'TODO'

valueset "X Institutional SNP Value Set": 'TODO'
valueset "X Long-Term in Institution Value Set": 'TODO'
*/

/*
This library has an explicit parameter which is the product line.
Recognized normal arguments are {'commercial', 'medicaid', 'medicare'}.
If one of these normal arguments is given, the patient will only be
considered to be in the Initial Population if they have an appropriate
continuous enrollment in that kind of medical plan.
If instead a null argument is given, their enrollment status will have no
effect on whether they are considered to be in the Initial Population.
If instead some other argument is given (an unrecognized plan type),
the patient will unconditionally NOT be in the Initial Population.
*/

parameter "Product Line" String

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

define "Second Predecessor Year":
	Interval[start of "Measurement Period" - 2 years, start of "Measurement Period" - 1 year)

define "Third Predecessor Quarter":
	Interval[start of "Measurement Period" - 2 years - 3 months, start of "Measurement Period" - 2 years)

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
Initial Population
Product lines -- Commercial, Medicaid, Medicare (report each product line separately).
*/

define "Initial Population":
	"Is Female"
		and "Is Age 24 to 64 at End"
/*
		and (not "Is In Hospice")
		and "Is In Applicable Product Line"
*/

define "Is Female":
	Patient.gender.value = 'female'

define "Is Age 24 to 64 at End":
	AgeInYearsAt(end of "Measurement Period") between 24 and 64

/*
define "Is In Hospice":
	exists(
		[Encounter: "Hospice Value Set"] Enc
			where Enc.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and PeriodToIntervalOfDT(Enc.period) overlaps "Measurement Period"
	)
	or
	exists(
		[Encounter: "Encounter Inpatient"] DischargeHospice
			where DischargeHospice.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and (CodingToCode(DischargeHospice.hospitalization.dischargeDisposition.coding)
						in "Discharged to Home for Hospice Care"
					or CodingToCode(DischargeHospice.hospitalization.dischargeDisposition.coding)
						in "Discharged to Health Care Facility for Hospice Care")
				and PeriodToIntervalOfDT(DischargeHospice.period) ends during "Measurement Period"
	)
	or
	exists(
		[ProcedureRequest: "Hospice care ambulatory"] HospiceOrder
			where HospiceOrder.status.value in { 'active', 'completed' }
				and HospiceOrder.authoredOn.value during "Measurement Period"
	)
	or
	exists(
		[Procedure: "Hospice care ambulatory"] HospicePerformed
			where HospicePerformed.status.value = 'completed'
				and ChoiceToIntervalOfDT(HospicePerformed.performed) overlaps "Measurement Period"
	)

define "Is In Applicable Product Line":
	case
		when ("Product Line" ~ null) then true
		when ("Product Line" = 'commercial') then "Is Continuous Enrollment"
		when ("Product Line" = 'medicaid') then "Is Continuous Enrollment"
		when ("Product Line" = 'medicare') then
			("Is Continuous Enrollment"
				and (if "Is Age 65 Plus at Start"
					then ("Is Enrolled in Institutional SNP"
						or "Is Living Long-Term in Institution")
					else false))
		else false
	end

define "Enrollment Periods":
	collapse(
		[Coverage] Cov
			where Cov.status.value in { 'active', 'cancelled' }
				and case "Product Line"
					when 'commercial' then
						CodingToCode(Cov.type.coding) in "X Commercial Coverage Value Set"
					when 'medicaid' then
						CodingToCode(Cov.type.coding) in "X Medicaid Coverage Value Set"
					when 'medicare' then
						CodingToCode(Cov.type.coding) in "X Medicare Coverage Value Set"
					else false
				end
			return PeriodToIntervalOfDT(Cov.period)
	)
	// We assume [Coverage] in Patient context implicitly has this filter:
	// Cov.beneficiary.identifier ~ Patient.identifier
	// ... and that the paitient is not connected as a policy holder or payor.
	// TODO: Properly determine organization(s) for the product line.
	// Note: collapse() also puts the resulting intervals in order.

define function "Enrollment Periods In Year"(Year Interval<DateTime>):
	"Enrollment Periods" EnrP
		where EnrP overlaps Year
		return EnrP intersect Year

define function "Is Continuous Enrollment In Year"(Year Interval<DateTime>):
	case Count("Enrollment Periods In Year"(Year))
		when 1 then (
			(("Enrollment Periods In Year"(Year)[0] starts Year)
				and ((difference in days between
						end of "Enrollment Periods In Year"(Year)[0]
						and end of Year
					) <= 45))
			or
			(("Enrollment Periods In Year"(Year)[0] ends Year)
				and ((difference in days between
						start of "Enrollment Periods In Year"(Year)[0]
						and start of Year
					) <= 45))
		)
		when 2 then (
			("Enrollment Periods In Year"(Year)[0] starts Year)
				and ("Enrollment Periods In Year"(Year)[1] ends Year)
				and ((difference in days between
						end of "Enrollment Periods In Year"(Year)[0]
						and start of "Enrollment Periods In Year"(Year)[1]
					) <= 45)
		)
		else false
	end

define function "Is Continuous Enrollment In Quarter"(Quarter Interval<DateTime>):
	case Count("Enrollment Periods In Year"(Quarter))
		when 1 then ("Enrollment Periods In Year"(Quarter)[0] = Quarter)
		else false
	end

define "Is Continuous Enrollment":
	"Is Continuous Enrollment In Year"("Measurement Period")
		and "Is Continuous Enrollment In Year"("First Predecessor Year")
		and "Is Continuous Enrollment In Year"("Second Predecessor Year")
		and "Is Continuous Enrollment In Quarter"("Third Predecessor Quarter")

define "Is Age 65 Plus at Start":
	AgeInYearsAt(start of "Measurement Period") >= 65

define "Is Enrolled in Institutional SNP":
	exists(
		[Encounter: "X Institutional SNP Value Set"] Enc
			where Enc.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and PeriodToIntervalOfDT(Enc.period) overlaps "Measurement Period"
	)
	// TODO: Determine properly whether the patient was in SNP during the measurement year.

define "Is Living Long-Term in Institution":
	exists(
		[Encounter: "X Long-Term in Institution Value Set"] Enc
			where Enc.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and PeriodToIntervalOfDT(Enc.period) overlaps "Measurement Period"
	)
	// TODO: Determine properly whether the patient was in LTI during the measurement year.
*/

/*
Administrative Specification
*/

define "Denominator":
	"Initial Population"

define "Numerator":
	case
		when (not "Initial Population") then false
		when "Is Cervical Cytology Test In Last 3 Years" then true
		when (not "Is Age 30 to 64 at End") then false
		when "Is Cervical Cytology Plus HPV Test In Last 5 Years" then true
		else false
	end

define "Is Age 30 to 64 at End":
	AgeInYearsAt(end of "Measurement Period") between 30 and 64

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
		return ChoiceToIntervalOfDT(Proc.performed))
	union
	([DiagnosticReport: "Cervical Cytology Value Set"] DiagRep
		where DiagRep.status.value in { 'final', 'appended', 'corrected' }
		return ChoiceToIntervalOfDT(DiagRep.effective))
	union
	([Observation: "Cervical Cytology Value Set"] Obs
		where Obs.status.value in { 'final', 'amended' }
		return ChoiceToIntervalOfDT(Obs.effective))

define "Dates of HPV Tests":
	([Procedure: "HPV Tests Value Set"] Proc
		where Proc.status.value = 'completed'
		return ChoiceToIntervalOfDT(Proc.performed))
	union
	([DiagnosticReport: "HPV Tests Value Set"] DiagRep
		where DiagRep.status.value in { 'final', 'appended', 'corrected' }
		return ChoiceToIntervalOfDT(DiagRep.effective))
	union
	([Observation: "HPV Tests Value Set"] Obs
		where Obs.status.value in { 'final', 'amended' }
		return ChoiceToIntervalOfDT(Obs.effective))

define "Denominator Exclusion":
	"Initial Population"
		and "Is Hysterectomy"

define "Is Hysterectomy":
	exists(
		[Procedure: "Absence of Cervix Value Set"] Proc
			where Proc.status.value = 'completed'
				and end of ChoiceToIntervalOfDT(Proc.performed) before end of "Measurement Period"
	)

/*
Hybrid Specification
TODO, if needed
*/


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
