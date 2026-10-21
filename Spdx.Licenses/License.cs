using System;
using System.IO;
using System.IO.Compression;
using System.Text;

namespace Spdx.Licenses
{
    internal sealed class License : ILicense
    {
        private readonly byte _flags;
        private readonly int _offset;
        private readonly int _textByteCount;
        private readonly int _templateByteCount;

        // Both strings come out of one deflate stream, so they are decoded and published together.
        private Tuple<string, string>? _texts;

        public License(string id, string name, byte flags, int offset, int textByteCount, int templateByteCount)
        {
            Id = id;
            Name = name;
            _flags = flags;
            _offset = offset;
            _textByteCount = textByteCount;
            _templateByteCount = templateByteCount;
        }

        public string Id { get; }
        public string Name { get; }
        public bool IsDeprecated => (_flags & 1) != 0;
        public bool IsFsfLibre => (_flags & 2) != 0;
        public bool IsOsiApproved => (_flags & 4) != 0;
        public string LicenseText => Texts.Item1;
        public string StandardLicenseTemplate => Texts.Item2;

        private Tuple<string, string> Texts => _texts ??= Decompress();

        private Tuple<string, string> Decompress()
        {
            using var resource = SpdxLicenseStore.OpenResource();
            resource.Position = _offset;
            using var reader = new BinaryReader(new DeflateStream(resource, CompressionMode.Decompress));
            return Tuple.Create(
                Encoding.UTF8.GetString(reader.ReadBytes(_textByteCount)),
                Encoding.UTF8.GetString(reader.ReadBytes(_templateByteCount)));
        }
    }
}
