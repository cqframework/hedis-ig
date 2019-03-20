

library BCS_CDS_Logic version '0.0.0'

using FHIR version '3.0.0'

include BCS_Common_Logic version '0.0.0' called Common

context Patient

// NOTE: Using 50 to make the decision support prospective
define "Needs Screening":
  (AgeInYears() >= 50 and AgeInYears() < 75
   or (AgeInYears() >= 40 and AgeInYears() < 75 and Common."Has BRACA Mutation Indicators"))
   and not (
		(Common."Is Lacking Both Breasts"
			or (Common."Is Lacking Left Breast"
				and Common."Is Lacking Right Breast"))
   )
   and not(Common."Has Mammogram in Last 36 Months") // Need to back off 3 months to allow for scheduling...

