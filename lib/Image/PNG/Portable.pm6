class Image::PNG::Portable;

use String::CRC32;
use Compress::Zlib;

#`[[[
https://rt.perl.org/Public/Bug/Display.html?id=123700
subset UInt of Int where * >= 0;
subset PInt of Int where * > 0;
subset UInt8 of Int where 0 <= * <= 255;
subset NEStr of Str where *.chars;
]]]

has Int $.width = die 'Width is required';
has Int $.height = die 'Height is required';

# + 1 allows filter bytes in the raw data, avoiding needless buf manip later
has $!line-bytes = $!width * 3 + 1;
has $!data-bytes = $!line-bytes * $!height;
has $!data = do { my $b = buf8.new; $b[$!data-bytes-1] = 0; $b; };

# magic string for PNGs
my $magic = Blob.new: 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A;

method set (
    Int $x where * < $!width,
    Int $y where * < $!height,
    Int $r, Int $g, Int $b
) {
    my $buffer = $!data;
    # + 1 skips aforementioned filter byte
    my $index = $!line-bytes * $y + 3 * $x + 1;

    $buffer[$index++] = $r;
    $buffer[$index++] = $g;
    $buffer[$index] = $b;

    True;
}

method write (Str $file) {
    my $fh = $file.IO.open(:w, :bin);

    $fh.write: $magic;

    $fh.write: chunk 'IHDR', bytes($!width, 4), bytes($!height, 4),
        8, 2, 0, 0, 0; # w, h, bpp, color, compress, filter, interlace

    # would love to skip compression for my purposes, but PNG mandates it
    my $zdata = compress $!data;
    $fh.write: chunk 'IDAT', @$zdata;

    $fh.write: chunk 'IEND';

    $fh.close;

    True;
}

# creates a chunk
sub chunk (Str $type, *@data) {
    my @length = bytes @data.elems, 4;

    my @type := $type.encode;
    my @td := Blob[uint8].new: |@type, |@data;
    my @crc = bytes String::CRC32::crc32 @td;

    Blob[uint8].new: |@length, |@td, |@crc;
}

# converts a number to a list of byte values with optional fixed width
sub bytes (Int $n is copy, Int $count = 0) {
    my @return;

    my $exp = 1;
    $exp++ while 256 ** $exp <= $n;

    if $count {
        my $diff = $exp - $count;
        die 'Overflow' if $diff > 0;
        @return.push(0 xx -$diff) if $diff < 0;
    }

    while $exp {
        my $scale = 256 ** --$exp;
        my $value = $n div $scale;
        @return.push: $value;
        $n -= $value * $scale;
    }

    @return;
}

