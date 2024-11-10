#!/bin/zsh

# Run AppleScript to choose an image file and capture the path
IMAGE_FILE=$(osascript <<'END'
use AppleScript version "2.4"
use scripting additions
use framework "Foundation"

set theFile to POSIX path of (choose file with prompt "Choose an image file")
return theFile
END
)

# Exit if no file was selected or IMAGE_FILE is empty
if [ -z "$IMAGE_FILE" ]; then
    echo "No file selected. Exiting."
    exit 1
fi

# Prompt for custom caption
CUSTOM_CAPTION=$(osascript <<'END'
use AppleScript version "2.4"
use scripting additions

display dialog "Enter the custom caption:" default answer ""
set captionText to text returned of result
return captionText
END
)

# If no caption was provided, set a default message
if [ -z "$CUSTOM_CAPTION" ]; then
    CUSTOM_CAPTION="Look around you"
fi

# Use choose color for COLOR1 and COLOR2
get_hex_color() {
    osascript <<'END'
use AppleScript version "2.4"
use scripting additions

try
    set chosenColor to choose color default color {65535, 65535, 65535}  -- default is white
    set redValue to (item 1 of chosenColor / 257) as integer
    set greenValue to (item 2 of chosenColor / 257) as integer
    set blueValue to (item 3 of chosenColor / 257) as integer
    set hexColor to "#" & (do shell script "printf '%02X%02X%02X' " & redValue & " " & greenValue & " " & blueValue)
    return hexColor
on error
    return "#000000"  -- fallback to black if there's an error
end try
END
}

# Assign colors selected through the color picker
COLOR1=$(get_hex_color)
COLOR2=$(get_hex_color)

# Retrieve EXIF data for Camera, Lens, and Photographer using exiftool
CAMERA_MODEL=$(exiftool -s -s -s -Model "$IMAGE_FILE")
LENS_MODEL=$(exiftool -s -s -s -LensModel "$IMAGE_FILE")
FOCAL_LENGTH=$(exiftool -s -s -s -FocalLength "$IMAGE_FILE")
PHOTOGRAPHER=$(exiftool -s -s -s -Artist "$IMAGE_FILE")

# Combine EXIF data into a single string for the caption
EXIF_DATA="$CAMERA_MODEL $LENS_MODEL"
if [ -n "$PHOTOGRAPHER" ]; then
    EXIF_DATA="$EXIF_DATA"
fi

# Define parameters for primary caption with EXIF data
CAPTION_LINE1="$CUSTOM_CAPTION | $EXIF_DATA"
FONT_NAME1="HackNerdFontComplete-Regular"
VERTICAL_PERCENTAGE1=7  # Position as a percentage of image height

# Define parameters for secondary caption
CAPTION_LINE2="$PHOTOGRAPHER"
FONT_NAME2="HackNerdFontComplete-Regular"
VERTICAL_PERCENTAGE2=5  # Position as a percentage of image height

OUTPUT_FILE="${IMAGE_FILE%.*}-captioned.jpg"

# AppleScript to add two lines of text with custom fonts, colors, and positions to the image
osascript <<END
use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit"
use scripting additions

-- Helper function to create NSColor from hex code
on colorFromHex(hexCode)
    set redComponent to (do shell script "printf '%d' 0x" & text 2 thru 3 of hexCode) / 255.0
    set greenComponent to (do shell script "printf '%d' 0x" & text 4 thru 5 of hexCode) / 255.0
    set blueComponent to (do shell script "printf '%d' 0x" & text 6 thru 7 of hexCode) / 255.0
    return current application's NSColor's colorWithRed:redComponent green:greenComponent blue:blueComponent alpha:1.0
end colorFromHex

-- Path for input and output
set theFile to POSIX path of "$IMAGE_FILE"
set newPath to POSIX path of "$OUTPUT_FILE"

try
    -- Load image data
    set imageData to current application's NSData's alloc()'s initWithContentsOfFile:theFile
    set originalBitmapRep to current application's NSBitmapImageRep's imageRepWithData:imageData
    if originalBitmapRep is missing value then error "Failed to load image."

    -- Get original image size
    set imageWidth to originalBitmapRep's pixelsWide()
    set imageHeight to originalBitmapRep's pixelsHigh()

    -- Calculate font sizes based on image height
    set fontSize1 to round (imageHeight * 0.018)
    set fontSize2 to round (imageHeight * 0.009)

    -- Calculate vertical positions based on image height and percentages
    set verticalPosition1 to imageHeight * $VERTICAL_PERCENTAGE1 / 100
    set verticalPosition2 to imageHeight * $VERTICAL_PERCENTAGE2 / 100

    -- Create a new NSImage for drawing
    set finalImage to current application's NSImage's alloc()'s initWithSize:{imageWidth, imageHeight}
    finalImage's addRepresentation:originalBitmapRep
    finalImage's lockFocus()

    -- Draw first line of text
    set theNSString1 to current application's NSString's stringWithString:"$CAPTION_LINE1"
    set customFont1 to current application's NSFont's fontWithName:"$FONT_NAME1" |size|:fontSize1
    if customFont1 is missing value then error "Font not found: $FONT_NAME1"
    
    -- Set color for first line
    set customColor1 to my colorFromHex("$COLOR1")
    
    set attributesNSDictionary1 to current application's NSDictionary's dictionaryWithObjects:{customFont1, customColor1} forKeys:{current application's NSFontAttributeName, current application's NSForegroundColorAttributeName}
    set textSize1 to theNSString1's sizeWithAttributes:attributesNSDictionary1
    set textWidth1 to textSize1's width
    set centeredX1 to (imageWidth - textWidth1) / 2
    theNSString1's drawAtPoint:{centeredX1, verticalPosition1} withAttributes:attributesNSDictionary1

    -- Draw second line of text with custom caption
    set theNSString2 to current application's NSString's stringWithString:"$CAPTION_LINE2"
    set customFont2 to current application's NSFont's fontWithName:"$FONT_NAME2" |size|:fontSize2
    if customFont2 is missing value then error "Font not found: $FONT_NAME2"

    -- Set color for second line
    set customColor2 to my colorFromHex("$COLOR2")
    
    set attributesNSDictionary2 to current application's NSDictionary's dictionaryWithObjects:{customFont2, customColor2} forKeys:{current application's NSFontAttributeName, current application's NSForegroundColorAttributeName}
    set textSize2 to theNSString2's sizeWithAttributes:attributesNSDictionary2
    set textWidth2 to textSize2's width
    set centeredX2 to (imageWidth - textWidth2) / 2
    theNSString2's drawAtPoint:{centeredX2, verticalPosition2} withAttributes:attributesNSDictionary2

    -- Unlock drawing and save final image
    finalImage's unlockFocus()
    set finalBitmapRep to current application's NSBitmapImageRep's alloc()'s initWithData:(finalImage's TIFFRepresentation())
    set newNSData to finalBitmapRep's representationUsingType:(current application's NSJPEGFileType) |properties|:{NSImageCompressionFactor:0.8, NSImageProgressive:false}
    newNSData's writeToFile:newPath atomically:true
on error errMsg number errNum
    display dialog "Error: " & errMsg & " (" & errNum & ")" buttons {"OK"} default button "OK"
end try
END

# Notify user
echo "High-quality captioned image saved as: $OUTPUT_FILE"
