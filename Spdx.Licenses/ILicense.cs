namespace Spdx.Licenses
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
