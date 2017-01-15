library COL version '1'

using FHIR version '1.6'

/*

Colonoscopy	          COL	Indicates a colonoscopy was provided on the indicated date of service,                    CPT, HCPCS	                       10 years
                      results/findings must be provided	ORU	"Colonoscopy"

Hx Colorectal Cancer	COL	Date of colorectal cancer diagnosis	ORU	"Colorectal Cancer"	                              HCPCS, ICD10CM	                   Unlimited

Hx Sigmoidoscopy	    COL	Most recent historic sigmoidoscopy date, results/findings must be provided	              CPT, HCPCS	                       5 years
                      ORU	"Flexible Sigmoidoscopy"

Hx Total Colectomy	  COL	Date of total colectomy	ORU	"Total Colectomy"	                                            CPT, ICD10PCS	                     Unlimited

iFOBT	                COL	Indicates completion of an immunochemical fecal occult blood test (iFOBT) as              CPT, HCPCS, LOINC       	         1 year
                      part of screening for colorectal cancer.  Results/findings must be provided.

gFOBT	                COL	Indicates completion of a GUAIAC fecal occult blood test (gFOBT) as part of screening     CPT, HCPCS, LOINC	                 1 year
                      for colorectal cancer.Â  Provide number of samples returned
                      (completion of test requires 3 results).	ORU	"FOBT"

Hx Colonoscopy	      COL	Most recent historic colonoscopy date	ORU	"Colonoscopy"	                                  CPT, HCPCS	                       10 years

*/

/*
https://ecqi.healthit.gov/system/files/ecqm/2014/EP/measures/CMS130v3.html
"Laboratory Test, Result: Fecal Occult Blood Test (FOBT)" using "Fecal Occult Blood Test (FOBT) Grouping Value Set (2.16.840.1.113883.3.464.1003.198.12.1011)"
"Procedure, Performed: Colonoscopy" using "Colonoscopy Grouping Value Set (2.16.840.1.113883.3.464.1003.108.12.1020)"
"Procedure, Performed: Flexible Sigmoidoscopy" using "Flexible Sigmoidoscopy Grouping Value Set (2.16.840.1.113883.3.464.1003.198.12.1010)"
"Procedure, Performed: Total Colectomy" using "Total Colectomy Grouping Value Set (2.16.840.1.113883.3.464.1003.198.12.1019)"

https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=3&ved=0ahUKEwjH8s7Qv_DLAhXsloMKHWWZAy8QFggpMAI&url=http%3A%2F%2Fwww.ncqa.org%2FPortals%2F0%2FHomepage%2FHEDIS_2015_Public_Comment_Value_Set_Directory.xlsx&usg=AFQjCNF_C4NgMFPA5IE2LQ3b17uOi8NmrQ&sig2=qtVajd628VNTb_yS9camxA&cad=rja
Non-Recommended Colorectal Cancer Screening in Older Adults	Colonoscopy	2.16.840.1.113883.3.464.1004.1064
Non-Recommended Colorectal Cancer Screening in Older Adults	Colorectal Cancer	2.16.840.1.113883.3.464.1004.1065
Non-Recommended Colorectal Cancer Screening in Older Adults	Flexible Sigmoidoscopy	2.16.840.1.113883.3.464.1004.1102
Non-Recommended Colorectal Cancer Screening in Older Adults	FOBT	2.16.840.1.113883.3.464.1004.1093

*/

valueset "Malignant Neoplasm of Colon": '2.16.840.1.113883.3.464.1004.1065' // Colorectal Cancer
valueset "Total Colectomy": '2.16.840.1.113883.3.464.1003.198.12.1019'
valueset "Colonoscopy":	'2.16.840.1.113883.3.464.1004.1064'
valueset "Flexible Sigmoidoscopy": '2.16.840.1.113883.3.464.1004.1102'
valueset "Fecal Occult Blood Test (FOBT)": '2.16.840.1.113883.3.464.1003.198.12.1011'
valueset "CT Colonography": '2.16.840.1.113883.3.464.1004.1421'
valueset "FIT-DNA": '2.16.840.1.113883.3.464.1004.1420'

parameter MeasurementPeriod Interval<DateTime>

context Patient

//used by FOBT
define "Lookback Interval One Year":
  Interval[start of MeasurementPeriod, end of MeasurementPeriod]

//used by FIT  
  define "Lookback Interval Two Years":
  Interval[start of MeasurementPeriod - 1 years, end of MeasurementPeriod]

//used by CT and FS
define "Lookback Interval Five Years":
  Interval[start of MeasurementPeriod - 4 years, end of MeasurementPeriod]

//used by Colonoscopy
define "Lookback Interval Ten Years":
  Interval[start of MeasurementPeriod - 9 years, end of MeasurementPeriod]

// TODO: Need to verify the demographic here
define "In Demographic":
    AgeInYearsAt(end of MeasurementPeriod) >= 51 and
    AgeInYearsAt(end of MeasurementPeriod) <= 75

// Hx Colorectal Cancer	Date of colorectal cancer diagnosis - no date to exclude future

define "Hx Colorectal Cancer":
  [Condition: "Malignant Neoplasm of Colon"] C
    where C.verificationStatus.value = 'confirmed'

// Hx Total Colectomy - Date of total colectomy - no date to exclude future

define "Hx Total Colectomy":
  [Procedure: "Total Colectomy"] T
    where T.status.value = 'completed'

// Colonoscopy - Indicates a colonoscopy was provided on the indicated date of service, results/findings must be provided.

define "Colonoscopy Performed":
  [DiagnosticReport: "Colonoscopy"] C
    where C.status.value = { 'final', 'appended', 'corrected' } 
      and C.performedDateTime.value during "Lookback Interval Ten Years"



// Hx Sigmoidoscopy	- Most recent historic sigmoidoscopy date, results/findings must be provided

define "Sigmoidoscopy Procedure":
  [DiagnosticReport: "Flexible Sigmoidoscopy"] S
	where S.status.value = { 'final', 'appended', 'corrected' } 
		and S.performedDateTime.value during "Lookback Interval Five Years"


// Using the grouping value set to include both iFOBT and gFOBT

define "FOBT Observation":
  [Observation: "Fecal Occult Blood Test (FOBT)"] O
    where O.status.value = { 'final', 'amended' } 
      and O.effectiveDateTime.value during "Lookback Interval One Year"

// Hx Colonoscopy - Most recent historic colonoscopy date

define "Colonoscopy Procedure":
  [DiagnosticReport: "Colonoscopy"] C
	where C.status.value = { 'final', 'appended', 'corrected' } 
		and C.performedDateTime.value during "Lookback Interval Ten Years"


// Virtual Colonoscopy - Procedure and Observation

define "Virtual Colonoscopy Procedure":
  [DiagnosticReport: "CT Colonography"] V
		where V.status.value = { 'final', 'appended', 'corrected' } 
      and V.performedDateTime.value during "Lookback Interval Five Years"

     
     
// Fit DNA - Procedure and Observation

define "Fit DNA Observation":
  [Observation: "CT Colonography"] F
    where F.status.value = { 'final', 'amended' } 
      and F.effectiveDateTime.value during "Lookback Interval Two Years"