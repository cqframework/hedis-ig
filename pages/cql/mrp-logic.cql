/*
Medication reconciliation postdischarge (MRP)
*/

library MRP_FHIR

using FHIR version '3.0.0'

codesystem SNOMED: 'http://snomed.info/sct'
codesystem CPT: 'http://www.ama-assn.org/go/cpt'

valueset "Inpatient Encounter": 'http://ncqa.org/hedis/ValueSet/inpatientvalueset' // SNOMED
valueset "Medication Reconciliation Value Set": 'http://ncqa.org/hedis/ValueSet/hedismedrecvalueset' // CPT

code "Drug rehabilitation and detoxification": '56876005' from SNOMED
code "Medication reconciliation postdischarge": '1111F' from CPT

parameter "Measurement Period" default Interval[@2018-01-01T00:00, @2019-01-01T00:00)

context Patient

define "Initial Population":
    AgeInYearsAt(end of "Measurement Period") >= 18

define Encounters:
  // TODO: debug this, should be a value set reference
  [Encounter: "Drug rehabilitation and detoxification"] E
    // where E.period."end" during "Measurement Period" TODO: debug this

define Denominator:
  exists (Encounters)
  
define Procedures:
  [Procedure: "Medication reconciliation postdischarge"]

define Numerator:
  exists (
    Encounters E 
      with Procedures P 
        such that P.performed."end".value before E.period."end".value + 30 days
  )

//define TestEncounters: First(Encounters E return E.period."end".value)
//define TestProcedures: First(Procedures P return P.performed."end".value)

// TODO: debug this, should be able to say 30 days or less after...
//define TestCondition: TestProcedures before TestEncounters + 30 days
  

