# Active Directory Password Compliance Checker

A PowerShell script that checks whether a user's password complies with a password policy and whether it is due for renewal. It simulates an Active Directory password audit using a CSV file as the account database.

> **Note:** This is an educational project. The account data is fictional and passwords are stored in plain text only for demonstration purposes. Real systems must never store passwords in plain text.

## Features

- Looks up a user by full or partial name (case-insensitive).
- Displays the user's name, password and password age.
- Validates the password against a configurable policy.
- Lists every rule the password breaks, not just the first one.
- Warns when the password is older than the allowed maximum age.
- Uses colored output: green for compliant, red for non-compliant, dark yellow for expired passwords.

## Password Policy

A password is **compliant** only if it meets all of the following rules:

| Rule | Default |
|---|---|
| Minimum length | 10 characters |
| Minimum number of digits | 5 |
| Minimum number of letters (A-Z, a-z) | 5 |
| Forbidden substrings | None of the entries in `forbidden_password_substrings.csv` (case-insensitive) |

Independently of compliance, a password is flagged for update when it was last changed **more than 50 days** ago.

## Project Structure

```
active-directory/
├── ActiveDirectoryAnalysis.ps1         # The compliance checker script
├── accounts.csv                        # Account database (users, passwords, password age)
├── forbidden_password_substrings.csv   # Substrings not allowed in passwords
├── Requirements.txt                    # Project requirements
├── LICENSE                             # MIT License
└── README.md
```

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- No additional modules are required

## Usage

1. Clone or download the repository.
2. Open a PowerShell terminal in the project folder.
3. Run the script:

   ```powershell
   .\ActiveDirectoryAnalysis.ps1
   ```

   If script execution is blocked by the execution policy, run it with (use `pwsh` instead of `powershell` for PowerShell 7):

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\ActiveDirectoryAnalysis.ps1
   ```

4. Enter a user's name when prompted (for example `James Smith`).

### User Lookup

- The search is case-insensitive, and extra spaces are ignored (for example `  james   SMITH ` finds `James Smith`).
- An **exact match** on the full name is used if one exists.
- Otherwise, a **partial match** is used (for example `Smith` finds `James Smith`).
- If several users match (for example `James`), they are listed and you are asked to be more specific.

## Example Output

The examples below are real runs of the script using the sample data in `accounts.csv`. The second line of each example is the name typed by the user.

### 1. Compliant password, recently changed

The password meets every rule and was changed 5 days ago, so no warning is shown.

```
Enter the user's first and last name:
James Smith

User information:
User: James Smith
Password: Kx7m2Rq9Lp4z8
Password last update (days ago): 5

Verification result:

Compliant!
```

### 2. Compliant password that has expired

The password is valid, but it was last changed 120 days ago, so an update warning is shown in dark yellow.

```
Enter the user's first and last name:
Olivia Johnson

User information:
User: Olivia Johnson
Password: 7vT3kP9wQ1zR6
Password last update (days ago): 120

Verification result:

Compliant!

Password is older than 50 days, it should be updated.
```

### 3. Password exactly at the limits

`a1b2c3d4e5` has exactly 10 characters, 5 digits and 5 letters, and is exactly 50 days old. All limits are inclusive, so the password is compliant and no age warning is shown.

```
Enter the user's first and last name:
William Brown

User information:
User: William Brown
Password: a1b2c3d4e5
Password last update (days ago): 50

Verification result:

Compliant!
```

### 4. Several forbidden substrings

Every forbidden substring found in the password is reported, not just the first one.

```
Enter the user's first and last name:
Oliver Harris

User information:
User: Oliver Harris
Password: adminpassword12345
Password last update (days ago): 70

Verification result:

Not compliant!

 - Password contains forbidden substring: admin.
 - Password contains forbidden substring: password.

Password is older than 50 days, it should be updated.
```

### 5. Password contains the user's own name

The user's first name is in the forbidden substrings list.

```
Enter the user's first and last name:
Thomas Wright

User information:
User: Thomas Wright
Password: thomas55667788
Password last update (days ago): 15

Verification result:

Not compliant!

 - Password contains forbidden substring: thomas.
```

### 6. Password contains another user's name

`Brown` is the last name of William Brown. The names of all users are forbidden, and the check is case-insensitive.

```
Enter the user's first and last name:
Grace Hughes

User information:
User: Grace Hughes
Password: Brown12345xyz
Password last update (days ago): 40

Verification result:

Not compliant!

 - Password contains forbidden substring: brown.
```

### 7. Password breaks every rule

All broken rules are listed, followed by the age warning.

```
Enter the user's first and last name:
Amelia Scott

User information:
User: Amelia Scott
Password: abc
Password last update (days ago): 200

Verification result:

Not compliant!

 - Password has fewer than 10 characters.
 - Password has fewer than 5 digits.
 - Password has fewer than 5 letters.

Password is older than 50 days, it should be updated.
```

### 8. Empty password

An empty password fails the length, digit and letter rules.

```
Enter the user's first and last name:
Hannah Bennett

User information:
User: Hannah Bennett
Password:
Password last update (days ago): 10

Verification result:

Not compliant!

 - Password has fewer than 10 characters.
 - Password has fewer than 5 digits.
 - Password has fewer than 5 letters.
```

### 9. Invalid password age

The password is compliant, but the age column contains `unknown` instead of a number, so the age cannot be checked.

```
Enter the user's first and last name:
Samuel Price

User information:
User: Samuel Price
Password: Zr8Ty3Mn6Vb1Kq5
Password last update (days ago): unknown

Verification result:

Compliant!

Invalid password age value: 'unknown'.
```

### 10. Known limitation: character substitution

`Pa55w0rd` is `password` written with digits. The script does not detect character substitutions, so the password is reported as compliant.

```
Enter the user's first and last name:
James Carter

User information:
User: James Carter
Password: Pa55w0rd2024!
Password last update (days ago): 90

Verification result:

Compliant!

Password is older than 50 days, it should be updated.
```

### 11. Several users match

`James` matches both James Smith and James Carter, so the script lists them and stops.

```
Enter the user's first and last name:
James
Multiple users match, please be more specific:
 - James Smith
 - James Carter
```

### 12. Partial name

`Smith` matches only James Smith, so that user is selected.

```
Enter the user's first and last name:
Smith

User information:
User: James Smith
Password: Kx7m2Rq9Lp4z8
Password last update (days ago): 5

Verification result:

Compliant!
```

### 13. User not found

No account has this name.

```
Enter the user's first and last name:
Michael Brown
User not found!
```

### 14. Empty input

Pressing Enter without typing a name stops the script.

```
Enter the user's first and last name:

No name entered!
```

## Data Files

Both files use `;` as the delimiter and must be in the same folder as the script.

### `accounts.csv`

| Column | Description |
|---|---|
| `User` | The user's full name |
| `Password` | The user's password |
| `PasswordLastUpdateinDaysAgo` | Number of days since the password was last changed |

```csv
User;Password;PasswordLastUpdateinDaysAgo
James Smith;Kx7m2Rq9Lp4z8;5
```

### `forbidden_password_substrings.csv`

A single `Substring` column with one entry per line. It contains common weak words (`admin`, `password`, `qwerty`, etc.) and the first and last names of all users.

```csv
Substring
admin
password
```

## Configuration

The policy limits are defined as variables at the top of `ActiveDirectoryAnalysis.ps1`:

```powershell
$MinLength        = 10
$MinDigits        = 5
$MinLetters       = 5
$MaxPasswordAge   = 50
```

## Test Cases

The sample `accounts.csv` covers the following scenarios:

| User | Scenario | Expected Result |
|---|---|---|
| James Smith | Valid password, recently changed | Compliant |
| Olivia Johnson | Valid password, old | Compliant, age warning |
| William Brown | Exactly at every limit (10 chars, 5 digits, 5 letters, 50 days) | Compliant, no age warning |
| Emily Davis | Valid password, 51 days old | Compliant, age warning |
| Henry Wilson | Too short | Not compliant |
| Charlotte Taylor | Only 4 digits | Not compliant |
| George Clark | Only 3 letters | Not compliant |
| Sophie Walker | Contains a common word in mixed case (`Qwerty`) | Not compliant |
| Thomas Wright | Contains the user's own name | Not compliant |
| Grace Hughes | Contains another user's name | Not compliant |
| Oliver Harris | Contains several forbidden substrings | Not compliant, age warning |
| Amelia Scott | Breaks every rule | Not compliant, age warning |
| Jack Turner | Digits only | Not compliant |
| Lucy Morgan | Letters only | Not compliant |
| Daniel Cooper | Contains special characters | Compliant |
| Hannah Bennett | Empty password | Not compliant |
| Samuel Price | Invalid password age value | Compliant, invalid age message |
| James Carter | `password` written with digits (`Pa55w0rd`) | Compliant, age warning (known limitation) |

## Known Limitations

- **Character substitutions are not detected.** Variants such as `Pa55w0rd` or `@dmin` bypass the forbidden substring check.
- **Only ASCII letters are counted.** Accented letters (for example `é`, `ö`) do not count towards the minimum number of letters.
- **Passwords are stored in plain text.** This is acceptable only for a demonstration; a real system would store salted hashes.
- **Not connected to a real Active Directory.** The data comes from a CSV file, not from a domain controller.

## License

This project is licensed under the [MIT License](LICENSE).
