/*
Breast Cancer Screening (BCS)
*/

library BCS_FHIR version '1.0.0'

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
The percentage of women 50–74 years of age who had a mammogram to screen for breast cancer.
*/

valueset "Mammography Value Set": 'TODO'

valueset "Bilateral Mastectomy Value Set": 'TODO'
valueset "Bilateral Modifier Value Set": 'TODO'
valueset "History of Bilateral Mastectomy Value Set": 'TODO'
valueset "Unilateral Mastectomy Value Set": 'TODO'
valueset "Absence of Left Breast Value Set": 'TODO'
valueset "Left Modifier Value Set": 'TODO'
valueset "Unilateral Mastectomy Left Value Set": 'TODO'
valueset "Absence of Right Breast Value Set": 'TODO'
valueset "Right Modifier Value Set": 'TODO'
valueset "Unilateral Mastectomy Right Value Set": 'TODO'

define "Lookback Interval 27 More Months":
	Interval[start of HFC."Measurement Period" - 27 months, end of HFC."Measurement Period")

/*
This library evaluates with respect to exactly 1 candidate patient at a time,
that patient being given by the special context parameter Patient.
*/

context Patient

/*
Eligible Population
Product lines -- Commercial, Medicaid, Medicare (report each product line separately).
*/

define "Is In Eligible Population":
	"Is Female"
		and "Is Age 52 to 74 at End"
		and (not HFC."Is In Hospice")
		and HFC."Is In Applicable Product Line"

define "Is Female":
	Patient.gender.value = 'female'

define "Is Age 52 to 74 at End":
	AgeInYearsAt(end of HFC."Measurement Period") between 52 and 74


/*
Administrative Specification
*/

define "Is In Denominator":
	"Is In Eligible Population"

define "Is In Numerator":
	"Is In Eligible Population"
		and "Is Mammogram In Last 39 Months"

define "Is Mammogram In Last 39 Months":
	exists(
		[Procedure: "Mammography Value Set"] Proc
			where Proc.status.value = 'completed'
				and IncludedIn(HFC.ChoiceToIntervalOfDT(Proc.performed), "Lookback Interval 27 More Months")
	)

define "Is In Administrative Exclusions":
	"Is Lacking Both Breasts"
		or ("Is Lacking Left Breast"
			and "Is Lacking Right Breast")

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
				and end of HFC.ChoiceToIntervalOfDT(Proc.performed) before end of HFC."Measurement Period"
	)

define "Is History Of Bilateral Mastectomy":
	exists(
		[Procedure: "History of Bilateral Mastectomy Value Set"] Proc
			where Proc.status.value = 'completed'
				and end of HFC.ChoiceToIntervalOfDT(Proc.performed) before end of HFC."Measurement Period"
	)
	// NOTE: This assumes the history of a procedure is also recorded as a procedure in FHIR

define "Is Unilateral Mastectomy With Bilateral Modifier":
	exists(
		[Claim] Claim
			where Claim.status.value = 'active'
				and exists(
				Claim.procedure BbElem
					with (
						[Procedure: "Unilateral Mastectomy Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of HFC.ChoiceToIntervalOfDT(Proc.performed) before end of HFC."Measurement Period"
					) Proc1
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier ~ Proc1.identifier
								else false)
					with (
						[Procedure: "Bilateral Modifier Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of HFC.ChoiceToIntervalOfDT(Proc.performed) before end of HFC."Measurement Period"
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
				return HFC.ChoiceToIntervalOfDT(Proc.performed)
		) WhenUM1
			with (
				[Procedure: "Unilateral Mastectomy Value Set"] Proc
					where Proc.status.value = 'completed'
					return HFC.ChoiceToIntervalOfDT(Proc.performed)
			) WhenUM2
				such that (((difference in days between start of WhenUM1 and start of WhenUM2) >= 14)
					and end of WhenUM1 before end of HFC."Measurement Period"
					and end of WhenUM2 before end of HFC."Measurement Period")
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
								and end of HFC.ChoiceToIntervalOfDT(Proc.performed) before end of HFC."Measurement Period"
					) Proc1
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier ~ Proc1.identifier
								else false)
					with (
						[Procedure: "Left Modifier Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of HFC.ChoiceToIntervalOfDT(Proc.performed) before end of HFC."Measurement Period"
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
				and end of HFC.ChoiceToIntervalOfDT(Proc.performed) before end of HFC."Measurement Period"
	)

define "Is Absence Of Left Breast":
	exists(
		[Observation: "Absence of Left Breast Value Set"] Obs
			where Obs.status.value in { 'final', 'amended' }
				and end of HFC.ChoiceToIntervalOfDT(Obs.effective) before end of HFC."Measurement Period"
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
								and end of HFC.ChoiceToIntervalOfDT(Proc.performed) before end of HFC."Measurement Period"
					) Proc1
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier ~ Proc1.identifier
								else false)
					with (
						[Procedure: "Right Modifier Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of HFC.ChoiceToIntervalOfDT(Proc.performed) before end of HFC."Measurement Period"
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
				and end of HFC.ChoiceToIntervalOfDT(Proc.performed) before end of HFC."Measurement Period"
	)

define "Is Absence Of Right Breast":
	exists(
		[Observation: "Absence of Right Breast Value Set"] Obs
			where Obs.status.value in { 'final', 'amended' }
				and end of HFC.ChoiceToIntervalOfDT(Obs.effective) before end of HFC."Measurement Period"
	)
