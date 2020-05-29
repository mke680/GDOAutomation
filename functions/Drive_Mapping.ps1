#Template Path
$templatePath = (Split-Path -path $PSScriptRoot -Parent) + '\'

#Network Path 
$csvDrives = $templatePath  + 'config\' + 'Drive_Config.csv'

#Import CSV
$drives = Import-Csv $csvDrives 

foreach($drive in $drives){

    #Prep Drive Letters Remove Existing Mapping
    $checkDrive = Get-PSDrive -Name $drive.DriveLetter -ErrorAction SilentlyContinue

    if($checkDrive){ 
        try{
            Remove-PSDrive -Name $drive.DriveLetter -ErrorAction Stop ;Sleep -Seconds 3 #Allow Time for Drive to disconnect
        }catch{ 
            if($Error[0].Exception.MEssage -like '*because it is in use.'){
                write-host 'Drive Letter Active'  $drive.DriveLetter ':'   $drive.NetworkLocation -ForegroundColor Yellow
                continue
            }else{
                write-host 'Could not Disconnect for some stupid reason.' -ForegroundColor DarkRed 
            }
        }
    } 

    #Map Drives
    try{

        New-PSDrive -Persist -Name $drive.DriveLetter -PSProvider "FileSystem" -Root $drive.NetworkLocation -ErrorAction Stop | Out-Null
        $message = 'Successfully Mapped ' + $drive.DriveLetter+ ' : ' + $drive.NetworkLocation 
        write-host $message -ForegroundColor Green

    }catch{
        switch($Error[0].Exception.Message){ 

            #Error Logic
            'Access is denied' { write-host $Error[0].Exception.Message  'to'  $drive.DriveLetter ':'   $drive.NetworkLocation -ForegroundColor Red }
            'The network path was not found' { write-host 'Network unreachable'  $drive.DriveLetter ':'   $drive.NetworkLocation -ForegroundColor Yellow }
            #'The local device name is already in use' { write-host 'Drive Letter Active' $drive.DriveLetter ':'   $drive.NetworkLocation -ForegroundColor Yellow }
            Default { write-host $Error[0].Exception.Message  'to:'  $drive.NetworkLocation -ForegroundColor Gray }

        }
    }
}
