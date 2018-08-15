/*
Medication reconciliation postdischarge (MRP)
*/

library MRP_FHIR version '1.0.000'

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0'

// Use http://fhir.ext.apelon.com/dtsserverws/fhir to evaluate, but these are the canonical urls
valueset "Inpatient Encounter": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.666.5.307' // In VSAC
valueset "Medication Reconciliation Value Set": 'http://ncqa.org/hedis/ValueSet/2.16.840.1.113883.3.464.1004.1174' // HEDIS IG?

// Prescribing Practitioner, Clinical Pharmacist or Registered Nurse
// http://hl7.org/fhir/v2/0360/2.7/index.html { CNP, CRN, DO, MD, NP, PharmD, RN, RPH }
valueset "Valid Medication Reconciliation Performer Qualifications": 'http://ncqa.org/hedis/ValueSet/hedis-med-rec-practitioner'

parameter "Measurement Period" default Interval[@2018-01-01T00:00, @2019-01-01T00:00)

context Patient

define Encounters:
  [Encounter: "Inpatient Encounter"] E
    where E.period ends during Interval[start of "Measurement Period", end of "Measurement Period" - 30 days]

define "Initial Population":
  Encounters E
    where AgeInYearsAt(end of "Measurement Period") >= 18

define Denominator:
  true
  
define Practitioners:
  [Practitioner] P
    where P.active
      and exists (P.qualification Q where Q.code in "Valid Medication Reconciliation Performer Qualifications")
  
define Tasks:
  [Task: "Medication Reconciliation Value Set"] T
    where T.intent = 'order'
      and T.status = 'completed'
      and exists (Practitioners P where EndsWith(T.owner.reference, P.id))
      
define Observations:
  [Observation: "Medication Reconciliation Value Set"] O
    where O.status in { 'final', 'amended', 'corrected' }
      and exists (Practitioners P where EndsWith(O.performer[0].reference, P.id))

define Numerator:
  Encounters E 
    where exists (Tasks T where FHIRHelpers.ToInterval(T.executionPeriod) during Interval[E.period."end", E.period."end" + 30 days])
      or exists (Observations O where O.effective during Interval[E.period."end", E.period."end" + 30 days])

