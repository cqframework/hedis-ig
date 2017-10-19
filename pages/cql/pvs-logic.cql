/*
Pneumococcal Vaccination Status of Older Adults (PVS)
*/

library PVS_FHIR version '1.0.0'

//using FHIR version '3.0.1'
using FHIR version '3.0.0'

/*
Measure Description
The percentage of members 65 years of age and older who have ever received
the recommended series of pneumococcal vaccines: 13-valent pneumococcal
conjugate vaccine (PCV13) and 23-valent pneumococcal polysaccharide vaccine (PPSV23).
*/

// valueset "Anaphylactic Reaction Due to Vaccine": 'urn:oid:2.16.840.1.113883.3.464.1003.199.12.1027' // Grouping Value Set
// valueset "Cerebrospinal Fluid Leaks": 'urn:oid:1.1.1.1' // User Defined QDM Value Set
// valueset "Functional or Aplastic Anemia": 'urn:oid:1.1.1.1' // User Defined QDM Value Set
// valueset "Disorders of the Immune System": 'urn:oid:1.1.1.1' // User Defined QDM Value Set
// valueset "Pneumococcal Conjugate Vaccine 13": 'urn:oid:1.1.1.1' // User Defined QDM Value Set
// valueset "Pneumococcal Conjugate Vaccine 23": 'urn:oid:1.1.1.1' // User Defined QDM Value Set
// valueset "Bone Marrow Transplant": 'urn:oid:2.16.840.1.113883.3.666.5.336' // Grouping Value Set
// valueset "Chemotherapy": 'urn:oid:2.16.840.1.113762.1.4.1047.451' // Grouping Value Set
// valueset "Cochlear Implants": 'urn:oid:1.1.1.1' // User Defined QDM Value Set

// update
valueset "Anaphylactic Reaction Due to Serum": '2.16.840.1.113883.3.464.1004.1023'
valueset "Anaphylactic Reaction Due to Vaccine": '2.16.840.1.113883.3.464.1004.1024'
valueset "Bone Marrow Transplant": '2.16.840.1.113883.3.464.1004.1325'
valueset "Bone Marrow Transplant SNOMED": '2.16.840.1.113883.3.464.1004.1442'
valueset "Cerebrospinal Fluid Leaks": '2.16.840.1.113883.3.464.1004.1448'
valueset "Chemotherapy": '2.16.840.1.113883.3.464.1004.1326'
valueset "Chemotherapy SNOMED/CPT": '2.16.840.1.113883.3.464.1004.1441'
valueset "Cochlear Implants": '2.16.840.1.113883.3.464.1004.1447'
valueset "Disorders of the Immune System": '2.16.840.1.113883.3.464.1004.1139'
valueset "Functional or Aplastic Anemia": '2.16.840.1.113883.3.464.1004.1449'
valueset "Hospice": '2.16.840.1.113883.3.464.1004.1418'
valueset "Pneumococcal Conjugate Vaccine 13": '2.16.840.1.113883.3.464.1004.1439'
valueset "Pneumococcal Conjugate Vaccine 23": '2.16.840.1.113883.3.464.1004.1440'

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
	AgeInYearsAt(start of "Measurement Period") >= 65

/*
Exclusions
*/

define "Denominator Exclusion":
	exists (
		"Chemotherapy and Bone Marrow Transplant Procedures" ProcedureUnion
			where ProcedureUnion.status.value in { 'in-progress', 'completed' }
				and PeriodToIntervalOfDT(ProcedureUnion.performed) overlaps "Measurement Period"
	)
	or
	exists (
		[DiagnosticReport: "Anaphylactic Reaction Due to Vaccine"] ReactionToVaccine
			where ReactionToVaccine.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and ReactionToVaccine.effective.value before day of "Measurement Period"
	)

define "Chemotherapy and Bone Marrow Transplant Procedures":
	[Procedure: "Chemotherapy"]
	union
	[Procedure: "Bone Marrow Transplant"]

/*
Denominators and Numerators
*/

define "Denominator":
	"Initial Population"

// TODO: The Numerator logic in the spec appears to have contradictions
// with the intent of the spec, such as AND meaning union vs intersection;
// this logic should be given another review.

define "Numerator":
	"Initial Population"
	and
	(
		"PVC13 After Age 60 And Then PVC23 After 12 More Months"
		or
		"PVC13 After Age 2 And Then PVC23 After 8 More Weeks"
	)

define "PVC13 After Age 60 And Then PVC23 After 12 More Months":
	exists (
		"Pneumococcal Vaccine 13 After Age 60" V13
			with "Pneumococcal Vaccine 23 After Age 60" V23
				such that months between V13."date".value and V23."date".value >= 12
	)

define "Pneumococcal Vaccine 13 After Age 60":
	[Immunization: "Pneumococcal Conjugate Vaccine 13"] V13
		where V13.status.value in { 'in-progress', 'completed' }
			and AgeInYearsAt(V13."date".value) >= 60

define "Pneumococcal Vaccine 23 After Age 60":
	[Immunization: "Pneumococcal Conjugate Vaccine 23"] V23
		where V23.status.value in { 'in-progress', 'completed' }
			and AgeInYearsAt(V23."date".value) >= 60

define "PVC13 After Age 2 And Then PVC23 After 8 More Weeks":
	"Immunocompromised Diagnoses or Cochlear Implants"
	and
	exists (
		"Pneumococcal Vaccine 13 After Age 2" V13
			with "Pneumococcal Vaccine 23 After Age 2" V23
				such that weeks between V13."date".value and V23."date".value >= 8
	)

define "Pneumococcal Vaccine 13 After Age 2":
	[Immunization: "Pneumococcal Conjugate Vaccine 13"] V13
		where V13.status.value in { 'in-progress', 'completed' }
			and AgeInYearsAt(V13."date".value) >= 2

define "Pneumococcal Vaccine 23 After Age 2":
	[Immunization: "Pneumococcal Conjugate Vaccine 23"] V23
		where V23.status.value in { 'in-progress', 'completed' }
			and AgeInYearsAt(V23."date".value) >= 2

define "Immunocompromised Diagnoses or Cochlear Implants":
	exists ("Immunocompromised Diagnoses Overlapping Measurement Period")
		or exists ("Cochlear Implants on or Before End of Measurement Period")

define "Immunocompromised Diagnoses Overlapping Measurement Period":
	distinct (
		[DiagnosticReport: "Cerebrospinal Fluid Leaks"]
		union [DiagnosticReport: "Functional or Aplastic Anemia"]
		union [DiagnosticReport: "Disorders of the Immune System"]
	) D
		where D.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
			and D.effective.value in "Measurement Period"

define "Cochlear Implants on or Before End of Measurement Period":
	[Procedure: "Cochlear Implants"] CochlearImplant
		where CochlearImplant.status.value in { 'in-progress', 'completed' }
			and start of PeriodToIntervalOfDT(CochlearImplant.performed) same day or before end of "Measurement Period"

/*
Stratifiers
*/

define "Stratifier 1":
	AgeInYearsAt(start of "Measurement Period") in Interval[65, 74]

define "Stratifier 2":
	AgeInYearsAt(start of "Measurement Period") in Interval[75, 84]

define "Stratifier 3":
	AgeInYearsAt(start of "Measurement Period") >= 85

/*
Utility Functions
*/

define function PeriodToIntervalOfDT(value FHIR.Period):
	Interval[value."start".value, value."end".value]
