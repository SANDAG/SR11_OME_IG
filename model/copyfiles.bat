@ECHO off

SET argc=0
FOR %%x in (%*) DO SET /A argc+=1

CD %1

IF EXIST %1\output_%2 DEL %1\output_%2
MKDIR %1\output_%2
MKDIR %1\output_%2\assignment
MKDIR %1\output_%2\skims

COPY %1\poe_output.csv %1\output_%2\poe_output.csv /Y
COPY %1\poe_results.csv %1\output_%2\poe_results.csv /Y
COPY %1\port_of_entry_demand.csv %1\output_%2\port_of_entry_demand.csv /Y
COPY %1\results.xlsx %1\output_%2\results.xlsx /Y

XCOPY %1\assignment\*.bin %1\output_%2\assignment\*.bin /Y /Q
XCOPY %1\assignment\*.dcb %1\output_%2\assignment\*.dcb /Y /Q
XCOPY %1\skims\*.RDS %1\output_%2\skims\*.RDS /Y /Q
XCOPY %1\skims\*.MTX %1\output_%2\skims\*.MTX /Y /Q
XCOPY %1\skims\*.net %1\output_%2\skims\*.net /Y /Q