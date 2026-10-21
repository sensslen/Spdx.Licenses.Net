using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Text;

namespace Spdx.Licenses
{
    public static class SpdxLicenseStore
    {
        private const string ResourceName = "licenses.bin";

        public static readonly IReadOnlyDictionary<string, ILicense> Licenses = Load();

        internal static Stream OpenResource() =>
            typeof(SpdxLicenseStore).Assembly.GetManifestResourceStream(ResourceName)
            ?? throw new InvalidOperationException($"Embedded resource {ResourceName} is missing.");

        private static ReadOnlyDictionary<string, ILicense> Load()
        {
            using var reader = new BinaryReader(OpenResource(), Encoding.UTF8);
            var count = reader.ReadInt32();
            var payloadStart = reader.ReadInt32();
            var licenses = new Dictionary<string, ILicense>(count);
            for (var i = 0; i < count; i++)
            {
                var license = new License(
                    id: reader.ReadString(),
                    name: reader.ReadString(),
                    flags: reader.ReadByte(),
                    offset: payloadStart + reader.ReadInt32(),
                    textByteCount: reader.ReadInt32(),
                    templateByteCount: reader.ReadInt32());
                licenses.Add(license.Id, license);
            }

            return new ReadOnlyDictionary<string, ILicense>(licenses);
        }
    }
}
