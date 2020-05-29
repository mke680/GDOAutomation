Function Set-GDOJson{

#Check SQL for Conflicts ONLY NEEDED FOR FIRST RUN
#Install-Module -Name SqlServer -Scope CurrentUser

Param($index)

[hashtable]$return = @{}

# DB
$Database = "IMD0VSQL01"

### Currently Supplied Index File ###
$documentPath = (Split-Path -path $index -Parent) + '\'
$uploadedFolder = (Split-Path -path (Split-Path -path $documentPath -Parent) -Parent)  + '\Uploaded\' 
$networkPath = Split-Path -Path $documentPath -Parent
$tableName = (Get-Date -format FileDate).ToString() + "_" + ((Get-item $documentPath | Select Name).Name).Replace("WO ","").Replace("WO","")

#template Path
$templatePath = (Split-Path -path $PSScriptRoot -Parent) + '\'

#$networkPath 
$csvCreds = $templatePath  + 'config\' + 'GDO_Creds.csv'

#import CSV
$creds = Import-Csv $csvCreds 

#Search For Matching Creds
$validCreds = $creds | Where-Object {$_.network_path -eq $networkPath } 
if(!$validCreds){
    $return.outputjson = $null 
    $return.name = ((Get-item $documentPath | Select Name).Name).Replace("WO ","").Replace("WO","")
    return $return
}
#outputFile
$outputjson = $templatePath + 'json\' + $validCreds.dbname + '_migration.json'

#Json Structure
$json = @{}
    $csv_splitter = @()
    $connection = @{}
        $ix = @{}
        $db = @{}
    $projects = New-Object System.Collections.Arraylist
    $project = @{}
        #conditional values
            $kwf_Condition = @{}
                $default_Value = @{}

#splitter value
$csv_splitter  = '|'

#ix values
$ix['username'] = $validCreds.ix_user
$ix['password'] = $validCreds.ix_pass
$ix['ixurl'] = $validCreds.ix_url

#db values
$db['username'] = $validCreds.db_user 
$db['password'] = $validCreds.db_pass
$db['dbhost'] = $Database
$db['dbport'] = "1433"
$db['dbname'] = $validCreds.dbname
$db['batchsize'] = "100"

#Build Connection
$connection['ix'] = $ix
$connection['db'] = $db

#conditional values
if($validCreds.kwf_condition){
    $default_Value['default_value'] = $validCreds.kwf_condition
}else{
    $default_Value['default_value'] = "Scan On Demand"
}
$kwf_Condition['kwf_condition'] = $default_Value

#Index Attrs
$index_attrs = New-Object System.Collections.Arraylist
$index_attrs.Clear()
if($validCreds.index_Attr){
    $index_names = $validCreds.index_attr.Split('|')  
    $index_types = @()
    foreach($attr in $index_names){ $index_types += 'STRING' }     
}else{
    $index_names = @( 'SOD_CODE1',  'SOD_CODE2',  'SOD_CODE3',  'SOD_REQUESTOR_EMAIL',  'SOD_WODELDATE',  'SOD_WONUMBER',  'SOD_BOX',  'SOD_FILE',  'SOD_DESC',  'DOCUMENT_PATH' )
    $index_types = @( 'STRING',  'STRING',  'STRING',  'STRING',  'STRING',  'STRING',  'STRING',  'STRING',  'STRING',  'STRING' )
}
$counter = 0
foreach($name in $index_names){
    $index_temp = "" | select 'index_position', 'type', 'elogrpname'
    $index_temp.index_position =  $counter
    $index_temp.type = $index_types[$counter]
    $index_temp.elogrpname = $name
    $index_attrs.Add($index_temp) 
    $counter++
}

#Migration Attrs
$migration_attrs = New-Object System.Collections.Arraylist
$migration_attrs.Clear()
$migration_names = @( 'KWFNAME',  'ELOOBJID',  'UPLOADTIME' )
$migration_types = @( 'STRING',  'STRING',  'DATETIME' )
$migration_condition_name = @( 'kwf_condition' )
$counter = 0
foreach($name in $migration_names){
    try{
        if($migration_condition_name[$counter]){
            $migration_temp = "" | select 'index_position', 'type', 'elogrpname', 'condition_name'
            $migration_temp.condition_name = $migration_condition_name[$counter]
            $migration_temp.index_position =  100 + $counter
            $migration_temp.type = $index_types[$counter]
            $migration_temp.elogrpname = $name
            $migration_attrs.Add($migration_temp) 
            $counter++
        }else{
            $migration_temp = "" | select 'index_position', 'type', 'elogrpname'
            $migration_temp.index_position =  100 + $counter
            $migration_temp.type = $index_types[$counter]
            $migration_temp.elogrpname = $name
            $migration_attrs.Add($migration_temp) 
            $counter++
        }
    }catch{ 
        $migration_temp = "" | select 'index_position', 'type', 'elogrpname'
        $migration_temp.index_position =  100 + $counter
        $migration_temp.type = $index_types[$counter]
        $migration_temp.elogrpname = $name
        $migration_attrs.Add($migration_temp) 
        $counter++
    }

}

#Build Project
$project['name'] = $tableName
$project['indexfilepath'] = $index
$project['documentrootpath'] = $documentPath
$project['index_attrs'] = $index_attrs
$project['migration_attrs'] = $migration_attrs
$project['conditional_values'] = $kwf_Condition
$projects.Add($project)

#Build JSON
$json['projects'] = $projects
$json['connection'] = $connection
$json['csv_splitter'] = $csv_splitter

### SQL Pre-Checks
##Pre Import Query Check for Table Clash
$query = "SELECT TABLE_NAME FROM "+ ($Database) +".INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = '" + ($TableName)+ "_STAGING'"
#Post Import Query Check for Bad Uploads
$query2 = "SELECT DOCUMENT_PATH FROM [dbo].[" + ($TableName)+ "_STAGING] WHERE ELOOBJID IS NULL"

<##Requires SQL Module to communicate
$tableExist = try{
        Invoke-Sqlcmd -ServerInstance $SQLServer -Database $database -Query $query -Username $sqluser -Password $sqlpass -Verbose
    }catch{
        $Body += "$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") ERROR powershell.automation - " + "SQL Table Name NOT Unique." + "<br/>" + "<br/>"
        Send-MailMessage -From $from -To $to -Subject 'Upload Summary - Could Not Reach Server' -SmtpServer $smtpserver -Credential $Cred -BodyAsHtml $Body
    exit
    }

if($tableExist){
    $Body += "$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") ERROR powershell.automation - " + "SQL Table Name NOT Unique." + "<br/>" + "<br/>"
    Send-MailMessage -From $from -To $to -Subject 'Upload Summary - Errors Detected' -SmtpServer $smtpserver -Credential $Cred -BodyAsHtml $Body
    exit
}
#>

$json | ConvertTo-Json -Depth 10 | Out-File $outputjson -Encoding OEM

$return.outputjson = $outputjson 
$return.uploaded = $uploadedFolder 
$return.documentpath = $documentPath
$return.headercount = $index_names.Count
$return.name = ((Get-item $documentPath | Select Name).Name).Replace("WO ","").Replace("WO","")

Return $return
}