SET JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF-8
call ant -buildfile build.xml -Dguidename=hedis -Dspec=http://hl7.org/fhir/
pause