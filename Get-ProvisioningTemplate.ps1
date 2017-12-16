#region Variables
$siteUrl = "http://wingtipserver/sites/demo"
$templateFileName = "ProvisioningTemplate.xml"
$librarySitePages = "SitePages"
$librarySiteAssets = "SiteAssets"
$scriptFolder = "/Scripts"
$folderFiles ="Files"
#endregion

#region functions
#Save page to locale and add data to provisioning template
function Get-Page($fileName) {
    $pageFile = "/" + $librarySitePages + "/" + $fileName
    $filesFolder = ".\" + $folderFiles

    If(!(test-path $filesFolder)){
        New-Item -ItemType Directory -Force -Path $filesFolder
    }
    
    $folderPath = $PSScriptRoot + "\" + $folderFiles
    #Save file to locale
    Get-PnPFile -Url $pageFile -AsFile  -Path $folderPath
    
    #Add file data to provisioning template
    $filePath = $folderPath + "\" + $fileName
    Add-PnPFileToProvisioningTemplate -Path $rootsiteTemplateFileName -Source $filePath -Folder $librarySitePages
}

#Save all web parts from page to locale
function Get-WebParts($fileName){
    $web = Get-PnPWeb 
    $serverRelativePageUrl = $web.ServerRelativeUrl + "/" + $librarySitePages + "/" + $fileName
    #Get all web parts
    $webParts = Get-PnPWebPart -ServerRelativePageUrl $serverRelativePageUrl
    $count = 0

    foreach($webPart in $webParts){
        $count++
        $xml = Get-PnPWebPartXml -ServerRelativePageUrl $serverRelativePageUrl -Identity $webPart.Id
        $newFileName = "webpart_" + $fileName + "_" + $count.ToString() + ".xml"
        #Save file to locale
        Set-Content -Path $newFileName $xml -Force
    }
}

#Get all script files to locale which is used for web parts
function Get-ScriptFiles{
    #get all files
    $query ="<View Scope='RecursiveAll'><Query><Where><Eq><FieldRef Name='FSObjType' /><Value Type='Integer'>0</Value></Eq></Where></Query><ViewFields><FieldRef Name='FileLeafRef' /><FieldRef Name='FileDirRef' /></ViewFields></View>"
    $listItems = Get-PnPListItem -List $librarySiteAssets -Query $query
    $libraryFolderPath = $librarySiteAssets + $scriptFolder
    $folderPath = $PSScriptRoot + "\" + $folderFiles
    
    foreach($listItem in $listItems){
        #get all items in the folder 'Scripts'
        if($listItem.FieldValues.FileDirRef -match $scriptFolder){
            $scriptFile = $libraryFolderPath + "/" + $listItem.FieldValues.FileLeafRef
            #Save file to locale
            Get-PnPFile -Url $scriptFile -AsFile -Path $folder

            #Add file data to provsioning template
            $filePath = $folderPath + "\" + $listItem.FieldValues.FileLeafRef
            Add-PnPFileToProvisioningTemplate -Path $rootsiteTemplateFileName -Source $filePath -Folder $libraryFolderPath
        }
    }
}

#Clean all permissions in provisionig template
function Clear-PermissionsInProvisioningTemplate{
    $template = Load-PnPProvisioningTemplate -Path $rootsiteTemplateFileName
    $template.Security.AdditionalAdministrators.Clear()
    $template.Security.AdditionalMembers.Clear()
    $template.Security.AdditionalOwners.Clear()
    $template.Security.AdditionalVisitors.Clear()
    Save-PnPProvisioningTemplate -Out $rootsiteTemplateFileName -InputInstance $template -Force
}
#endregion

#region call main functions
Connect-PnPOnline -Url $siteUrl -CurrentCredentials
Get-PnPProvisioningTemplate -Out $templateFileName -IncludeSearchConfiguration -IncludeNativePublishingFiles -PersistPublishingFiles -PersistBrandingFiles -ForceGet-Page -fileName $startPageFileName 

Get-Page -fileName $startPageFileName
Get-WebParts -fileName $startPageFileName

Get-Page -fileName $myTaskPageFileName
Get-WebParts -fileName $myTaskPageFileName

Get-ScriptFiles

Clear-PermissionsInProvisioningTemplate
Disconnect-PnPOnline
#endregion