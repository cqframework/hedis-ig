library NCQA_Common_FHIR version '3.10.000'

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0' called FHIRHelpers

codesystem "LOINC": 'urn:oid:2.16.840.1.113883.6.1'
codesystem "SNOMEDCT": 'urn:oid:2.16.840.1.113883.6.96'
codesystem "SNOMEDCT:2015-09": 'urn:oid:2.16.840.1.113883.6.96' version 'urn:hl7:version:2015-09'
codesystem "SNOMEDCT:2016-03": 'urn:oid:2.16.840.1.113883.6.96' version 'urn:hl7:version:2016-03'

valueset "Encounter Inpatient": 'urn:oid:2.16.840.1.113883.3.666.5.307'
valueset "Hospice care ambulatory": 'urn:oid:2.16.840.1.113762.1.4.1108.15'
valueset "Care Services in Long-Term Residential Facility": 'urn:oid:2.16.840.1.113883.3.464.1003.101.12.1014'
valueset "X Institutional SNP Value Set": 'urn:oid:2.16.840.1.113762.1.4.1165.43'
valueset "Commercial": 'urn:oid:2.16.840.1.113762.1.4.1165.46'
valueset "Medicaid": 'urn:oid:2.16.840.1.113762.1.4.1165.45'
valueset "Medicare": 'urn:oid:2.16.840.1.113762.1.4.1165.44'
valueset "NCQA Payer": 'urn:oid:2.16.840.1.113762.1.4.1165.42'

code "Birthdate": '21112-8' from "LOINC" display 'Birthdate'
code "Dead": '419099009' from "SNOMEDCT" display 'Dead'
code "Discharge to healthcare facility for hospice care (procedure)": '428371000124100' from "SNOMEDCT:2015-09" display 'Discharge to healthcare facility for hospice care (procedure)'
code "Discharge to home for hospice care (procedure)": '428361000124107' from "SNOMEDCT:2015-09" display 'Discharge to home for hospice care (procedure)'
code "Long term care hospital (environment)": '32074000' from "SNOMEDCT:2016-03" display 'Long term care hospital (environment)'
code "Patient transfer, to another health care facility (procedure)": '19712007' from "SNOMEDCT:2016-03" display 'Patient transfer, to another health care facility (procedure)'
code "Referral to long term care service (procedure)": '417708006' from "SNOMEDCT:2016-03" display 'Referral to long term care service (procedure)'

parameter "Measurement Period" Interval<DateTime>

context Patient

define "Is Enrolled in Institutional SNP":
  exists ( ["Encounter": "X Institutional SNP Value Set"] SNP
      where SNP.status in { 'in-progress', 'finished' }
        and SNP.period overlaps "Measurement Period"
  )

define "Is Living Long Term in Institution":
  exists ( ["Encounter": "Encounter Inpatient"] DischargeLongTerm
      where DischargeLongTerm.status in { 'in-progress', 'finished' }
        and ( FHIRHelpers.ToConcept(DischargeLongTerm.hospitalization.dischargeDisposition) ~ "Patient transfer, to another health care facility (procedure)"
          or FHIRHelpers.ToConcept(DischargeLongTerm.hospitalization.dischargeDisposition) ~ "Referral to long term care service (procedure)"
      )
        and DischargeLongTerm.period ends during "Measurement Period"
  )
    // TODO: Consider whether this should be Procedure or Task? (See http://build.fhir.org/ig/cqframework/qi-core/Intervention.html#Intervention)
    or exists ( ["Task": "Care Services in Long-Term Residential Facility"] LongTermOrder
        where LongTermOrder.intent = 'order'
          and (LongTermOrder.authoredOn during "Measurement Period"
            or LongTermOrder.executionPeriod overlaps "Measurement Period"
          )
    )
    // TODO: For the mapping to task, both Order and Performed map to a Task with intent of order, the fact that
    // the task is performed seems to be best captured by the presence of an executionPeriod... This would be
    // worth some discussion with the Workflow Group on the intended representation here
    //or exists ( ["Task": "Care Services in Long-Term Residential Facility"] LongTermPerformed
    //    where LongTermPerformed.
    //    LongTermPerformed.relevantPeriod overlaps "Measurement Period"
    //)

define "Is Age 65 Plus at Start":
  CalendarAgeInYearsAt(Patient.birthDate, start of "Measurement Period")>= 65

define "Lookback Interval Four More Years":
  Interval[start of "Measurement Period" - 4 years, end of "Measurement Period"]

define "Lookback Interval Two More Years":
  Interval[start of "Measurement Period" - 2 years, end of "Measurement Period"]

/*This is the standard NCQA Hospice exclusion logic from 3.6.2018*/
define "Has Hospice":
  exists ( ["Encounter": "Encounter Inpatient"] DischargeHospice
      where DischargeHospice.status in { 'in-progress', 'finished' }
        and ( FHIRHelpers.ToConcept(DischargeHospice.hospitalization.dischargeDisposition) ~ "Discharge to home for hospice care (procedure)"
          or FHIRHelpers.ToConcept(DischargeHospice.hospitalization.dischargeDisposition) ~ "Discharge to healthcare facility for hospice care (procedure)"
      )
        and DischargeHospice.period ends during "Measurement Period"
  )
    or exists ( ["Task": "Hospice care ambulatory"] HospiceTask
        where HospiceTask.intent = 'order'
          and (HospiceTask.authoredOn during "Measurement Period"
            or HospiceTask.executionPeriod overlaps "Measurement Period"
          )
    )
    // TODO: See discussion in "Is Living Long Term in Institution"
    //or exists ( ["Intervention, Order": "Hospice care ambulatory"] HospiceOrder
    //    where HospiceOrder.authorDatetime during "Measurement Period"
    //)
    //or exists ( ["Intervention, Performed": "Hospice care ambulatory"] HospicePerformed
    //    where HospicePerformed.relevantPeriod overlaps "Measurement Period"
    //)

// TODO: From a QDM perspective, these really ought to just be Participation, right? There's no need for this characteristic anymore?
//define "Is Medicaid":
//  exists ( ["Patient Characteristic Payer": "Medicaid"] )

//define "Is Commercial":
//  exists ( ["Patient Characteristic Payer": "Commercial"] )

//define "Is Medicare":
//  exists ( ["Patient Characteristic Payer": "Medicare"] )

define "Medicaid Product":
  'medicaid'

define "Commercial Product":
  'commercial'

define "Medicare Product":
  'medicare'

define "Is Enrolled Commercial":
  "Is Continuously Enrolled One Year"("Commercial Product")
    or "Is Continuously Enrolled Two Years"("Commercial Product")
    or "Is Continuously Enrolled for Twenty Seven Months"("Commercial Product")

define "Is Enrolled Medicaid":
  "Is Continuously Enrolled One Year"("Medicaid Product")
    or "Is Continuously Enrolled Two Years"("Medicaid Product")
    or "Is Continuously Enrolled for Twenty Seven Months"("Medicaid Product")

define "Is Enrolled Medicare":
  "Is Continuously Enrolled One Year"("Medicare Product")
    or "Is Continuously Enrolled Two Years"("Medicare Product")
    or "Is Continuously Enrolled for Twenty Seven Months"("Medicare Product")

define "First Predecessor Year":
  Interval[start of "Measurement Period" - 1 year, start of "Measurement Period" )

define "Second Predecessor Quarter":
  Interval[start of "Measurement Period" - 1 years - 3 months, start of "Measurement Period" - 1 year )

define "Second Predecessor Year":
  Interval[start of "Measurement Period" - 2 years, start of "Measurement Period" - 1 year )

/*ToDate takes a given DateTime value and returns a DateTime with the time components "zeroed", and the timezone of the input value, for example */
define function "ToDate"(Value DateTime ):
  DateTime(year from Value, month from Value, day from Value, 0, 0, 0, 0, timezone from Value)

/*CalendarAgeInDaysAt calculates the calendar age (meaning the age without considering time components) in days*/
define function "CalendarAgeInDaysAt"(BirthDateTime DateTime, AsOf DateTime ):
  days between ToDate(BirthDateTime)and ToDate(AsOf)

/*CalendarAgeInDays calculates the calendar age (meaning the age without considering time components) in days as of today*/
define function "CalendarAgeInDays"(BirthDateTime DateTime ):
  CalendarAgeInDaysAt(BirthDateTime, Today())

/*CalendarAgeInMonthsAt calculates the calendar age (meaning the age without considering time components) in months*/
define function "CalendarAgeInMonthsAt"(BirthDateTime DateTime, AsOf DateTime ):
  months between ToDate(BirthDateTime)and ToDate(AsOf)

define function "CalendarAgeInMonths"(BirthDateTime DateTime ):
  CalendarAgeInMonthsAt(BirthDateTime, Today())

/*calculates the difference in calendar days between the start and end of the given interval*/
define function "LengthInDays"(Value Interval<DateTime> ):
  difference in days between start of Value and end of Value

/*CalendarAgeInYearsAt calculates the calendar age (meaning the age without considering time components) in years*/
define function "CalendarAgeInYearsAt"(BirthDateTime DateTime, AsOf DateTime ):
  years between ToDate(BirthDateTime)and ToDate(AsOf)

/*CalendarAgeInYears calculates the calendar age (meaning the age without considering time components) in years as of today */
define function "CalendarAgeInYears"(BirthDateTime DateTime ):
  CalendarAgeInYearsAt(BirthDateTime, Today())

define function "Enrollment Periods"(ProductLine String ):
  collapse ( ( case ProductLine 
        when "Commercial Product" then ["Coverage": "Commercial"] C where C.status = 'active'
        when "Medicare Product" then ["Coverage": "Medicare"] C where C.status = 'active'
        when "Medicaid Product" then ["Coverage": "Medicaid"] C where C.status = 'active'
        else ["Coverage": "NCQA Payer"] C where C.status = 'active'
      end 
    ) Coverage
      return all Coverage.period
  )

define function "Is Continuous Enrollment in Quarter"(ProductLine String, Quarter Interval<DateTime> ):
  ( {
    ProductLine: ProductLine,
    Quarter: Quarter
  } ) Input
    let Periods: "EnrollmentPeriodsInYear"(Input.ProductLine, Input.Quarter)
    return Count(Periods)= 1
      and Periods[0]= Quarter

define function "EnrollmentPeriodsInYear"(ProductLine String, Year Interval<DateTime> ):
  ("Enrollment Periods"(ProductLine)) EnrP
    where EnrP overlaps Year
    return EnrP intersect Year

define function "Is Continuously Enrolled Two Years"(ProductLine String ):
  "Is Continuous Enrollment In Year"(ProductLine, "Measurement Period")
    and "Is Continuous Enrollment In Year"(ProductLine, "First Predecessor Year")

define function "Is Continuously Enrolled for Twenty Seven Months"(ProductLine String ):
  "Is Continuous Enrollment In Year"(ProductLine, "Measurement Period")
    and "Is Continuous Enrollment In Year"(ProductLine, "First Predecessor Year")
    and "Is Continuous Enrollment In Year"(ProductLine, "Second Predecessor Year")
    and "Is Continuous Enrollment in Quarter"(ProductLine, "Second Predecessor Quarter")

define function "Is In Applicable Product Line"(ProductLine String ):
  case 
    when ( ProductLine is null ) then true 
    when ( ProductLine ~ "Commercial Product" ) then 
      "Is Continuously Enrolled One Year"(ProductLine)
        or "Is Continuously Enrolled for Twenty Seven Months"(ProductLine)
        or "Is Continuously Enrolled Two Years"(ProductLine)
    when ( ProductLine ~ "Medicaid Product" ) then 
      "Is Continuously Enrolled One Year"(ProductLine)
        or "Is Continuously Enrolled for Twenty Seven Months"(ProductLine)
        or "Is Continuously Enrolled Two Years"(ProductLine)
    when ( ProductLine ~ "Medicare Product" ) then 
      "Is Continuously Enrolled One Year"(ProductLine)
        or "Is Continuously Enrolled for Twenty Seven Months"(ProductLine)
        or "Is Continuously Enrolled Two Years"(ProductLine)
    else false 
  end

  //and  (if "Is Age 65 Plus at Start" then ( "Is Enrolled in Institutional SNP"
  //or "Is Living Long Term in Institution"
  //) else false
  //)

define function "Is Continuously Enrolled One Year"(ProductLine String ):
  "Is Continuous Enrollment In Year"(ProductLine, "Measurement Period")

define function "Is Continuous Enrollment In Year"(ProductLine String, Year Interval<DateTime> ):
  ( {
    ProductLine: ProductLine,
    Year: Year
  } ) Input
    let Periods: "EnrollmentPeriodsInYear"(Input.ProductLine, Input.Year)
    return 
      case Count(Periods)
        when 1 then ( ( Periods[0] starts Year
            and ( ( difference in days between end of Periods[0] and end of Year ) <= 45 )
          )
          or ( Periods[0] ends Year
            and ( ( difference in days between start of Periods[0] and start of Year ) <= 45 )
          )
        ) 
        when 2 then ( Periods[0] starts Year and Periods[1] ends Year
          and ( difference in days between end of Periods[0] and start of Periods[1]<= 45 )
        ) 
        else false 
      end
