#region Variables
$siteUrl = "http://wingtipserver/sites/department"
$templateFileName = "ProvisioningTemplate.xml"
$librarySitePages = "SitePages"

$oldWebServerRelativeUrl = "/sites/demo"
$oldListId = "0d92fddd-cbba-4e12-8c42-a8ba28f403ed"
$oldListId_2 = "0D92FDDD-CBBA-4E12-8C42-A8BA28F403ED"
$newListName = "Projects"
#endregion

#region functions
#fileName of the page: web Part will be added to to the page
#webPart: XML-file
#zoneId: You can get zone ID using by SharePoint Designer
#ZoneIndex: Order of web parts 
function Set-WebPart($fileName, $webPart, $ZoneId, $ZoneIndex){
    $web = Get-PnPWeb
    $serverRelativePageUrl = $web.ServerRelativeUrl + "/" + $librarySitePages + "/" + $fileName
    $directory = Get-Location
    $filePath = $directory.Path + "\" + $webPart
    $newFilePath = $filePath.Replace(".xml", "_new.xml")
    Copy-Item -Path $filePath -Destination $newFilePath
    #Replace source web server relative URL  with new web server relative URL
    (Get-Content $newFilePath) -replace $oldWebServerRelativeUrl, $web.ServerRelativeUrl | Set-Content $newFilePath
    $isXsltListViewWebPart = Select-String $newFilePath -pattern "WebPartPages.XsltListViewWebPart"
    
    if($isXsltListViewWebPart){
        $list = Get-PnPList -Identity $newListName
        $views = Get-PnPView -List $newListName
        
        #Replace source list id with new list ID
        (Get-Content $newFile) -replace $oldListId, $list.Id | Set-Content $newFile
        (Get-Content $newFile) -replace $oldListId_2, $list.Id | Set-Content $newFile

        #Replace source view id with new default view ID
        (Get-Content $newFile) -replace '1DE11B0A-6492-4FF1-989C-51DC790E558C', $views[0].Id | Set-Content $newFile
    }
    
    Add-PnPWebPartToWebPartPage -ServerRelativePageUrl $serverRelativePageUrl -Path $newFile -ZoneId $ZoneId -ZoneIndex $ZoneIndex
    Remove-Item -Path $newFile
}
#endregion

#region call main functions
Connect-PnPOnline -Url $siteUrl -CurrentCredentials
Apply-PnPProvisioningTemplate -Path $templateFileName -ClearNavigation       

Set-WebPart -fileName $startPageFileName -webPart "webpart_UniDok.aspx_1.xml" -ZoneId "Header" -ZoneIndex 0
Set-WebPart -fileName $startPageFileName -webPart "webpart_UniDok.aspx_2.xml" -ZoneId "Header" -ZoneIndex 1
Set-WebPart -fileName $startPageFileName -webPart "webpart_UniDok.aspx_3.xml" -ZoneId "Header" -ZoneIndex 2
Set-WebPart -fileName $myTaskPageFileName -webPart "webpart_Meine Aufgaben.aspx_2.xml" -ZoneId "MiddleColumn" -ZoneIndex 0
Set-WebPart -fileName $myTaskPageFileName -webPart "webpart_Meine Aufgaben.aspx_3.xml" -ZoneId "LeftColumn" -ZoneIndex 0

Disconnect-PnPOnline
#endregion