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

# Define parameters for primary caption
CAPTION_LINE1="You had to be there | Fuji X-T5 35mm"
FONT_NAME1="Space Mono"
FONT_SIZE1=120
COLOR1="#800855"  # Example hex color for the first line
VERTICAL_PERCENTAGE1=10  # Position as a percentage of image height

# Define parameters for secondary caption
CAPTION_LINE2="by Symon Flaming"
FONT_NAME2="Space Mono"
FONT_SIZE2=90
COLOR2="#fafafa"  # Can still use standard colors like "blue"
VERTICAL_PERCENTAGE2=7  # Position as a percentage of image height

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

    -- Calculate vertical positions based on image height and percentages
    set verticalPosition1 to imageHeight * $VERTICAL_PERCENTAGE1 / 100
    set verticalPosition2 to imageHeight * $VERTICAL_PERCENTAGE2 / 100

    -- Create a new NSImage for drawing
    set finalImage to current application's NSImage's alloc()'s initWithSize:{imageWidth, imageHeight}
    finalImage's addRepresentation:originalBitmapRep
    finalImage's lockFocus()

    -- Draw first line of text
    set theNSString1 to current application's NSString's stringWithString:"$CAPTION_LINE1"
    set customFont1 to current application's NSFont's fontWithName:"$FONT_NAME1" |size|:$FONT_SIZE1
    if customFont1 is missing value then error "Font not found: $FONT_NAME1"
    
    -- Set color for first line
    if "$COLOR1" starts with "#" then
        set customColor1 to my colorFromHex("$COLOR1")
    else if "$COLOR1" is equal to "red" then
        set customColor1 to current application's NSColor's redColor()
    else if "$COLOR1" is equal to "blue" then
        set customColor1 to current application's NSColor's blueColor()
    else if "$COLOR1" is equal to "white" then
        set customColor1 to current application's NSColor's whiteColor()
    else if "$COLOR1" is equal to "green" then
        set customColor1 to current application's NSColor's greenColor()
    else
        set customColor1 to current application's NSColor's blackColor() -- Default to black if color is not recognized
    end if

    set attributesNSDictionary1 to current application's NSDictionary's dictionaryWithObjects:{customFont1, customColor1} forKeys:{current application's NSFontAttributeName, current application's NSForegroundColorAttributeName}
    set textSize1 to theNSString1's sizeWithAttributes:attributesNSDictionary1
    set textWidth1 to textSize1's width
    set centeredX1 to (imageWidth - textWidth1) / 2
    theNSString1's drawAtPoint:{centeredX1, verticalPosition1} withAttributes:attributesNSDictionary1

    -- Draw second line of text
    set theNSString2 to current application's NSString's stringWithString:"$CAPTION_LINE2"
    set customFont2 to current application's NSFont's fontWithName:"$FONT_NAME2" |size|:$FONT_SIZE2
    if customFont2 is missing value then error "Font not found: $FONT_NAME2"
    
    -- Set color for second line
    if "$COLOR2" starts with "#" then
        set customColor2 to my colorFromHex("$COLOR2")
    else if "$COLOR2" is equal to "red" then
        set customColor2 to current application's NSColor's redColor()
    else if "$COLOR2" is equal to "blue" then
        set customColor2 to current application's NSColor's blueColor()
    else if "$COLOR2" is equal to "white" then
        set customColor2 to current application's NSColor's whiteColor()
    else if "$COLOR2" is equal to "green" then
        set customColor2 to current application's NSColor's greenColor()
    else
        set customColor2 to current application's NSColor's blackColor() -- Default to black if color is not recognized
    end if

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
