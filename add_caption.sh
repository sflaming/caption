#!/bin/bash

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

# Define parameters for captioning with custom font, color, and position
CAPTION="Nice night for a fatty | Fuji X-T5 35mm \n Symon Flaming"
FONT_NAME="Space Mono"
FONT_SIZE=80
COLOR="black"  # Change this to any other color if you prefer
VERTICAL_POSITION=450  # Adjust this value to move the text up or down
OUTPUT_FILE="${IMAGE_FILE%.*}-captioned.jpg"

# AppleScript to add centered text with custom font and color to the image, preserving quality
osascript <<END
use AppleScript version "2.4"
use framework "Foundation"
use framework "AppKit"
use scripting additions

-- Path for input and output
set theFile to POSIX path of "$IMAGE_FILE"
set newPath to POSIX path of "$OUTPUT_FILE"

try
    -- Text with custom font and specified color
    set theNSString to current application's NSString's stringWithString:"$CAPTION"
    
    -- Custom font setup
    set customFont to current application's NSFont's fontWithName:"$FONT_NAME" |size|:$FONT_SIZE
    if customFont is missing value then error "Font not found: $FONT_NAME"
    
    -- Set custom color based on predefined choices
    set customColor to missing value
    if "$COLOR" is equal to "red" then
        set customColor to current application's NSColor's redColor()
    else if "$COLOR" is equal to "blue" then
        set customColor to current application's NSColor's blueColor()
    else if "$COLOR" is equal to "white" then
        set customColor to current application's NSColor's whiteColor()
    else if "$COLOR" is equal to "green" then
        set customColor to current application's NSColor's greenColor()
    else
        set customColor to current application's NSColor's blackColor() -- Default to black if color is not recognized
    end if

    if customColor is missing value then error "Failed to set color: $COLOR"

    -- Construct attributes dictionary with custom font and color
    set attributesNSDictionary to current application's NSDictionary's dictionaryWithObjects:{customFont, customColor} forKeys:{current application's NSFontAttributeName, current application's NSForegroundColorAttributeName}

    -- Load the original image as NSBitmapImageRep to retain DPI and other metadata
    set imageData to current application's NSData's alloc()'s initWithContentsOfFile:theFile
    set originalBitmapRep to current application's NSBitmapImageRep's imageRepWithData:imageData
    if originalBitmapRep is missing value then error "Failed to load image."

    -- Get original image size
    set imageWidth to originalBitmapRep's pixelsWide()
    set imageHeight to originalBitmapRep's pixelsHigh()

    -- Create a new NSImage for drawing
    set finalImage to current application's NSImage's alloc()'s initWithSize:{imageWidth, imageHeight}
    finalImage's addRepresentation:originalBitmapRep

    -- Begin drawing on the new image
    finalImage's lockFocus()
    
    -- Calculate text width for centering
    set textSize to theNSString's sizeWithAttributes:attributesNSDictionary
    set textWidth to textSize's width
    set centeredX to (imageWidth - textWidth) / 2

    -- Draw the text onto the new image
    theNSString's drawAtPoint:{centeredX, $VERTICAL_POSITION} withAttributes:attributesNSDictionary
    finalImage's unlockFocus()

    -- Save the final image with text as high-quality JPEG
    set finalBitmapRep to current application's NSBitmapImageRep's alloc()'s initWithData:(finalImage's TIFFRepresentation())
    set newNSData to finalBitmapRep's representationUsingType:(current application's NSJPEGFileType) |properties|:{NSImageCompressionFactor:0.8, NSImageProgressive:false}
    newNSData's writeToFile:newPath atomically:true
on error errMsg number errNum
    display dialog "Error: " & errMsg & " (" & errNum & ")" buttons {"OK"} default button "OK"
end try
END

# Notify user
echo "High-quality captioned image saved as: $OUTPUT_FILE"
