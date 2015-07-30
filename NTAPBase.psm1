function Convert-DateString {
    param (
        [string]$Date,
        
        [string]$Format
    )
    
    $result = [DateTime]::Now
    
    $convertible = [DateTime]::TryParseExact(
        $Date,
        $Format,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::AllowWhiteSpaces,
        [ref]$result
    )
    
    if ($convertible) {
        Write-Output $result
    }
}

function ConvertTo-TypedValue {
    param (
        $Text
    )
    
    # Convert newline separated values to an array
    if ($Text -match "`n") {
        return ($Text -split '\n' | Skip-NullOrEmpty)
    }
    
    #These will fail on version strings in some locales other than en-US.
  #  # try to convert numbers
  #  $number = 0
  ##  if ([int64]::TryParse($verStr, [System.Globalization.NumberStyles]::Integer, [System.Globalization.CultureInfo]::GetCultureInfo('en-US'), [ref]$number)) {
  #  if ([int64]::TryParse($Text, [ref]$number)) {
  #      return $number
  #  }
  
  #  $number = 0
  ##  if ([decimal]::TryParse($verStr, [System.Globalization.NumberStyles]::Number, [System.Globalization.CultureInfo]::GetCultureInfo('en-US'), [ref]$number)) {
  #  if ([decimal]::TryParse($Text, [ref]$number)) {
  #      return $number
  #  }
  
    # try to convert to booleans
    $bool = $false
    if ([bool]::TryParse($Text, [ref]$bool)) {
        return $bool
    }
    
    #try to convert to date
    $date = $null
    if (($date = Convert-DateString -Date $Text) -or ($date = Convert-DateString -Date $Text -Format 'ddd MMM d HH:mm:ss yyyy')) {
        return $date
    }
    
    return $Text
}

function Convert-SystemCliTextInstance {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
        [AllowNull()]
        [string]$Data
    )
    
    if ($Data) {
        $ht = @{}
        $obj = @()
        
        foreach ($line in ($Data -split [Environment]::NewLine | Where-Object { $_ -notmatch '--' })) {
            $line = $line -replace "`'"
            
            switch -regex ($line) {
                {$line -match '^\s*$|entries were displayed'} {
                    if ($ht.Keys.Count -gt 0) {
                        $obj += (New-Object -TypeName PSObject -Property $ht)
                        
                        $ht = @{}
                    }
                    
                    break
                }
                {$line -match 'no entries matching your query'} {
                    break
                }
                #This is a hack for wrapped/multiline raw text
                {$line -notmatch '[:]\s+'} {
                    $ht[$name] += [String]::Format(' {0}', $line.Trim())
                    
                    break
                }
                default {
                    $lineSplit = $line -split '[:]\s+', 2 | ForEach-Object { $_.Trim() }
                    $name, $value = ((Get-Culture).TextInfo.ToTitleCase($lineSplit[0].ToLower()) -replace '\s*' -replace '\(.*\)[-]?' -replace '/' -replace '\\' -replace '\?$'), $lineSplit[1]
                    
                    $ht[$name] = ConvertTo-TypedValue -Text $value
                    
                    break
                }
            }
        }
        
        Write-Output $obj
    }
}