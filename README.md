# Spdx.Licenses.Net

A .NET library for SPDX license data, including license texts and metadata. This project automates the download and packaging of SPDX license information for use in .NET applications.

## Features
- Provides SPDX license texts and metadata as .NET resources
- Automated scripts for updating license data
- Easy integration into .NET projects

## Usage

```csharp
using Spdx.Licenses;

if (SpdxLicenseStore.Licenses.TryGetValue("MIT", out var license))
{
    Console.WriteLine($"{license.Name}: OSI approved {license.IsOsiApproved}");
    Console.WriteLine(license.LicenseText);
}
```

All license texts ship in one compressed resource. A license's text and template are decompressed on first access and cached.

### Manual Update & Publish
To manually update and publish the package:
1. Run `download-licenses.ps1` to fetch the latest SPDX license data.
2. Run `create-license-resource.ps1` to pack it into `Spdx.Licenses/licenses.bin`.
3. Build, test and pack, passing the SPDX license list version as the package version:
   ```powershell
   dotnet build Spdx.Licenses.Net.sln --configuration Release -p:Version=<version>
   dotnet test Spdx.Licenses.Net.sln --configuration Release --no-build
   dotnet pack Spdx.Licenses/Spdx.Licenses.csproj --configuration Release --no-build -p:Version=<version> --output ./nupkg
   ```
4. Publish the NuGet package:
   ```powershell
   dotnet nuget push ./nupkg/*.nupkg --api-key <your-nuget-api-key> --source https://api.nuget.org/v3/index.json
   ```

### GitHub Actions CI
An automated workflow is available in `.github/workflows/manual-publish.yml` to automate the above steps and publish to NuGet and GitHub Releases. Trigger it from the GitHub Actions tab.

## Contributing
Pull requests and issues are welcome. Please ensure any new license data is sourced from SPDX.

## License
See the `LICENSE` file for details.
