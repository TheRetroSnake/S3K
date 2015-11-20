@echo off
echo "Assembling S&K driver"
vasmZ80 -Fbin -maxerrors=25 -nocase -DisSK=1 -L SK.lst -o SK.bin drv.Z80>../../err.SK.txt
echo "Assembling S3 driver"
vasmZ80 -Fbin -maxerrors=25 -nocase -DisSK=0  -L S3.lst -o S3.bin drv.Z80>../../err.S3.txt

echo "Compressing S&K driver"
"../../tools/KENSC/koscmp.exe" SK.bin SK.kos
del SK.bin