using Xunit;

namespace Spdx.Licenses.Tests
{
    public class SpdxLicenseStoreTests
    {
        [Fact]
        public void EveryLicenseDecodesUnderItsId()
        {
            Assert.NotEmpty(SpdxLicenseStore.Licenses);
            foreach (var (id, license) in SpdxLicenseStore.Licenses)
            {
                Assert.Equal(id, license.Id);
                Assert.NotNull(license.LicenseText);
                Assert.NotNull(license.StandardLicenseTemplate);
            }

            var mit = SpdxLicenseStore.Licenses["MIT"];
            Assert.Equal("MIT License", mit.Name);
            Assert.True(mit.IsOsiApproved);
            Assert.StartsWith("MIT License", mit.LicenseText);
            Assert.Contains("Permission is hereby granted", mit.StandardLicenseTemplate);
        }
    }
}
