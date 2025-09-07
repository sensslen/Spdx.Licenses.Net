# Accept licenses folder as a command line parameter
param(
    [string]$LicensesFolder = "SpdxLicenseData"
)

# Paths
$licensesJsonPath = Join-Path $LicensesFolder "licenses.json"
$projectName = "Spdx.Licenses"
$csprojName = "$projectName.csproj"

# Remove old project if it exists
if (Test-Path $projectName) {
    Remove-Item -Recurse -Force $projectName
}

# Read licenseListVersion from licenses.json
$licensesData = Get-Content $licensesJsonPath | ConvertFrom-Json
$licenseListVersion = $licensesData.licenseListVersion

# Read all detailed license files
$detailsDir = Join-Path $LicensesFolder "Licenses"
$licenseFiles = Get-ChildItem -Path $detailsDir -Filter *.json
$licenses = @()
foreach ($file in $licenseFiles) {
    $license = Get-Content $file.FullName | ConvertFrom-Json
    $licenses += $license
}

# Create new project directory
New-Item -ItemType Directory -Path $projectName | Out-Null

# Create .NET Standard 2.0 class library
dotnet new classlib -n $projectName -o $projectName --framework netstandard2.0
Remove-Item -Force (Join-Path $projectName "Class1.cs")

dotnet add $projectName package PolySharp
dotnet add $projectName package System.Collections.Immutable

# Set version in csproj
$csprojPath = Join-Path $projectName $csprojName
$csprojContent = Get-Content $csprojPath
$csprojContent = $csprojContent -replace '  </PropertyGroup>', @"
    <Version>$licenseListVersion</Version>
    <LangVersion>12</LangVersion>
    <Authors>Simon Ensslen</Authors>
    <PackageProjectUrl>https://github.com/sensslen/Spdx.Licenses.Net</PackageProjectUrl>
    <TreatWarningsAsErrors>True</TreatWarningsAsErrors>
    <Nullable>enable</Nullable>
    <PackageId>Sensslen.SPDX.Licenses.Net</PackageId>
    <RepositoryType>git</RepositoryType>
    <PackageLicenseExpression>Apache-2.0</PackageLicenseExpression>
    <PackageReadmeFile>README.md</PackageReadmeFile>
  </PropertyGroup>
"@
$csprojContent = $csprojContent -replace '</Project>', @"
  <ItemGroup>
    <Content Include="..\README.md">
      <Pack>true</Pack>
      <PackagePath>README.md</PackagePath>
    </Content>
    <EmbeddedResource Include="Licenses\*.txt" />
  </ItemGroup>
</Project>
"@

Set-Content $csprojPath $csprojContent

# Create Licenses subfolder for per-license classes
$licensesFolderPath = Join-Path $projectName "Licenses"
if (!(Test-Path $licensesFolderPath)) {
    New-Item -ItemType Directory -Path $licensesFolderPath | Out-Null
}

# Write ILicense interface
$interfaceCode = @"
namespace $projectName
{
    public interface ILicense
    {
        string Id { get; }
        string Name { get; }
        bool IsDeprecated { get; }
        bool IsFsfLibre { get; }
        bool IsOsiApproved { get; }
        string LicenseText { get; }
        string StandardLicenseTemplate { get; }
    }
}
"@
Set-Content (Join-Path $projectName "ILicense.cs") $interfaceCode

# Generate each license class
$licenseClassNames = @()
foreach ($license in $licenses) {
    $id = $license.licenseId
    $className = $id -replace '[^A-Za-z0-9_]', '_' # Safe C# identifier
    if ($className -match '^[0-9]') { $className = "License_$className" }
    $licenseClassNames += $className
    $name = $license.name
    $isDeprecated = if ($license.isDeprecatedLicenseId) { 'true' } else { 'false' }
    $isFsfLibre = if ($null -ne $license.isFsfLibre -and $license.isFsfLibre) { 'true' } else { 'false' }
    $isOsiApproved = if ($license.isOsiApproved) { 'true' } else { 'false' }
    $idRaw = '"""' + $id + '"""'
    $nameRaw = '"""' + $name + '"""'
    $classCode = @"
namespace $projectName.Licenses
{
    public class $className : ILicense
    {
        public string Id => "$idRaw";
        public string Name => "$nameRaw";
        public bool IsDeprecated => $isDeprecated;
        public bool IsFsfLibre => $isFsfLibre;
        public bool IsOsiApproved => $isOsiApproved;
        public string LicenseText => ReadResource("$projectName.Licenses.$className.LicenseText.txt");
        public string StandardLicenseTemplate => ReadResource("$projectName.Licenses.$className.StandardLicenseTemplate.txt");

        private static string ReadResource(string resourceName)
        {
            var assembly = typeof($className).Assembly;
            using var stream = assembly.GetManifestResourceStream(resourceName);
            if (stream == null) return string.Empty;
            using var reader = new System.IO.StreamReader(stream);
            return reader.ReadToEnd();
        }
    }
}
"@
    Set-Content (Join-Path $licensesFolderPath "$className.cs") $classCode
    Set-Content (Join-Path $licensesFolderPath "$className.LicenseText.txt") $license.licenseText
    Set-Content (Join-Path $licensesFolderPath "$className.StandardLicenseTemplate.txt") $license.standardLicenseTemplate
}

# Write main SpdxLicenseStore class referencing all license classes
$storeFilePath = Join-Path $projectName "SpdxLicenseStore.cs"
$dictEntries = $licenseClassNames | ForEach-Object { "            new KeyValuePair<string, ILicense>(`"$($_)`", new Licenses.$($_)())" }
$dictBody = $dictEntries -join ",`n"
$storeCode = @"
using System.Collections.Generic;
using System.Collections.Immutable;

namespace $projectName
{
    public static class SpdxLicenseStore
    {
        public static readonly ImmutableDictionary<string, ILicense> Licenses =
            ImmutableDictionary.CreateRange<string, ILicense>(new[]
            {
$dictBody
            });
    }
}
"@
Set-Content $storeFilePath $storeCode
