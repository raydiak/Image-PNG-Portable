# Image::PNG::Portable

This is an almost-pure Perl 6 PNG module, requiring only zlib.

## Status

This module is currently useful for outputting opaque 24-bit truecolor images.
Reading, precompression filters, alpha, palettes, grayscale, non-8-bit
channels, and ancillary features like gamma correction, color profiles, and
textual metadata are all NYI.

## Synopsis

    use Image::PNG::Portable;
    my $o = Image::PNG::Portable.new: :width(16), :height(16);
    $o.set: 8,8, 255,255,255;
    $o.write: 'image.png';

## Usage

The following types are used internally and in this documentation. They are
here for brevity, not exported in the public API.

    subset UInt of Int where * >= 0; # unsigned
    subset UInt8 of Int where 0 <= * <= 255; # unsigned 8-bit
    subset PInt of Int where * > 0; # positive

### .new(PInt :$width!, PInt :$height!)

Creates a new Image::PNG object, initialized to black.

### .set(UInt $x, UInt $y, UInt8 $red, UInt8 $green, UInt8 $blue)

Sets the color of a pixel in the image.

### .write($file, Bool :$free = True)

Writes the contents of the image to the specified file.

Also calls .free (see below) if $free is True (the default). Note that this
means the object is entirely useless after a call to .write, unless :!free is
passed. Freeing is essential for preventing memory leaks, so either allow
freeing on your last write, or call .free after you are done with the object,
before your application exits (including early/erroneous termination).

### .free()

Releases the memory used for in-memory storage. Once freed, the
Image::PNG::Portable object is useless and should be discarded. If you do not
free, either via .write or by calling this method directly, your application
will likely leak memory.

## BUGS

Very large images are known to cause a crash. The limit is around 10 or 15
megapixels. Please report any other bugs at
https://github.com/raydiak/Image-PNG-Portable/issues or to
raydiak@cyberuniverses.com .

