@ECHO OFF

cls
echo.
echo.
cd "\\grace.com.au\local_cam\local_cam_q\SHARES_CAM\Data Integrity Shared\GDO Upload Script\DemoScratchPad\Tool"
CMD /C "C:\ELO\java\jre\bin\java.exe -jar gracemigration-1.0.jar -migrationjson "\\grace.com.au\local_cam\local_cam_q\SHARES_CAM\Data Integrity Shared\GDO Upload Script\DemoScratchPad\Tool\migration.json" -operation 3"
echo.
echo.
rem pause