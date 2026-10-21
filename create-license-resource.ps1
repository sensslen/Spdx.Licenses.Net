# Packs the downloaded SPDX license data into the single resource that SpdxLicenseStore reads.
#
# Layout: int32 count, int32 payloadStart, then per license: id, name (BinaryWriter strings),
# byte flags, int32 payload offset, int32 text byte count, int32 template byte count.
# Each license's UTF-8 text and template follow as one deflate stream, so a license decompresses
# on its own and the template shares the compression window with the text it repeats.
param(
    [string]$LicensesFolder = "SpdxLicenseData",
    [string]$Output = "Spdx.Licenses/licenses.bin"
)

$utf8 = [System.Text.UTF8Encoding]::new($false)
$index = [System.IO.MemoryStream]::new()
$indexWriter = [System.IO.BinaryWriter]::new($index, $utf8)
$payload = [System.IO.MemoryStream]::new()

$files = Get-ChildItem -Path (Join-Path $LicensesFolder "Licenses") -Filter *.json | Sort-Object Name
foreach ($file in $files) {
    $license = Get-Content $file.FullName -Raw | ConvertFrom-Json
    $text = $utf8.GetBytes([string]$license.licenseText)
    $template = $utf8.GetBytes([string]$license.standardLicenseTemplate)
    $flags = 0
    if ($license.isDeprecatedLicenseId) { $flags = $flags -bor 1 }
    if ($license.isFsfLibre) { $flags = $flags -bor 2 }
    if ($license.isOsiApproved) { $flags = $flags -bor 4 }

    $indexWriter.Write([string]$license.licenseId)
    $indexWriter.Write([string]$license.name)
    $indexWriter.Write([byte]$flags)
    $indexWriter.Write([int]$payload.Position)
    $indexWriter.Write([int]$text.Length)
    $indexWriter.Write([int]$template.Length)

    $deflate = [System.IO.Compression.DeflateStream]::new($payload, [System.IO.Compression.CompressionLevel]::SmallestSize, $true)
    $deflate.Write($text, 0, $text.Length)
    $deflate.Write($template, 0, $template.Length)
    $deflate.Dispose()
}
$indexWriter.Flush()

$out = [System.IO.File]::Create((Join-Path (Get-Location) $Output))
$writer = [System.IO.BinaryWriter]::new($out)
$writer.Write([int]$files.Count)
$writer.Write([int](8 + $index.Length))
$writer.Flush()
$index.WriteTo($out)
$payload.WriteTo($out)
$writer.Dispose()
