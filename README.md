# Spdx.Licenses.Net

A .NET library for SPDX license data, including license texts and metadata. This project automates the download and packaging of SPDX license information for use in .NET applications.

## Features
- Provides SPDX license texts and metadata as .NET resources
- Automated scripts for updating license data
- Easy integration into .NET projects

## Usage

### Manual Update & Publish
To manually update and publish the package:
1. Run `download-licenses.ps1` to fetch the latest SPDX license data.
2. Run `create-csharp-project.ps1` to generate/update the C# project files.
3. Build and pack the project:
   ```powershell
   dotnet restore Spdx.Licenses/Spdx.Licenses.csproj
   dotnet build Spdx.Licenses/Spdx.Licenses.csproj --configuration Release
   dotnet pack Spdx.Licenses/Spdx.Licenses.csproj --configuration Release --output ./nupkg
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

## Maintainer
- GitHub: [sensslen](https://github.com/sensslen)
