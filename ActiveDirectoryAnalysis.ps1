# Active Directory Password Compliance Checker
#
# Asks for a user's name, finds the account in accounts.csv and checks the
# password against these rules:
#   - at least 10 characters
#   - at least 5 digits
#   - at least 5 letters
#   - no forbidden substrings from forbidden_password_substrings.csv
#
# Green = compliant, red = not compliant, dark yellow = password older than 50 days.
# The limits can be changed in the variables below.

$accountsPath   = Join-Path $PSScriptRoot "accounts.csv"
$substringsPath = Join-Path $PSScriptRoot "forbidden_password_substrings.csv"

$MinLength        = 10
$MinDigits        = 5
$MinLetters       = 5
$MaxPasswordAge   = 50

foreach ($path in $accountsPath, $substringsPath) {
    if (-not (Test-Path $path)) {
        Write-Host "File not found: $path" -ForegroundColor Red
        return
    }
}

function ConvertTo-SearchName {
    param([string]$Name)

    return ($Name.Trim() -replace '\s+', ' ').ToLower()
}

function Find-Account {
    param($Accounts, [string]$Name)

    $name = ConvertTo-SearchName $Name

    $exact = @($Accounts | Where-Object { (ConvertTo-SearchName $_.User) -eq $name })
    if ($exact.Count -gt 0) { return $exact[0] }

    return @($Accounts | Where-Object { (ConvertTo-SearchName $_.User).Contains($name) })
}

function Test-Password {
    param([string]$Password, [string[]]$ForbiddenSubstrings)

    $errors = @()
    $chars  = $Password.ToCharArray()

    if ($Password.Length -lt $MinLength) {
        $errors += "Password has fewer than $MinLength characters."
    }

    $digits = @($chars | Where-Object { $_ -match '\d' }).Count
    if ($digits -lt $MinDigits) {
        $errors += "Password has fewer than $MinDigits digits."
    }

    $letters = @($chars | Where-Object { $_ -match '[a-z]' }).Count
    if ($letters -lt $MinLetters) {
        $errors += "Password has fewer than $MinLetters letters."
    }

    $lowerPassword = $Password.ToLower()
    foreach ($sub in $ForbiddenSubstrings) {
        if ($lowerPassword.Contains($sub)) {
            $errors += "Password contains forbidden substring: $sub."
        }
    }

    return $errors
}

$accounts   = Import-Csv $accountsPath -Delimiter ";" | Where-Object { $_.User }
$substrings = (Import-Csv $substringsPath -Delimiter ";").Substring |
    ForEach-Object { $_.Trim().ToLower() } |
    Where-Object { $_ }

Write-Host "Enter the user's first and last name:" -ForegroundColor Cyan
$inputUser = Read-Host

if ([string]::IsNullOrWhiteSpace($inputUser)) {
    Write-Host "No name entered!" -ForegroundColor Red
    return
}

$found = @(Find-Account -Accounts $accounts -Name $inputUser)

if ($found.Count -eq 0) {
    Write-Host "User not found!" -ForegroundColor Red
    return
}

if ($found.Count -gt 1) {
    Write-Host "Multiple users match, please be more specific:" -ForegroundColor Yellow
    $found | ForEach-Object { Write-Host " - $($_.User)" }
    return
}

$user = $found[0]

Write-Host "`nUser information:" -ForegroundColor Cyan
Write-Host "User: $($user.User)"
Write-Host "Password: $($user.Password)"
Write-Host "Password last update (days ago): $($user.PasswordLastUpdateinDaysAgo)"

$passwordErrors = @(Test-Password -Password $user.Password -ForbiddenSubstrings $substrings)

$days = 0
$validAge = [int]::TryParse($user.PasswordLastUpdateinDaysAgo, [ref]$days)

Write-Host "`nVerification result:"

if ($passwordErrors.Count -eq 0) {
    Write-Host "`nCompliant!" -ForegroundColor Green
} else {
    Write-Host "`nNot compliant!`n" -ForegroundColor Red
    foreach ($passwordError in $passwordErrors) {
        Write-Host (" - " + $passwordError) -ForegroundColor Red
    }
}

if (-not $validAge) {
    Write-Host "`nInvalid password age value: '$($user.PasswordLastUpdateinDaysAgo)'." -ForegroundColor Red
} elseif ($days -gt $MaxPasswordAge) {
    Write-Host "`nPassword is older than $MaxPasswordAge days, it should be updated." -ForegroundColor DarkYellow
}