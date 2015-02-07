class Image::PNG::Portable;

use String::CRC32;
use Compress::Zlib;
use NativeCall;

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

    write-chunk $fh, 'IHDR', @(bytes($!width, 4).list, bytes($!height, 4).list,
        8, 2, 0, 0, 0); # w, h, bits/channel, color, compress, filter, interlace

    # would love to skip compression for my purposes, but PNG mandates it
    # splitting the data into multiple chunks would be good past a certain size
        # for now I'd rather expose weak spots in the pipeline wrt large data sets
        # PNG allows chunks up to (but excluding) 2GB (after compression for IDAT)
    write-chunk $fh, 'IDAT', compress $!data;

    write-chunk $fh, 'IEND';

    $fh.close;

    True;
}

# writes a chunk
sub write-chunk (IO::Handle $fh, Str $type, @data = ()) {
    $fh.write: bytes @data.elems, 4;

    my @type := $type.encode;
    my @td := @data ~~ Blob ??
        concat-blob @type, @data !!
        Blob[uint8].new: @type.list, @data.list;
    $fh.write: @td;

    $fh.write: bytes String::CRC32::crc32 @td;

    True;
}

# converts a number to a Blob of bytes with optional fixed width
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

    Blob[uint8].new: @return;
}

# concatenates two blobs into a buf via nativecall for performance
sub concat-blob (Blob[uint8] $a, Blob[uint8] $b) {
    return $a unless $b;

    my $buf = Buf[uint8].new;
    $buf[$a + $b - 1] = 0;
    # this is might be faster than .new(@$a), but that's not really why we're doing it
    # we exploit the fact that memcpy gives us a pointer...
    my $ptr = memcpy-buf $buf, $a, +$a;
    # ...to allow pointer arithmetic for copying the second part
    memcpy OpaquePointer.new($ptr + $a), $b, +$b;

    $buf;
}

# nativecall memcpy for above...should "Int" be int32? portability questions about pointer width, size_t, etc
sub memcpy (OpaquePointer, Blob, Int)
    returns OpaquePointer is native { * };
# nativecall doesn't seem to work on multis, thus -buf
sub memcpy-buf (Buf, Blob, Int) returns OpaquePointer is symbol('memcpy') is native { * };

