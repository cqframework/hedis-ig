/*
Breast Cancer Screening (BCS)
*/

library BCS_FHIR version '2.0.0'

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

include BCS_Common_Logic version '0.0.0' called Common

/*
Description
The percentage of women 50-74 years of age who had a mammogram to screen for breast cancer.
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
	Common."Is Female"
		and ("Is Age 52 to 74 at End"
      or "Is Age 42 to 74 at End and Has BRACA Mutation Results"
    )
/*
		and (not "Is In Hospice")
		and "Is In Applicable Product Line"
*/

define "Is Age 52 to 74 at End":
	AgeInYearsAt(end of "Measurement Period") between 52 and 74

define "Is Age 42 to 74 at End and Has BRACA Mutation Results":
  AgeInYearsAt(end of "Measurement Period") between 42 and 74
    and exists (Common."BRACA Mutation Observations")

/*
Administrative Specification
*/

define "Denominator":
	"Initial Population"

define "Numerator":
	Common."Is Mammogram In Last 39 Months"

define "Denominator Exclusion":
		(Common."Is Lacking Both Breasts"
			or (Common."Is Lacking Left Breast"
				and Common."Is Lacking Right Breast"))

/*
Utility Functions
*/

	// From FHIRHelpers
