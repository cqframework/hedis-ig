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

valueset "Anaphylactic Reaction to Pneumococcal Conjugate Vaccine": 'urn:oid:2.16.840.1.113883.3.464.1003.199.12.1027' // Grouping Value Set
valueset "Cerebrospinal Fluid Leaks": 'urn:oid:1.1.1.1' // User Defined QDM Value Set
valueset "Functional or Aplastic Anemia": 'urn:oid:1.1.1.1' // User Defined QDM Value Set
valueset "Immunocompromising Conditions": 'urn:oid:1.1.1.1' // User Defined QDM Value Set
valueset "Pneumococcal Conjugate Vaccine 13": 'urn:oid:1.1.1.1' // User Defined QDM Value Set
valueset "Pneumococcal Conjugate Vaccine 23": 'urn:oid:1.1.1.1' // User Defined QDM Value Set
valueset "Bone Marrow Transplant": 'urn:oid:2.16.840.1.113883.3.666.5.336' // Grouping Value Set
valueset "Chemotherapy": 'urn:oid:2.16.840.1.113762.1.4.1047.451' // Grouping Value Set
valueset "Cochlear Implants": 'urn:oid:1.1.1.1' // User Defined QDM Value Set

/*
This library has an explicit parameter which is the measurement year.
While the actual parameter's type accepts all intervals, this library
expects it will only be given arguments corresponding exactly to one whole
calendar year, and it will not behave properly otherwise; 2015 for example:
Interval[DateTime(2015,1,1,0,0,0,0), DateTime(2016,1,1,0,0,0,0))
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
			where ChoiceToIntervalOfDT(ProcedureUnion.performed) during "Measurement Period"
	)
	or
	exists (
		[DiagnosticReport: "Anaphylactic Reaction to Pneumococcal Conjugate Vaccine"] ReactionToVaccine
			where ReactionToVaccine.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }
				and ChoiceToIntervalOfDT(ReactionToVaccine.effective) ends before day of start of "Measurement Period"
	)

define "Chemotherapy and Bone Marrow Transplant Procedures":
	([Procedure: "Chemotherapy"] Proc
		where Proc.status.value in { 'in-progress', 'completed' })
	union
	([Procedure: "Bone Marrow Transplant"] Proc
		where Proc.status.value in { 'in-progress', 'completed' })

/*
Denominators and Numerators
*/

define "Denominator":
	"Initial Population"

define "Numerator":
	exists ("Pneumococcal Vaccine 13 After Age 60")
		and exists ("Pneumococcal Vaccine 23 After Age 60")
		and exists ("PVC13 and PVC23 12 Months Apart")
		and "Immunocompromised Diagnoses or Cochlear Implants"
		and exists ("PVC13 and PVC23 8 Weeks Apart")

define "Pneumococcal Vaccine 13 After Age 60":
	[Immunization: "Pneumococcal Conjugate Vaccine 13"] V13
		where V13.status.value in { 'in-progress', 'completed' }
			and AgeInYearsAt(V13."date".value) >= 60

define "Pneumococcal Vaccine 23 After Age 60":
	[Immunization: "Pneumococcal Conjugate Vaccine 23"] V23
		where V23.status.value in { 'in-progress', 'completed' }
			and AgeInYearsAt(V23."date".value) >= 60

define "First Pneumococcal Vaccine 13 After Age 2":
	First (
		[Immunization: "Pneumococcal Conjugate Vaccine 13"] V13
			where V13.status.value in { 'in-progress', 'completed' }
				and AgeInYearsAt(V13."date".value) >= 2
	)

define "PVC13 and PVC23 8 Weeks Apart":
	"First Pneumococcal Vaccine 13 After Age 2" V13
		with [Immunization: "Pneumococcal Conjugate Vaccine 23"] V23
			such that V23.status.value in { 'in-progress', 'completed' }
				and (weeks between V13."date".value and V23."date".value >= 8
					or weeks between V23."date".value and V13."date".value >= 8)
	return V13

define "PVC13 and PVC23 12 Months Apart":
	"Pneumococcal Vaccine 13 After Age 60" V13
		with "Pneumococcal Vaccine 23 After Age 60" V23
			such that months between V13."date".value and V23."date".value >= 12
				or months between V23."date".value and V13."date".value >= 12
	return V13

define "Immunocompromised Diagnoses or Cochlear Implants":
	exists ("Immunocompromised Diagnoses Overlapping Measurement Period")
		or exists ("Cochlear Implants on or Before End of Measurement Period")

define "Immunocompromised Diagnoses Overlapping Measurement Period":
	"Immunocompromised Diagnoses" ImmunocompromisedUnion
		where ChoiceToIntervalOfDT(ImmunocompromisedUnion.effective) overlaps "Measurement Period"

define "Immunocompromised Diagnoses":
	distinct (
		[DiagnosticReport: "Cerebrospinal Fluid Leaks"]
		union [DiagnosticReport: "Functional or Aplastic Anemia"]
		union [DiagnosticReport: "Immunocompromising Conditions"]
	) D
		where D.status.value in { 'preliminary', 'final', 'amended', 'corrected', 'appended' }

define "Cochlear Implants on or Before End of Measurement Period":
	[Procedure: "Cochlear Implants"] CochlearImplant
		where CochlearImplant.status.value in { 'in-progress', 'completed' }
			and start of ChoiceToIntervalOfDT(CochlearImplant.performed) same day or before end of "Measurement Period"

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
