# Template Path
$templatePath = (Split-Path -path $PSScriptRoot -Parent) + '\'

#Include Function json
.($templatePath + 'functions\Batch_Migration.ps1')

# NetworkPath 
$csvDrives = $PSScriptRoot  + '\config\Drive_Config.csv'

# Import CSV
$drives = Import-Csv $csvDrives 

# Exclusion Rules
$exclusion = '*Uploaded*'
$timespan = new-timespan -days 1 -hours 1 -minutes 5 ### Excessively set at the moment for better results

# Loop through available Drives
foreach($drive in $drives){
    try{
        $driveLetter = $drive.DriveLetter + ':\' # Build Drive Letter
        $gdoDrive = Get-ChildItem -Path $driveLetter -Filter "GDO JOBS" -ErrorAction Stop | Select FullName # Locate GDO JOBS folder in Drive
        $sodDrive = Get-ChildItem -Path $gdoDrive.FullName -Filter "SOD" | Select FullName # Locate SOD Sub-Folder

        #If SOD Subfolder Successfully Located
        if($sodDrive.FullName){
        write-host 'Checking' $sodDrive.FullName -ForegroundColor Cyan
            $indexes = Get-ChildItem -Path $sodDrive.FullName  -Recurse -Filter 'INDEX.TXT' | Where {$_.FullName -notlike $exclusion }  | Select FullName,LastWriteTime
            foreach($index in $indexes){
                if(((get-date) - $index.LastWriteTime) -gt $timespan) {
                    write-host $index.LastWriteTime ' - Bypassing -' $index.FullName -ForegroundColor Gray # Older
                    Start-Migration $index.FullName 3
                } else {
                    write-host $index.LastWriteTime ' - Uploading -' $index.FullName -ForegroundColor Green # Newer
                }          
            }
        }else{
            write-host 'Compliant Folder Structure Not Found in' $driveLetter -ForegroundColor Yellow 
        }
    }catch{
        if($Error[0].Exception.Message -like 'Access To the path*'){
            write-host $Error[0].Exception.Message -ForegroundColor Red
        }else{
            write-host $Error[0].Exception.Message -ForegroundColor Magenta
        }
    }
}
