@echo off
cd sound/driver
call build.bat
cd ../../
call build.bat
call buildS3andSK.bat
pause