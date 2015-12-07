@echo off
echo Build started...
asm68k /p /m main.asm,s3k.md, , s3k.lst>err.68k.txt
echo "Fixing equates for SK"
java -jar tools/EuqateProcessor.jar sound/driver/VariablesSK.Z80
echo "Fixing equates for S3"
java -jar tools/EuqateProcessor.jar sound/driver/VariablesS3.Z80

IF NOT EXIST s3k.md goto LABLERR
rem rompad s3k.md 255 0
rem fixheadr.exe s3k.md

echo Build succeeded

goto LABLDONE

:LABLERR
echo Build failed

:LABLDONE
