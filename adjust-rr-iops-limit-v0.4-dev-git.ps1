#Requires -Version 5.1
#Requires -RunAsAdministrator   

<#
.Synopsis
    Change de IOPS LIMIT RR Value
.KB Articles
    Broadcom Recommendation
    https://knowledge.broadcom.com/external/article/323117/adjusting-round-robin-iops-limit-from-de.html
    Dell recommendation
    https://dl.dell.com/manuals/common/sc-series-vmware-vsphere-best-practices_en-us.pdf

.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.AUTHOR
    Juliano Alves de Brito Ribeiro (find me at julianoalvesbr@live.com or https://github.com/julianoabr or https://youtube.com/@powershellchannel)
.VERSION
    0.3
.TO THINK

4.Jesus answered: “Watch out that no one deceives you.
5.For many will come in my name, claiming, ‘I am the Messiah,’ and will deceive many.
6.You will hear of wars and rumors of wars, but see to it that you are not alarmed. Such things must happen, but the end is still to come.
7.Nation will rise against nation, and kingdom against kingdom. There will be famines and earthquakes in various places.
8. All these are the beginning of birth pains.
9 “Then you will be handed over to be persecuted and put to death, and you will be hated by all nations because of me.
10. At that time many will turn away from the faith and will betray and hate each other,
11. and many false prophets will appear and deceive many people.
12.Because of the increase of wickedness, the love of most will grow cold,13but the one who stands firm to the end will be saved.14And this gospel of the kingdom will be preached in the whole world as a testimony to all nations, and then the end will come.

#>
Clear-Host

#VALIDATE MODULE
$moduleExists = Get-Module -Name Vmware.VimAutomation.Core

if ($moduleExists){
    
    Write-Output "The Module Vmware.VimAutomation.Core is already loaded"
    
}#if validate module
else{
    
    Import-Module -Name Vmware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction Stop
    
}#else validate module

Set-PowerCLIConfiguration -WebOperationTimeoutSeconds 900 -Verbose -Confirm:$false -ErrorAction Continue

$Script:pathOutput = "$env:systemdrive\temp\report\"

$currentDate = (Get-Date -Format "ddMMyyyy").ToString()

function Pause-PSScript
{

   Read-Host 'Pressione [ENTER] para continuar' | Out-Null

}

#Welcome to Script Function
Function Welcome-ToScript{

    $remoteSrvConnected = ($Env:CLIENTNAME)
    $localSrvConnected = ($env:COMPUTERNAME)
    $localUsrConnected = ($env:USERNAME)

    Write-Host "Welcome $localUsrConnected" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host "You are connected to: $localSrvConnected" -ForegroundColor White -BackgroundColor DarkRed
    Write-Host "You connected from:: $remoteSrvConnected" -ForegroundColor White -BackgroundColor DarkBlue
}

#VALIDATE IF OPTION IS NUMERIC
function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
} #end function is Numeric

#FUNCTION CONNECT TO VCENTER
function Connect-vCenterServer
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateSet('Menu','Auto')]
        $methodToConnect = 'Menu',

        [Parameter(Mandatory=$true,
                   Position=1)]
        [System.String[]]$vCenterServerList, 
                
        [Parameter(Mandatory=$false,
                   Position=2)]
        [System.String]$dnsSuffix,
        
        [Parameter(Mandatory=$false,
                   Position=3)]
        [System.Boolean]$LastConnectedServers = $false,

        [Parameter(Mandatory=$false,
                   Position=4)]
        [System.String]$connectionProtocol,

        [Parameter(Mandatory=$false,
                   Position=4)]
        [ValidateSet('80','443')]
        [System.String]$port = '443'
    )

#VALIDATE IF YOU ARE CONNECTED TO ANY VCENTER 
if ((Get-Datacenter) -eq $null)
    {
        Write-Host "Você não está conectado a nenhum vCenter Server" -ForegroundColor White -BackgroundColor DarkMagenta
    }#enf of IF
else{
        
        $previousvCenterConnected = $global:DefaultVIServer.Name

        Write-Host "Você está conectado ao vCenter:$previousvCenterConnected" -ForegroundColor White -BackgroundColor Green
        
        Write-Host -NoNewline "Irei desconecta-lo antes de continuar." -ForegroundColor White -BackgroundColor Red
            
        Disconnect-VIServer -Server * -Confirm:$false -Force -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

}#end of else validate if you are connected. 


if ($methodToConnect -eq 'Auto'){
        
    foreach ($vCenterServer in $vCenterServerList){
            
        $Script:workingServer = ""
        
        $Script:workingServer = $vCenterServer + '.' + $suffix

        $vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $Port -WarningAction Continue -ErrorAction Stop

   }#end of foreach vcenter list
       
}#end of If Method to Connect
else{
        
    $workingLocationNum = ""
        
    $tmpWorkingLocationNum = ""
        
    $Script:WorkingServer = ""
        
    $iterator = 0

    #MENU SELECT VCENTER
    foreach ($vCenterServer in $vCenterServerList){
	   
        $vcServerValue = $vCenterServer
	    
        Write-Output "            [$iterator].- $vcServerValue ";	
	            
        $iterator++	
                
        }#end foreach	
                
            Write-Output "            [$iterator].- Sair do Script";

            while(!(isNumeric($tmpWorkingLocationNum)) ){
	                
                $tmpWorkingLocationNum = Read-Host "Digite o número referente ao vCenter que deseja conectar"
                
            }#end of while

                $workingLocationNum = ($tmpWorkingLocationNum / 1)

                if(($WorkingLocationNum -ge 0) -and ($WorkingLocationNum -le ($iterator-1))  ){
	                
                    $Script:WorkingServer = $vCenterServerList[$WorkingLocationNum]
                
                }#end of IF
                else{
            
                    Write-Host "Exit selecionado ou um número inválido digitado. Fim do Script." -ForegroundColor Red -BackgroundColor White
            
                    Exit;
                }#end of else

        #Connect to Vcenter
        $Script:vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $port -WarningAction Continue -ErrorAction Stop -Verbose
  
    
    }#end of Else Method to Connect

}#End of Function Connect to vCenter


#FUNCTION TO CREATE CLUSTER LIST
function Create-ClusterList
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.String[]]$extvcClusterList
                
     )

$vCClusterList = @()

$vCClusterList = $extvcClusterList

$tmpWorkingClusterNum = ""
        
$Script:WorkingCluster = ""
        
$ic = 0

        #CREATE CLUSTER MENU LIST
        foreach ($vCCluster in $vCClusterList){
	   
            $vCClusterValue = $vCCluster
	    
        Write-Output "            [$ic].- $vCClusterValue ";	
	    
        $ic++	
        
        }#end foreach	
        
        Write-Output "            [$ic].- Exit this script ";

        while(!(isNumeric($tmpWorkingClusterNum)) ){
	    
            $tmpWorkingClusterNum = Read-Host "Type the vCenter Cluster Number to adjust Lun Queue Depth"
        
        }#end of while

            $workingClusterNum = ($tmpWorkingClusterNum / 1)

        if(($workingClusterNum -ge 0) -and ($workingClusterNum -le ($ic-1))  ){
	        
            $Script:WorkingCluster = $vCClusterList[$workingClusterNum]
        }
        else{
            
            Write-Host "Exit selected, or Invalid choice number. End of Script " -ForegroundColor Red -BackgroundColor White
            
            Exit;
        }#end of else      

}#end of Function Create Cluster List

function AdjustRRLun-IOPSLimit
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateRange(1,1000)]
        [int]$IOPSLimitValue
   
    )

Do {

[int]$userMenuChoice = 0

$lunlist = ""

$Script:waveToAdjust = ""

[System.String]$waveToAdjust = Read-Host "Digite o número ou o nome da onda que será ajustada (Exemplo: Onda1, CH-156)"

#MAIN MENU - WHILE YOU DON'T PRESS 4. IT WILL BACK TO MENU      
    Do {
    
    Write-Output "

----------MENU ADJUST ROUND ROBIN IOPS LIMIT----------

You are connected to vCenter: $WorkingServer

The IOPS Limit value will be adjust to: $IOPSLimitValue if necessary

1 = Generate Report Before Adjust IOPS Limit
2 = Generate Report After Adjust IOPS LIMIT
3 = Adjusting Round Robin IOPS limit in a Cluster: $workingCluster
4 = Exit

------------------------------------------------------"

[int]$userMenuChoice = Read-host -prompt "Select an Option and Press Enter - Only Accept 1,2,3 or 4"

        switch ($userMenuChoice){
        1 {
            
            Write-Host "O relatório será salvo em: $Script:pathOutput" -ForegroundColor White -BackgroundColor Red

            $csvFile = $Script:pathOutput + "LUNCONFIG-BEFORE-ADJUST-RR-IOPS-$waveToAdjust-$currentDate.csv"

            #Check to see if the file exists, if it does then overwrite it.
            if (Test-Path $csvfile) {
    
                Write-Output "Overwriting $csvfile ..."
    
                Start-Sleep -Milliseconds 400

                Remove-Item $csvfile -Confirm -Verbose
            }  


            foreach ($esxiHost in $allESXiHosts){
            
                #create esxi host object
                $esxiHostObj = Vmware.VimAutomation.Core\Get-VMHost -Name $esxiHost

                #Datastores
                $dsNameList = @()

                $dsNameList = (VMware.VimAutomation.Core\Get-Vmhost -Name $esxiHost | 
                Get-Datastore  | Where-Object -FilterScript {($PSItem.ExtensionData.Info.Vmfs.Local -eq $false) -and ($PSItem.ExtensionData.Summary.MultipleHostAccess) -and ($psitem.Name -notlike '*CLUSTERED*')} | Select-Object -ExpandProperty Name | Sort-Object)

                $totalDSList = $dsNameList.Count

                Write-Host "I found: $totalDSList Datastores" -ForegroundColor White -BackgroundColor DarkBlue

                Pause-PSScript

                $lunNAAList = @()
        
                foreach ($dsName in $dsNameList)
                {
            
                    $dsObj = Get-datastore -Name $dsName
            
                    $dsNAA = $dsObj.ExtensionData.Info.Vmfs.Extent[0].DiskName

                    $lunNAAList += $dsNAA
                           
                }#end of foreach get NAA ID

               
                foreach ($lunNAA in $lunNAAList){
                    
                    Write-Host "NAA VALUE: $lunNAA" -ForegroundColor White -BackgroundColor DarkGreen

                    Get-ScsiLun -CanonicalName $lunNAA -VmHost $esxiHostObj | Select-Object -Property VmHost,CanonicalName,MultipathPolicy,CommandsToSwitchPath | Export-Csv -NoTypeInformation -Path $csvFile -Append -Verbose
        
                }#end ForeachLuns
        
            }#end ForeachHosts

            explorer $Script:pathOutput
    
    }#end of 1
        2 {
           
            Write-Host "O relatório será salvo em: $Script:pathOutput" -ForegroundColor White -BackgroundColor Red
            
            #output path to report 
            $csvFile = $Script:pathOutput + "LUNCONFIG-AFTER-ADJUST-RR-IOPS-$waveToAdjust-$currentDate.csv"

            #Check to see if the file exists, if it does then overwrite it.
            if (Test-Path $csvfile) {
    
                Write-Output "Overwriting $csvfile ..."
    
                Start-Sleep -Milliseconds 400

                Remove-Item $csvfile -Confirm -Verbose
            }  


            foreach ($esxiHost in $Script:allESXiHosts){
                
                #create esxi host obj
                $esxiHostObj = Vmware.VimAutomation.Core\Get-VMHost -Name $esxiHost

                #Datastores
                $dsNameList = @()

                $dsNameList = (VMware.VimAutomation.Core\Get-Vmhost -Name $esxiHost | 
                Get-Datastore  | Where-Object -FilterScript {($PSItem.ExtensionData.Info.Vmfs.Local -eq $false) -and ($PSItem.ExtensionData.Summary.MultipleHostAccess) -and ($psitem.Name -notlike '*CLUSTERED*')} | Select-Object -ExpandProperty Name | Sort-Object)

                $totalDSList = $dsNameList.Count

                Write-Host "I found: $totalDSList Datastores" -ForegroundColor White -BackgroundColor DarkBlue

                Pause-PSScript
            
                $lunNAAList = @()
        
                foreach ($dsName in $dsNameList)
                {
            
                    $dsObj = Get-datastore -Name $dsName
            
                    $dsNAA = $dsObj.ExtensionData.Info.Vmfs.Extent[0].DiskName

                    $lunNAAList += $dsNAA
                           
                }
                    
                foreach ($lunNAA in $lunNAAList){

                    Write-Host "NAA VALUE: $lunNAA" -ForegroundColor White -BackgroundColor DarkGreen
        
                    Get-ScsiLun -CanonicalName $lunNAA -VmHost $esxiHostObj | Select-Object -Property VmHost,CanonicalName,MultipathPolicy,CommandsToSwitchPath | Export-Csv -NoTypeInformation -Path $csvFile -Append -Verbose
        
                }#end ForeachLuns
        
            }#end ForeachHosts

    explorer $Script:pathOutput
    
    }#end of 2
        3 {
        
        Write-Host "Esta opção ajusta o Round Robin para o valor digitado: $intIOPSLimitValue" -ForegroundColor White -BackgroundColor Red
        
        #path to output report
        $csvFile = $Script:pathOutput + "LUNCONFIG-ADJUST-RR-IOPS-$waveToAdjust-$currentDate.csv"

        #Check to see if the file exists, if it does then overwrite it.
        if (Test-Path $csvfile) {
    
            Write-Output "Overwriting $csvfile ..."
    
            Start-Sleep -Milliseconds 400

            Remove-Item $csvfile -Confirm -Verbose
        }#end of if test-path  


        foreach ($esxiHost in $Script:allESXiHosts){
            
            #create esxi host obj
            $esxiHostObj = Vmware.VimAutomation.Core\Get-VMHost -Name $esxiHost

            #Datastores
            $dsNameList = @()

            $dsNameList = (VMware.VimAutomation.Core\Get-Vmhost -Name $esxiHost | 
            Get-Datastore  | Where-Object -FilterScript {($PSItem.ExtensionData.Info.Vmfs.Local -eq $false) -and ($PSItem.ExtensionData.Summary.MultipleHostAccess) -and ($psitem.Name -notlike '*CLUSTERED*')} | Select-Object -ExpandProperty Name | Sort-Object)

            $totalDSList = $dsNameList.Count

            Write-Host "I found: $totalDSList Datastores" -ForegroundColor White -BackgroundColor DarkBlue

            Pause-PSScript

            $lunNAAList = @()
        
            foreach ($dsName in $dsNameList)
            {
            
                $dsObj = Get-datastore -Name $dsName
            
                $dsNAA = $dsObj.ExtensionData.Info.Vmfs.Extent[0].DiskName

                $lunNAAList += $dsNAA
            
            }
            
            foreach ($lunNAA in $lunNAAList){
        
                Get-ScsiLun -CanonicalName $lunNAA -VmHost $esxiHostObj | Set-ScsiLun -CommandsToSwitchPath $IOPSLimitValue -Verbose
                
            }#end ForeachLuns
        
        }#end ForeachHosts

        explorer $Script:pathOutput
    
    
    }#end of 3
        4 {
    
            Disconnect-VIServer -Force -Confirm:$false -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

            Write-Output "You choose finish the Script"
    
            Start-Sleep -Seconds 2
    
            Exit


    }#end of 4
        }#end of switch

    }until($userMenuChoice -lt 1 -or $userMenuChoice -gt 4)#end of Do Until

}while ($userMenuChoice -ne 4)#end of Do While


}#End of Function AdjustRRLun-IOPSLimit


################## Main script logic ##############################

Welcome-ToScript

Write-Host "`n"

#DEFINE VCENTER LIST
$vcServerList = @();

#ADD OR REMOVE VCs        
$vcServerList = ('server1','server2') | Sort-Object

#SELECT TYPE OF CONNECTIONS
Do
{
 
 $tmpMethodToConnect = Read-Host -Prompt "Digite (Menu) se você deseja escolher o vCenter a se conectar. 
 Digite (Auto) se você deseja digitar o nome do vCenter ao qual irá se conectar"

    if ($tmpMethodToConnect -notmatch "^(?:menu\b|auto\b)"){
    
        Write-Host "Você digitou uma palavra inválida. Digite somente (menu) ou (auto)" -ForegroundColor White -BackgroundColor Red
    
    }
    else{
    
        Write-Host "Você digitou uma palavra válida. Irei prosseguir =D" -ForegroundColor White -BackgroundColor DarkBlue
    
    }
    
}While ($tmpMethodToConnect -notmatch "^(?:menu\b|auto\b)")#end of while choose method to connect


if ($tmpMethodToConnect -match "^\bauto\b$"){

    [System.String]$tmpVC = Read-Host "Digite o Hostname do vCenter ao qual você deseja se conectar"

    $tmpSuffix = ""

    [System.String]$tmpSuffix = Read-Host "Digite o sufixo do vCenter ao qual deseja se conectar"

    if ($tmpSuffix -like $null){
        
        Connect-vCenterServer -vCenterServerList $tmpVC -methodToConnect Auto -port 443 -Verbose
            
    }#end of IF
    else{
    
        Connect-vCenterServer -vCenterServerList $tmpVC -methodToConnect Auto -dnsSuffix $tmpSuffix -port 443 -Verbose
    
    }#end of Else
    

}#end of IF
else{

    Connect-vCenterServer -vCenterServerList $vcServerList -methodToConnect Menu -port 443 -Verbose

}#end of Else

#call function to create cluster list
Write-Output "`n"

Write-Host "SELECT THE CLUSTER THAT YOU WANT TO WORK" -ForegroundColor DarkBlue -BackgroundColor White

Write-Output "`n"

$tmpvCClusterList = @()
        
$tmpvCClusterList = (VMware.VimAutomation.Core\Get-Cluster | Select-Object -ExpandProperty Name| Sort-Object)

[System.Int32]$numberOfClusters = $tmpvCClusterList.Count

#only call function if number of clusters is equal to 1
if ($numberOfClusters -eq 1){

    Write-Host "I found only one Cluster in this vCenter" -ForegroundColor White -BackgroundColor DarkGreen

    $Script:WorkingCluster= $tmpvCClusterList[0]

}
elseif($numberOfClusters -eq 0){

    Write-Host "I didn't found any Cluster in this vCenter" -ForegroundColor White -BackgroundColor Red
    
    Write-Host "I will exit this script" -ForegroundColor White -BackgroundColor Red
    
    Exit

}
else{

    Create-ClusterList -extvcClusterList $tmpvCClusterList

}

$script:allESXiHosts = (VMware.VimAutomation.Core\Get-VMHost -Location $workingCluster | Select-Object -ExpandProperty Name | Sort-Object)

$tmpIOPSLimitValue = Read-Host "Digite um valor para ajustar o IOPS Limits (Range aceito: 1 a 1000)" 

$intIOPSLimitValue = ($tmpIOPSLimitValue / 1)


AdjustRRLun-IOPSLimit -IOPSLimitValue $intIOPSLimitValue
