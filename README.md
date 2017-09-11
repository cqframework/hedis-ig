# HEDIS (Healthcare Effectiveness Data and Information Set)

HEDIS® Implementation Guide

This project provides the source for the HEDIS® Implementation Guide.

The implementation is based on the prior payerextract FHIR IG.

Commits to this repository will automatically trigger a new build of the IG, which will then be published to the following location:

[http://build.fhir.org/ig/cqframework/payerextract](http://build.fhir.org/ig/cqframework/payerextract)

Build log is available here:
[http://ig-build.fhir.org.s3-website-us-east-1.amazonaws.com/logs/cqframework/payerextract](http://ig-build.fhir.org.s3-website-us-east-1.amazonaws.com/logs/cqframework/payerextract)

Full debugging information is available here:
[http://build.fhir.org/ig/cqframework/payerextract/debug.tgz](http://build.fhir.org/ig/cqframework/payerextract/debug.tgz)

## Local Build

The HL7 IG Publisher is committed to this repository to make building as easy as possible. To build locally, clone the repository and issue the following command in the root:

    java -jar "org.hl7.fhir.igpublisher.jar" -ig ig.json