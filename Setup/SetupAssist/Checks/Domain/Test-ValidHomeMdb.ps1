﻿# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

. $PSScriptRoot\..\New-TestResult.ps1
. $PSScriptRoot\..\..\..\..\Shared\ActiveDirectoryFunctions\Search-AllActiveDirectoryDomains.ps1

function Test-ValidHomeMDB {
    $testName = "Valid Home MDB"
    $arbitration = 0x800000
    $discovery = 0x20000000
    $publicFolder = 0x1000000000
    $recipientTypes = $arbitration -bor $discovery -bor $publicFolder
    $filter = "(&(objectClass=user)(mailNickname=*)(msExchRecipientTypeDetails:1.2.840.113556.1.4.804:=$recipientTypes))"
    $propsToLoad = @("distinguishedName", "homeMDB")

    $results = Search-AllActiveDirectoryDomains -Filter $filter -PropertiesToLoad $propsToLoad

    if ($null -ne $results -and
        $results.Count -gt 0) {

        foreach ($result in $results) {
            $dbName = $result.Properties["homeMDB"]
            $params = @{
                TestName      = $testName
                Details       = ("Mailbox DN: $($result.Properties["distinguishedName"])`n" +
                    "Database DN: $dbName")
                ReferenceInfo = ("Run the following command in EMS.`n" +
                    "If EMS is down, launch PowerShell and run `"Add-PSSnapin *Exchange*`"`n" +
                    "    Set-Mailbox 'DN' -Database 'DB_Name'")
            }

            if ((-not([string]::IsNullOrEmpty($dbName))) -and
                ([ADSI]::Exists("LDAP://$dbName"))) {
                New-TestResult @params -Result "Passed"
            } else {
                New-TestResult @params -Result "Failed"
            }
        }
    } else {
        New-TestResult -TestName $testName -Result "Failed" -Details "Failed to find any critical mailboxes"
    }
}
