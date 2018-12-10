---
external help file: AB-SCCM-help.xml
Module Name: AB-SCCM
online version:
schema: 2.0.0
---

# Reset-CMClientPolicy2

## SYNOPSIS
Reset the Client's Local Policy

## SYNTAX

```
Reset-CMClientPolicy2 [[-ComputerName] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function makes a WMI call to the remote server name that was passed as a
function parameter. 
This will reset the client policy and force it to redownload from the MP.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -ComputerName
{{Fill ComputerName Description}}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
