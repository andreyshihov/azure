#
# NOTE - ALL SCRIPTS MUST BE IDEMPOTENT
#
param (
    [Parameter(Mandatory = $true)]
    [String[]] $PartnerDirectories,

    [Parameter(Mandatory = $true)]
    $StorageAccountName
)

$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

Foreach ($container in $PartnerDirectories) {

    $directories = @("Incoming", "Report", "OK", "Fail")

    Foreach ($directory in $directories) {
        # BELOW WE WILL HAVE EXPECTED NON-TERMINATING ERROR - which is OK for now. It indicates that directory is not found.
        # TODO this could be improved 
        $dir = Get-AzDataLakeGen2Item -Context $ctx -FileSystem $container -Path $directory
        if ($Null -eq $dir) {
            New-AzDataLakeGen2Item -Context $ctx -FileSystem $container -Path $directory -Directory
        }  
    }
}