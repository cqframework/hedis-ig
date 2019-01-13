/*
Medication reconciliation postdischarge (MRP)
*/

library MRP_FHIR version '1.0.000'

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0'
include Participation
include NCQACommon

// Use http://fhir.ext.apelon.com/dtsserverws/fhir to evaluate, but these are the canonical urls
valueset "Inpatient Encounter": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.666.5.307' // In VSAC
valueset "Medication Reconciliation Value Set": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1174' // HEDIS IG

// Prescribing Practitioner, Clinical Pharmacist or Registered Nurse
// http://hl7.org/fhir/v2/0360/2.7/index.html { CANP, CNP, CNM, CNS, CRN, DO, MD, NP, PharmD, RN, RPH, PA, FPNP, PN }
valueset "Valid Medication Reconciliation Performer Qualifications": 'http://ncqa.org/hedis/ValueSet/hedis-med-rec-practitioner'

parameter "Measurement Period" default Interval[@2018-01-01T00:00, @2019-01-01T00:00)

context Patient

define "Encounters Ending Before December 2nd":
  [Encounter: "Inpatient Encounter"] E1
    where E.status ~ 'Finished'
     and E.period ends during Interval[start of "Measurement Period", end of "Measurement Period" - 30 days] 

define "Encounters in Measurement Period":
  [Encounter: "Inpatient Encounter"] E2
    where E.status ~ 'Finished'
     and E.period ends during Interval[start of "Measurement Period", end of "Measurement Period"] 
     
// Consider expressing this using a without, since in the case that there is no encounter after E1, this won't return
define "Encounters without 30 Day Readmission":
	"Encounters Ending Before December 2nd" E1
	   with "Encounters in Measurement Period" E2 
	   such that difference in days between E2.period and E1.period > 30
    	

define "Initial Population":
  "Encounters without 30 Day Readmission" E
    where AgeInYearsAt(end of "Measurement Period") >= 18
    and Participation."Is Enrolled"(Participation."Medicare Product",
		  end of E.period + 30 days,Interval [start of E.period, end of E.period + 30 days], 0)
		and not Common.HasHospice



define Denominator:
  true
  
define Practitioners:
  [Practitioner] P
    where P.active //This indicates the practitioner record was not created in error
      and exists (P.qualification Q where Q.code in "Valid Medication Reconciliation Performer Qualifications")//Practitioner is qualified to reconcile medications
  
define Tasks:
  [Task: "Medication Reconciliation Value Set"] T
    where T.intent = 'order'
      and T.status = 'completed'
      and exists (Practitioners P where EndsWith(T.owner.reference, P.id))
      
define Observations:
  [Observation: "Medication Reconciliation Value Set"] O
    with Practitioners P
    such that O.status in { 'final', 'amended', 'corrected' }
      and exists (O.performer OP where EndsWith(OP.reference, P.id))

define Numerator:
  "Encounters without 30 Day Readmission" E 
    where exists (Tasks T where FHIRHelpers.ToInterval(T.executionPeriod) during Interval[E.period."end", E.period."end" + 30 days])
      or exists (Observations O where O.effective during Interval[E.period."end", E.period."end" + 30 days])


