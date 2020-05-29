Function Start-Migration{

    Param($index,$operation)

    #Locations
    $templatePath = (Split-Path -path $PSScriptRoot -Parent) + '\'
    $logPath = $templatePath + 'logs\'

    #Include Function json
    .($templatePath + 'functions\JSON_Generator.ps1')
    .($templatePath + 'functions\Email_Validation.ps1')

    #Java Location
    $java="D:\ELO\java\bin\java.exe"
    #Jar Location
    $jarFile = $templatePath + 'Tool\gracemigration-1.0.jar'

    #VariablesChange
    #$index = Read-Host 'Enter Index File Full Path.'

    #Configure JSON File
    $json = (Set-GDOJson $index)
    $documentpath = $json.documentpath
    $uploadedPath = $json.uploaded + $json.name + "_$((Get-Date -format "yyyyMMdd").ToString())"

    #Auto Trigger Script should attempt first upload operation = 3 if fails try operation = 2
    #$operation = Read-Host 'Enter Operation Mode.' ### Errors that can cause operation 2 to succeed = file size or other misc reasons.
    $uploadFailures = 0
    $invalidRepo = 0
    $invalidEmails = 0

    #SMTP Config
    $username = $env:UserName.Substring(0,$env:UserName.Length-1)+ '@grace.com.au' ############# UPDATE TO RUNNING USER ##############
    $credPath = $templatePath + 'smtp\' + $username.replace('@grace.com.au','') +  '_SMTP.txt' ############ EMBED YOUR OWN PASSWORD ##########

    #Email Related
    $smtpserver = 'smtp.grace.com.au'
    $to = 'jshah@grace.com.au', 'rlabago@grace.com.au', 'mcho@grace.com.au' #Joyal to Provide contact list
    $from = 'AutomatedEDO <' + $username + '>'
    $Body = "Upload Summary for " + $json.name + "<br/>" + "<br/>"
    $pwdTxt = Get-Content $credPath
    $securePwd = $pwdTxt | ConvertTo-SecureString
    $cred = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $securePwd

    ##Dynamic SQL Name for JSON file
    #$tableName = (Get-Date -format FileDate).ToString() + "_" + ($PSscriptroot).Substring($PSScriptRoot.LastIndexOf("\")+1).Replace("WO ","")

    #Sanitize IndexFile
    Try { $IndexFile =  Import-Csv -Path $index -Delimiter '|' }
    Catch {
        $Body += "$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") ERROR powershell.automation - " + "Index File Missing" + "<br/>" + "<br/>"
        #Send-MailMessage -From $from -To $to -Subject ('Missing Index File - ' + $json.name ) -SmtpServer $smtpserver -Credential $Cred -BodyAsHtml $Body
        return $body ;exit 
    }

    foreach($targetEmail in ( $(foreach($target in $IndexFile){$target.Email}) | Get-Unique )){
        if($targetEmail){ $validEmail = Test-IsValidEmail $targetEmail }else{$validEmail = $TRUE}
        if($validEmail -eq $FALSE){$invalidEmails++; $Body += $targetEmail + ' is invalid.' + "<br/>" }
    }

    if($invalidEmails -gt 0){
        $Body = "$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") ERROR powershell.email.validation - " + "Email Format is incorrect." + "<br/>" + "<br/>" + $Body
        #Send-MailMessage -From $from -To $to -Attachments $index -Subject ('Malformed Email Address - ' + $json.name ) -SmtpServer $smtpserver -Credential $Cred -BodyAsHtml $body
        return $body ;exit
    }

    #Fix Missing Last Header
    $content = Get-Content $index   
    $header = $content | Select-Object -First 1 # Get current header of CSV file
    #$header = $header + '|DocumentPath' # Add additional columns
    $header = ($header + '|DocumentPath').split("|") # Split header into array
    #write-host $header.count
    
    #Invoke Java
    try{ 
        cd $documentpath 
    }catch{ 
        #Send-MailMessage -From $from -To $to -Subject ('Invalid Client - ' + $json.name ) -SmtpServer $smtpserver -Credential $Cred -BodyAsHtml ( $Body + "<br/>"+ "<br/>" + 'Invalid Client Supplied no Credentials Found.' )
        return ($(Get-Date -format "yyyy-MM-dd") + ' - No Client - ' + $index) ; exit 
        }

    #Check Header Count
    if($header.Count -ne $json.headercount){
        $Body +=  "$(Get-Date -format "yyyy-MM-dd hh:mm:ss,fff") ERROR powershell.automation - "  + "Incorrect Header Count" + "<br/>"+ "<br/>"
        #Send-MailMessage -From $from -To $to -Subject ( 'Incorrect Header Count - ' + $json.name ) -SmtpServer $smtpserver -Credential $Cred -BodyAsHtml $Body   
        return ($(Get-Date -format "yyyy-MM-dd") + ' - No Header - ' + $index) ;exit
    }

    ##return ($(Get-Date -format "yyyy-MM-dd") + ' - Uploading - ' + $index)

    & $java -jar $jarFile -operation $operation -migrationjson ($json.outputjson)
 
    #Send off Errors
    $ErrorsDetected = Select-String -Path .\Migration.log -Pattern  'Info'  -NotMatch
    $logUpdatedName = $json.name + " - $((Get-Date -format "yyyyMMdd_hhmm").ToString())"

    #Timestamp Migration Log for secondary attempts
    Get-ChildItem "Migration.log*" -Path $documentpath | Rename-Item -NewName { $_.name -Replace 'Migration',$logUpdatedName } -PassThru | Move-Item -Destination $logPath
    $attachment = $logPath + $logUpdatedName + ".log"

    #Embed log file errors into Email body
    if($ErrorsDetected){
        foreach($ErrorDetected in $ErrorsDetected){
            if($ErrorDetected.Line -like '*Upload failed -*'){ $uploadFailures++ }
            if($ErrorDetected.Line -like '*Not Found -*'){ $uploadFailures++ }
            if($ErrorDetected.Line -like '*Invalid repo*'){ $invalidRepo++ }
            $ErrorCleaned = $ErrorDetected.Line

            $Body += $ErrorCleaned + "<br/>" + "<br/>"

        }
        $Body = ($uploadFailures-$invalidRepo).ToString() + " Failed To Upload." + "<br/>" + $invalidRepo.ToString() + " Invalid Repos." + "<br/>" +  ($content.Count-1-$uploadFailures).ToString() + " Successful Uploads." + "<br/>" + $Body

        Send-MailMessage -From $from -To $to -Attachments $attachment -Subject ( 'Uploaded with Errors - ' + $json.name ) -SmtpServer $smtpserver -Credential $Cred -BodyAsHtml $Body
        exit
    }else{
        #Send Email
        Send-MailMessage -From $from -To $to -Attachments $attachment -Subject ( 'Upload Summary - ' + $json.name ) -SmtpServer $smtpserver -Credential $Cred -BodyAsHtml (($content.Count-1).ToString() + " Successful Uploads." + "<br/>" + $Body)
    
        #Move to uploaded
        cd $templatePath
        Move-Item -Path $documentpath -Destination $uploadedPath

        return ($(Get-Date -format "yyyy-MM-dd") + ' - Uploading - ' + $index)
    }
    
}