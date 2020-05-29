$rootPath = "C:\Users\elo_admin\Desktop\JOHN HOLLAND\7. Migration\"

$projects = Get-Content -Path "$($rootPath)_PROJECT LIST.txt"
$logPath = "$($rootPath)Migration.log"
$migPath = "$($rootPath)RunMigration.cmd"



foreach($t in $projects){
    Test-Path -Path "$($rootPath)migration $($t).json" -PathType Leaf
}

$cnt = 0
foreach($p in $projects){
    
    $cnt++
    
    $startMigration = "`r`n`r`n$(Get-Date) - STARTED ($($cnt)/$($projects.Count)): $($p)`r`n"
    Add-Content -Value $startMigration -Path $logPath

    $cmdLine = @"
CD "C:\Users\elo_admin\Desktop\JOHN HOLLAND\7. Migration"
CMD /C "D:\elo\java\jre\bin\java.exe -jar gracemigration-1.0.jar -migrationjson "C:\Users\elo_admin\Desktop\JOHN HOLLAND\7. Migration\migration $($p).json" -operation 3"
"@

    Set-Content -Value $cmdLine -Path $migPath

    $myProcess = Start-Process $migPath -PassThru
    $myProcess.WaitForExit()

    $finishMigration = "`r`n$(Get-Date) - FINISHED ($($cnt)/$($projects.Count)): $($p)`r`n`r`n"
    Add-Content -Value $finishMigration -Path $logPath

    Get-ChildItem "Migration.log*" | Rename-Item -NewName { $_.name -Replace 'Migration',"Migration - $($p)" }
}


