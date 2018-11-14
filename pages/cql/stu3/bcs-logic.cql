/*
Breast Cancer Screening (BCS)
*/

library BCS_FHIR version '1.0.1'

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

//include Participation version '1.0.0' called Participation

/*
Description
The percentage of women 50-74 years of age who had a mammogram to screen for breast cancer.
*/

valueset "Absence of Left Breast Value Set": '2.16.840.1.113883.3.464.1004.1329.1' // ICD10CM
valueset "Absence of Right Breast Value Set": '2.16.840.1.113883.3.464.1004.1330.2' // ICD10CM

valueset "Bilateral Mastectomy Value Set": '2.16.840.1.113883.3.464.1004.1042' // Grouping
// valueset "Bilateral Mastectomy Value Set": '2.16.840.1.113883.3.464.1004.1042.3' // ICD10PCS
// valueset "Bilateral Mastectomy Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1042.4' // ICD9CMProc

valueset "Bilateral Modifier Value Set": '2.16.840.1.113883.3.464.1004.1043.5' // CPT-Mod
valueset "History of Bilateral Mastectomy Value Set": '2.16.840.1.113883.3.464.1004.1331.6' // ICD10CM
valueset "Left Modifier Value Set": '2.16.840.1.113883.3.464.1004.1148.7' // CPT-Mod

valueset "Mammography Value Set": '2.16.840.1.113883.3.464.1004.1168' // Grouping
// valueset "Mammography Value Set": '2.16.840.1.113883.3.464.1004.1168.8' // CPT
// valueset "Mammography Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1168.9' // HCPCS
// valueset "Mammography Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1168.10' // ICD9CMProc
// valueset "Mammography Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1168.11' // RevCode

valueset "Right Modifier Value Set": '2.16.840.1.113883.3.464.1004.1230.12' // CPT-Mod

valueset "Unilateral Mastectomy Value Set": '2.16.840.1.113883.3.464.1004.1256' // Grouping
// valueset "Unilateral Mastectomy Value Set": '2.16.840.1.113883.3.464.1004.1256.13' // CPT
// valueset "Unilateral Mastectomy Value Set": 'urn:oid:2.16.840.1.113883.3.464.1004.1256.14' // ICD9CMProc

valueset "Unilateral Mastectomy Left Value Set": '2.16.840.1.113883.3.464.1004.1334.15' // ICD10PCS
valueset "Unilateral Mastectomy Right Value Set": '2.16.840.1.113883.3.464.1004.1335.16' // ICD10PCS

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
calendar year, and it will not behave properly otherwise; 2017 for example:
Interval[DateTime(2017,1,1,0,0,0,0), DateTime(2018,1,1,0,0,0,0))
*/

parameter "Measurement Period" Interval<DateTime>

define "Lookback Interval 27 More Months":
	Interval[start of "Measurement Period" - 27 months, end of "Measurement Period")

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
		and "Is Age 52 to 74 at End"
/*
		and (not "Is In Hospice")
		and Participation."Is Enrolled"(
			"Product Line", 
			start of "Measurement Period", 
			Interval[start of "Measurement Period" - 27 months, end of "Measurement Period"],
			45
		)
*/

define "Is Female":
	Patient.gender.value = 'female'

define "Is Age 52 to 74 at End":
	CalendarAgeInYearsAt(Patient.birthDate.value, end of "Measurement Period") between 52 and 74

/*
define "Is In Hospice":
	exists(
		[Encounter: "Hospice Value Set"] Enc
			where Enc.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and PeriodToIntervalOfDT(Enc.period) overlaps day of "Measurement Period"
	)
	or
	exists(
		[Claim: "Hospice Value Set"] Clm
			where Clm.status.value in { 'active', 'draft' }
				and PeriodToIntervalOfDT(Clm.item.service.period) overlaps day of "Measurement Period"
	)
	or
	exists(
		[Encounter: "Encounter Inpatient"] DischargeHospice
			where DischargeHospice.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and (CodingToCode(DischargeHospice.hospitalization.dischargeDisposition.coding)
						in "Discharged to Home for Hospice Care"
					or CodingToCode(DischargeHospice.hospitalization.dischargeDisposition.coding)
						in "Discharged to Health Care Facility for Hospice Care")
				and PeriodToIntervalOfDT(DischargeHospice.period) ends during day of "Measurement Period"
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
			where HospicePerformed.status.value in { 'preparation', 'in-progress', 'suspended', 'aborted', 'completed' }
				and date form PeriodToIntervalOfDT(HospicePerformed.performed) overlaps day of "Measurement Period"
	)
*/

/*
Administrative Specification
*/

define "Denominator":
    // was "Initial Population", but that will always be true if this expression is executed
	true

define "Numerator":
	"Is Mammogram In Last 39 Months"

define "Is Mammogram In Last 39 Months":
	exists(
		[Procedure: "Mammography Value Set"] Proc
			where Proc.status.value = 'completed'
				and PeriodToIntervalOfDT(Proc.performed) included in day of "Lookback Interval 27 More Months"
	)

define "Denominator Exclusion":
	("Is Lacking Both Breasts"
			or ("Is Lacking Left Breast"
				and "Is Lacking Right Breast"))

define "Is Lacking Both Breasts":
	"Is Bilateral Mastectomy"
		or "Is History Of Bilateral Mastectomy"
		or "Is Unilateral Mastectomy With Bilateral Modifier"
		or "Is Unilateral Mastectomy Twice Spread Two Weeks"

define "Is Lacking Left Breast":
	"Is Unilateral Mastectomy With Left Modifier"
		or "Is Unilateral Mastectomy Left"
		or "Is Absence Of Left Breast"

define "Is Lacking Right Breast":
	"Is Unilateral Mastectomy With Right Modifier"
		or "Is Unilateral Mastectomy Right"
		or "Is Absence Of Right Breast"

define "Is Bilateral Mastectomy":
	exists(
		[Procedure: "Bilateral Mastectomy Value Set"] Proc
			where Proc.status.value = 'completed'
				and end of PeriodToIntervalOfDT(Proc.performed) same day or before end of "Measurement Period"
	)

define "Is History Of Bilateral Mastectomy":
	exists(
		[Condition: "History of Bilateral Mastectomy Value Set"] Cond
			where Cond.verificationStatus.value = 'confirmed'
				and Cond.assertedDate.value same day or before end of "Measurement Period"
	)

define "Is Unilateral Mastectomy With Bilateral Modifier":
	exists(
		[Claim] Claim
			where Claim.status.value = 'active'
				and exists(
				Claim.procedure BbElem
					with (
						[Procedure: "Unilateral Mastectomy Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of PeriodToIntervalOfDT(Proc.performed) same day or before end of "Measurement Period"
					) Proc1
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier ~ Proc1.identifier
								else false)
					with (
						[Procedure: "Bilateral Modifier Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of PeriodToIntervalOfDT(Proc.performed) same day or before end of "Measurement Period"
					) Proc2
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier ~ Proc2.identifier
								else false)
			)
	)

define "Is Unilateral Mastectomy Twice Spread Two Weeks":
	exists(
		(
			[Procedure: "Unilateral Mastectomy Value Set"] Proc
				where Proc.status.value = 'completed'
				return PeriodToIntervalOfDT(Proc.performed)
		) WhenUM1
			with (
				[Procedure: "Unilateral Mastectomy Value Set"] Proc
					where Proc.status.value = 'completed'
					return PeriodToIntervalOfDT(Proc.performed)
			) WhenUM2
				such that (((difference in days between start of WhenUM1 and start of WhenUM2) >= 14)
					and end of WhenUM1 same day or before end of "Measurement Period"
					and end of WhenUM2 same day or before end of "Measurement Period")
	)

define "Is Unilateral Mastectomy With Left Modifier":
	exists(
		[Claim] Claim
			where Claim.status.value = 'active'
				and exists(
				Claim.procedure BbElem
					with (
						[Procedure: "Unilateral Mastectomy Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of PeriodToIntervalOfDT(Proc.performed) same day or before end of "Measurement Period"
					) Proc1
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier ~ Proc1.identifier
								else false)
					with (
						[Procedure: "Left Modifier Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of PeriodToIntervalOfDT(Proc.performed) same day or before end of "Measurement Period"
					) Proc2
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier ~ Proc2.identifier
								else false)
			)
	)

define "Is Unilateral Mastectomy Left":
	exists(
		[Procedure: "Unilateral Mastectomy Left Value Set"] Proc
			where Proc.status.value = 'completed'
				and end of PeriodToIntervalOfDT(Proc.performed) same day or before end of "Measurement Period"
	)

define "Is Absence Of Left Breast":
	exists(
		[Observation: "Absence of Left Breast Value Set"] Obs
			where Obs.status.value in { 'final', 'amended' }
				and Obs.effective.value same day or before end of "Measurement Period"
	)

define "Is Unilateral Mastectomy With Right Modifier":
	exists(
		[Claim] Claim
			where Claim.status.value = 'active'
				and exists(
				Claim.procedure BbElem
					with (
						[Procedure: "Unilateral Mastectomy Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of PeriodToIntervalOfDT(Proc.performed) same day or before end of "Measurement Period"
					) Proc1
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier ~ Proc1.identifier
								else false)
					with (
						[Procedure: "Right Modifier Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of PeriodToIntervalOfDT(Proc.performed) same day or before end of "Measurement Period"
					) Proc2
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier ~ Proc2.identifier
								else false)
			)
	)

define "Is Unilateral Mastectomy Right":
	exists(
		[Procedure: "Unilateral Mastectomy Right Value Set"] Proc
			where Proc.status.value = 'completed'
				and end of PeriodToIntervalOfDT(Proc.performed) same day or before end of "Measurement Period"
	)

define "Is Absence Of Right Breast":
	exists(
		[Observation: "Absence of Right Breast Value Set"] Obs
			where Obs.status.value in { 'final', 'amended' }
				and end of PeriodToIntervalOfDT(Obs.effective) same day or before end of "Measurement Period"
	)


/*
Utility Functions
*/

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

define function "ToDate"(Value DateTime):
	DateTime(year from Value, month from Value, day from Value, 0, 0, 0, 0, timezone from Value)

define function CalendarAgeInYearsAt(BirthDateTime DateTime, AsOf DateTime):
    years between ToDate(BirthDateTime)and ToDate(AsOf)