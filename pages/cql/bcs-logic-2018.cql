/*
Breast Cancer Screening (BCS)
*/

library BCS_FHIR version '1.0.0'

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

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

valueset "Hospice Value Set": 'TODO'

valueset "X Institutional SNP Value Set": 'TODO'
valueset "X Long-Term in Institution Value Set": 'TODO'

/*
This library has an explicit parameter which is the product line.
Recognized normal arguments are {'commercial', 'medicaid', 'medicare'}.
If one of these normal arguments is given, the patient will only be
considered to be in the Eligible Population if they have an appropriate
continuous enrollment in that kind of medical plan.
If instead a null argument is given, their enrollment status will have no
effect on whether they are considered to be in the Eligible Population.
If instead some other argument is given (an unrecognized plan type),
the patient will unconditionally NOT be in the Eligible Population.
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

define "Lookback Interval 27 More Months":
	Interval[start of "Measurement Period" - 27 months, end of "Measurement Period")

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
		and (not "Is In Hospice")
		and "Is In Applicable Product Line"

define "Is Female":
	Patient.gender.value = 'female'

define "Is Age 52 to 74 at End":
	AgeInYearsAt(end of "Measurement Period") between 52 and 74

define "Is In Hospice":
	exists(
		[Encounter: "Hospice Value Set"] Enc
			where Enc.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and Overlaps(PeriodToIntervalOfDT(Enc.period), "Measurement Period")
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

define "Any Patient Coverage At Any Time":
	[Coverage] Cov
		where Cov.status.value in { 'active', 'cancelled' }
	// We assume [Coverage] in Patient context implicitly has this filter:
	// Cov.beneficiary.identifier = Patient.identifier
	// ... and that the paitient is not connected as a policy holder or payor.

define "Product Line Organizations":
	case "Product Line"
		when 'commercial' then
			[Organization] Org
				where Org.name.value not in { 'Medicaid', 'Medicare' }
		when 'medicaid' then
			[Organization] Org
				where Org.name.value in { 'Medicaid' }
		when 'medicare' then
			[Organization] Org
				where Org.name.value in { 'Medicare' }
		else List<FHIR.Organization> {}
	end
	// TODO: Properly determine organization(s) for the product line.

define "Enrollment Periods":
	collapse(
		"Any Patient Coverage At Any Time" Cov
			with "Product Line Organizations" Org
				such that
					(if Cov.payor is List<FHIR.Reference>
						then (Cov.payor as List<FHIR.Reference>).identifier = Org.identifier
						else false)
			return PeriodToIntervalOfDT(Cov.period)
	)
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
				and Overlaps(PeriodToIntervalOfDT(Enc.period), "Measurement Period")
	)
	// TODO: Determine properly whether the patient was in SNP during the measurement year.

define "Is Living Long-Term in Institution":
	exists(
		[Encounter: "X Long-Term in Institution Value Set"] Enc
			where Enc.status.value in { 'planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished' }
				and Overlaps(PeriodToIntervalOfDT(Enc.period), "Measurement Period")
	)
	// TODO: Determine properly whether the patient was in LTI during the measurement year.

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
				and IncludedIn(ChoiceToIntervalOfDT(Proc.performed), "Lookback Interval 27 More Months")
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
				and end of ChoiceToIntervalOfDT(Proc.performed) before end of "Measurement Period"
	)

define "Is History Of Bilateral Mastectomy":
	exists(
		[Procedure: "History of Bilateral Mastectomy Value Set"] Proc
			where Proc.status.value = 'completed'
				and end of ChoiceToIntervalOfDT(Proc.performed) before end of "Measurement Period"
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
								and end of ChoiceToIntervalOfDT(Proc.performed) before end of "Measurement Period"
					) Proc1
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier = Proc1.identifier
								else false)
					with (
						[Procedure: "Bilateral Modifier Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of ChoiceToIntervalOfDT(Proc.performed) before end of "Measurement Period"
					) Proc2
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier = Proc2.identifier
								else false)
			)
	)

define "Is Unilateral Mastectomy Twice Spread Two Weeks":
	exists(
		(
			[Procedure: "Unilateral Mastectomy Value Set"] Proc
				where Proc.status.value = 'completed'
				return ChoiceToIntervalOfDT(Proc.performed)
		) WhenUM1
			with (
				[Procedure: "Unilateral Mastectomy Value Set"] Proc
					where Proc.status.value = 'completed'
					return ChoiceToIntervalOfDT(Proc.performed)
			) WhenUM2
				such that (((difference in days between start of WhenUM1 and start of WhenUM2) >= 14)
					and end of WhenUM1 before end of "Measurement Period"
					and end of WhenUM2 before end of "Measurement Period")
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
								and end of ChoiceToIntervalOfDT(Proc.performed) before end of "Measurement Period"
					) Proc1
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier = Proc1.identifier
								else false)
					with (
						[Procedure: "Left Modifier Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of ChoiceToIntervalOfDT(Proc.performed) before end of "Measurement Period"
					) Proc2
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier = Proc2.identifier
								else false)
			)
	)

define "Is Unilateral Mastectomy Left":
	exists(
		[Procedure: "Unilateral Mastectomy Left Value Set"] Proc
			where Proc.status.value = 'completed'
				and end of ChoiceToIntervalOfDT(Proc.performed) before end of "Measurement Period"
	)

define "Is Absence Of Left Breast":
	exists(
		[Observation: "Absence of Left Breast Value Set"] Obs
			where Obs.status.value in { 'final', 'amended' }
				and end of ChoiceToIntervalOfDT(Obs.effective) before end of "Measurement Period"
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
								and end of ChoiceToIntervalOfDT(Proc.performed) before end of "Measurement Period"
					) Proc1
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier = Proc1.identifier
								else false)
					with (
						[Procedure: "Right Modifier Value Set"] Proc
							where Proc.status.value = 'completed'
								and end of ChoiceToIntervalOfDT(Proc.performed) before end of "Measurement Period"
					) Proc2
						such that
							(if BbElem.procedure is FHIR.Reference
								then (BbElem.procedure as FHIR.Reference).identifier = Proc2.identifier
								else false)
			)
	)

define "Is Unilateral Mastectomy Right":
	exists(
		[Procedure: "Unilateral Mastectomy Right Value Set"] Proc
			where Proc.status.value = 'completed'
				and end of ChoiceToIntervalOfDT(Proc.performed) before end of "Measurement Period"
	)

define "Is Absence Of Right Breast":
	exists(
		[Observation: "Absence of Right Breast Value Set"] Obs
			where Obs.status.value in { 'final', 'amended' }
				and end of ChoiceToIntervalOfDT(Obs.effective) before end of "Measurement Period"
	)


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
