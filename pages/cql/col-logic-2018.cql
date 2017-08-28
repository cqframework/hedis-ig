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

valueset "Hospice Value Set": 'TODO'

valueset "X Institutional SNP Value Set": 'TODO'
valueset "X Long-Term in Institution Value Set": 'TODO'

/*
This library has an explicit parameter which is the product line.
Recognized normal arguments are {'commercial', 'medicare'}.
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
		and "Is In Applicable Product Line"

define "Is Age 51 to 75 at End":
	AgeInYearsAt(end of "Measurement Period") between 51 and 75

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
				and IncludedIn(ChoiceToIntervalOfDT(Obs.effective), "Measurement Period")
	)

define "Is Flexible Sigmoidoscopy In Last Five Years":
	exists(
		[DiagnosticReport: "Flexible Sigmoidoscopy Value Set"] DiagRep
			where DiagRep.status.value in { 'final', 'appended', 'corrected' }
				and IncludedIn(ChoiceToIntervalOfDT(DiagRep.effective), "Lookback Interval Four More Years")
	)

define "Is Colonoscopy In Last Ten Years":
	exists(
		[DiagnosticReport: "Colonoscopy Value Set"] DiagRep
			where DiagRep.status.value in { 'final', 'appended', 'corrected' }
				and IncludedIn(ChoiceToIntervalOfDT(DiagRep.effective), "Lookback Interval Nine More Years")
	)

define "Is CT Colonography In Last Five Years":
	exists(
		[DiagnosticReport: "CT Colonography Value Set"] DiagRep
			where DiagRep.status.value in { 'final', 'appended', 'corrected' }
				and IncludedIn(ChoiceToIntervalOfDT(DiagRep.effective), "Lookback Interval Four More Years")
	)

define "Is FIT-DNA Test In Last Three Years":
	exists(
		[Observation: "FIT-DNA Value Set"] Obs
			where Obs.status.value in { 'final', 'amended' }
				and IncludedIn(ChoiceToIntervalOfDT(Obs.effective), "Lookback Interval Two More Years")
	)

define "Is In Administrative Exclusions":
	"Is Colorectal Cancer"
		or "Is Total Colectomy"

define "Is Colorectal Cancer":
	exists(
		[Condition: "Colorectal Cancer Value Set"] Cond
			where Cond.verificationStatus.value = 'confirmed'
				and Cond.assertedDate.value before end of "Measurement Period"
	)

define "Is Total Colectomy":
	exists(
		[Procedure: "Total Colectomy Value Set"] Proc
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
