#JSON Deconstructer
$Folder = 'D:\GDO Scripts\BulkUpload\SOD'


#$CredentialsOutPut| Add-Member -MemberType NoteProperty -Name ComputerName -Value

Get-ChildItem $Folder -Recurse 'migration.json' -File |
foreach{
    $lineCount = 0
    $inputjson = $_.Directory.FullName +'\' + $_.Name
    $json  = Get-Content $inputjson  #-raw | Out-String #| ConvertFrom-Json
    #write-host $inputjson
    $CredentialsOutPut = New-Object -TypeName psobject 
    foreach($line in $json){
    $lineCount ++
        if($line -like '*username*' -and $lineCount -eq 5){
            #write-host $line
            $CredentialsOutPut| Add-Member -MemberType NoteProperty -Name ix_user -Value $line
        }
        if($line -like '*ixurl*'){
            #write-host $line
            $CredentialsOutPut| Add-Member -MemberType NoteProperty -Name ix_url -Value $line
        }
        if($line -like '*username*' -and $lineCount -eq 10){
            #write-host $line
            $CredentialsOutPut| Add-Member -MemberType NoteProperty -Name db_user -Value $line
        }
        if($line -like '*dbname*'){
            #write-host $line
            $CredentialsOutPut| Add-Member -MemberType NoteProperty -Name dbname -Value $line
        }
        if($line -like '*"documentrootpath": *'){
            #write-host $line
            $CredentialsOutPut| Add-Member -MemberType NoteProperty -Name documentrootpath -Value $line
        }
    }
    $CredentialsOutPut | export-csv –append –path 'D:\Creds.csv'
    #Send off Errors
    #$ErrorsDetected = Select-String $json -Pattern  'username'  -NotMatch
    ##$sqluser = $json.connection.db.username
    ##$sqluser
    #$inputjson = $PSScriptroot + '\migration.json'

}