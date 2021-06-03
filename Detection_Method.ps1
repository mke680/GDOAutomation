# Template Path
$templatePath = (Split-Path -path $PSScriptRoot -Parent) + '\'
$PSScriptRoot

#Include Function json
.($templatePath + 'functions\Send_GdoBatchOutput.ps1')
$batchMigration = ('-file ' + $templatePath + 'functions\Batch_Migration.ps1')
.($templatePath + 'functions\Batch_Migration.ps1')
.($templatePath + 'functions\Drive_Mapping.ps1')

$Mount = Mount-GDODrives

# NetworkPath 
$csvDrives = $templatePath  + 'config\Drive_Config.csv'
$csvClients = $templatePath  + 'config\GDO_Creds.csv'
$readyState = '*.TXT'
$counter = 0

#Emailing Stuffs
$subject = 'GDO Detection Summary'
$body = "<body style='font-family: Arial;'><p>$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") AUDIT powershell.detection - " + "Starting Detection Method" + "<br/>" 

# Import CSV
$drives = Import-Csv $csvDrives 
$body += "$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") AUDIT powershell.detection - " + "Importing Drive Config" + "<br/>" 
$clients = Import-Csv $csvClients 
$body += "$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") AUDIT powershell.detection - " + "Importing Client Config" + "<br/>" 

# Exclusion Rules
$exclusion = '*Uploaded*'
$timespan = new-timespan -days 25 -hours 1 -minutes 10 ### Excessively set at the moment for better results

# Loop through available Drives
foreach($drive in $drives){
    try{
        $driveLetter = $drive.DriveLetter + ':\'  # Build Drive Letter
        $gdoDrive = Get-ChildItem -Path $driveLetter -Filter "GDO JOBS" -ErrorAction Stop | Select FullName # Locate GDO JOBS folder in Drive
        $sodDrive = Get-ChildItem -Path $gdoDrive.FullName -Filter "SOD" | Select FullName # Locate SOD Sub-Folder

        #If SOD Subfolder Successfully Located
        if($sodDrive.FullName){
        write-host 'Checking' $sodDrive.FullName -ForegroundColor Cyan
        $body += "</p><p style='font-familly: Arial'><span style='color: DodgerBlue'>$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") AUDIT powershell.detection - " + "Checking " + $sodDrive.FullName + "</span><br/>" 
            #$indexes = Get-ChildItem -Path $sodDrive.FullName  -Recurse -Filter $readyState | Where {$_.FullName -notlike $exclusion }  | Select FullName,LastWriteTime
            $folders = Get-ChildItem -Path $sodDrive.FullName -Directory | Get-ChildItem -Directory | Where {$_.FullName -notlike $exclusion } | Select FullName
            foreach($folder in $folders){
                foreach($client in $clients){
                if($client.network_path -eq $folder.Fullname){
                write-host 'Scanning for' $client.dbname -ForegroundColor Gray
                $body += "<span style='color: BLACK'>$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") AUDIT powershell.detection - " + "Client Detected " + $client.dbname + " - Scanning." + "</span><br/>"
                        $indexes = Get-ChildItem -Path $folder.Fullname -Directory | Get-ChildItem -depth 0 -filter $readyState | Select FullName,LastWriteTime, Name
                        foreach($index in $indexes){
                            if($index.Name -eq 'READY.TXT' ){
                                write-host $index.LastWriteTime.ToString("yyyy-MM-dd") '- Uploading -' $index.FullName -ForegroundColor Green # READY
                                $body += "<span style='color: AQUAMARINE'>$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") AUDIT powershell.detection - " + "Ready State Detected for - " + $index.FullName + "</span><br/>"
                                #$migration = Start-Migration -index $index.FullName -operation 3
                                $indexFullName = $index.FullName
                                Start-Process -FilePath PowerShell -ArgumentList " -Command Start-Migration -index '$indexFullName' -operation 3 -scriptRoot '$PSScriptRoot'"
                                $Counter++
                                #$body += $migration.result
                            }
                            if($index.Name -eq 'PROCESSED.TXT' ){
                                write-host $index.LastWriteTime.ToString("yyyy-MM-dd") '- Reprocess -' $index.FullName -ForegroundColor Yellow # PROCESSED BEFORE
                                $body += "<span style='color: STEELBLUE'>$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") AUDIT powershell.detection - " + "Reprocess State Detected for - " + $index.FullName + "</span><br/>"
                                $indexFullName = $index.FullName
                                Start-Process -FilePath PowerShell -ArgumentList " -Command Start-Migration -index '$indexFullName' -operation 2 -scriptRoot '$PSScriptRoot'"
                                $Counter++
                                #$body += $migration.result
                            }
                            if($index.Name -eq 'INDEX.TXT' ){
                                if(((get-date) - $index.LastWriteTime) -gt $timespan) {
                                    write-host $index.LastWriteTime.ToString("yyyy-MM-dd") '- Bypassing -' $index.FullName -ForegroundColor Gray # OLDER THAN EXPECTED
                                    $body += "<span style='color: MAGENTA'>$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") AUDIT powershell.detection - " + "Over 25 Days - " + $index.FullName + "</span><br/>"
                                    #Send-GDOBatchOutput -Username 'GIMHELPDESK' -Subject ( 'GDO - Automation - Forced Upload attempted' ) -Body $index.FullName
                                    #Start-Migration -index $index.FullName -operation 3
                                } else {
                                    #$body += "$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") AUDIT powershell.detection - " + "Awaiting Review for - " + $index.FullName + "<br/>"
                                    write-host $index.LastWriteTime.ToString("yyyy-MM-dd") '- Reviewing -' $index.FullName -ForegroundColor Magenta # AWAITING REVIEW
                                }
                            }      
                        }
                    }
                }    
            }
        }else{
            write-host 'Compliant Folder Structure Not Found in' $driveLetter -ForegroundColor Red 
            Send-GDOBatchOutput -Username 'GIMHELPDESK' -Subject ( 'Non-Compliant Folder Structure in ' + $driveLetter  ) -Body ' '
        }
    }catch{
        if($Error[0].Exception.Message -like 'Access To the path*'){
            write-host $Error[0].Exception.Message -ForegroundColor Red
            Send-GDOBatchOutput -Username 'GIMHELPDESK' -Subject ( 'No Access to ' + $driveLetter  ) -Body $Error[0]
        }else{
            write-host $Error[0].Exception.Message -ForegroundColor Red
            Send-GDOBatchOutput -Username 'GIMHELPDESK' -Subject ( 'Unknown Error in ' + $driveLetter  ) -Body $Error[0]
        }
    }
}
$body += "</p>$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") AUDIT powershell.detection - " + "Ending Detection Method" + "<br/></body>" 

#checkforresults
if($counter -gt 0){
    Send-GDOBatchOutput -Username 'GIMHELPDESK' -Subject $subject -Body $body 
} 
