# Image::PNG::Portable

This is an almost-pure Raku PNG module.

## Status

This module is currently useful for outputting 8-bit-per-channel truecolor
images.  Reading, precompression filters, palettes, grayscale, non-8-bit
channels, and ancillary features like gamma correction, color profiles, and
textual metadata are all NYI.

Range checks (UInt, UInt8, and PInt, mentioned below) are disabled pending a
Rakudo bugfix. Violate them at your peril.

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

### .new(PInt :$width!, PInt :$height!, Bool $alpha = True)

Creates a new Image::PNG::Portable object, initialized to black. If the alpha
channel is enabled, it is initialized to transparent.

### .set(UInt $x, UInt $y, UInt8 $red, UInt8 $green, UInt8 $blue, UInt8 $alpha = 255)

Sets the color of a pixel in the image.

### .set-all(UInt8 $red, UInt8 $green, UInt8 $blue, UInt8 $alpha = 255)

Sets the color of all pixels in the image.

### .get(UInt $x, UInt $y)

Gets the color of a pixel in the image as an array of channel values.

### .write($file)

Writes the contents of the image to the specified file.

## BUGS

None known. Please report bugs at
https://github.com/raydiak/Image-PNG-Portable/issues or to
raydiak@cyberuniverses.com .
