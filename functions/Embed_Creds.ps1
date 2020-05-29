do {
Write-Host "I am here to compare the password you are entering..."
$username = Read-Host 'Username'
$pwd1 = Read-Host "Password" -AsSecureString
$pwd2 = Read-Host "Re-enter Password" -AsSecureString
$pwd1_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd1))
$pwd2_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd2))
}
while ($pwd1_text -ne $pwd2_text)
Write-Host "Passwords matched"
$secureStringPwd = $pwd2_text | ConvertTo-SecureString -AsPlainText -Force 
$secureStringText = $secureStringPwd | ConvertFrom-SecureString 
$storedCreds = 'D:\GDO Scripts\BulkUpload\GDOAutomatedUpload\smtp\' + $username.replace('@grace.com.au','') +  '_SMTP.txt' 
Set-Content $storedCreds $secureStringText