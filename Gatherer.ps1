function Get-Info {
    param (
        [ValidateNotNullOrEmpty()][string]$InfoSource = "All"
    )

    $ComputerName = $env:COMPUTERNAME

    $AllResults = @()

    $AllResults += Get-CPUInfo
    $AllResults += Get-GPUInfo
    $AllResults += Get-VolumeInfo
    $AllResults += Get-Users
    
    return $AllResults | ConvertTo-Json
  
}

function Get-CPUInfo {
    $returnObject = @{}

    $_CmdOutput = Get-WmiObject Win32_Processor 
    $_CmdOutputRows = $_CmdOutput | Measure-Object | Select-Object Count

    if ($_CmdOutputRows.Count -ge 2) {
        $_CmdOutput | foreach {
            $DeviceID = $_.DeviceID        
            $returnObject.$DeviceID = $_.Name
        }
    } else {
        $returnObject[$_CmdOutput.DeviceID] = $_CmdOutput.Name
    }

    return $returnObject
}

function Get-GPUInfo {
    $returnObject = @{}

    $_CmdOutput = Get-WmiObject Win32_VideoController
    $_CmdOutputRows = $_CmdOutput | Measure-Object | Select-Object Count

    $returnObject["Name"] = $_CmdOutput.Name
    $returnObject["Status"] = $_CmdOutput.Status

    return $returnObject
}

function Get-VolumeInfo {
    $returnObject = @{} 
        
    $_CmdOutput = Get-WmiObject Win32_LogicalDisk
    $_CmdOutputRows = $_CmdOutput | Measure-Object | Select-Object Count

    if ($_CmdOutputRows.Count -ge 2) {
        $_CmdOutput | foreach {
            $DriveName = "Drive"+ $_.DeviceID.Trim(":")
            $returnObject.$DriveName = @{} 
            $returnObject.$DriveName.VolumeName = $_.VolumeName
            $returnObject.$DriveName.Size = $_.Size
            $returnObject.$DriveName.FreeSpace = $_.FreeSpace 
        }
    } else {
        $returnObject[$_CmdOutput.DeviceID] = @{ 
                VolumeName = $_CmdOutput.VolumeName
                Size = $_CmdOutput.Size
                FreeSpace = $_CmdOutput.FreeSpace
        }
    }

    return $returnObject
}

function Get-Users {
    $returnObject = @{}

    $_CmdOutput = Get-WmiObject Win32_UserAccount
    $_CmdOutputRows = $_CmdOutput | Measure-Object | Select-Object Count

    if ($_CmdOutputRows.Count -ge 2) {
        $_CmdOutput | foreach {
            $Name = $_.Name
            $returnObject.$Name = @{} 
            $returnObject.$Name.SID = $_.SID 
 
        }
    } else {
        $returnObject[$_CmdOutput.Caption] = @{ 
                SID = $_CmdOutput.SID
        }
    }
    return $returnObject
}

Get-Info