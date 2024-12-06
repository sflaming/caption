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

# Get image size data
# Run sips command and capture output
output=$(sips -g dpiHeight -g dpiWidth $IMAGE_FILE)

# Extract dpiHeight
dpiHeight=$(echo "$output" | grep "dpiHeight" | awk '{print $2}')

# Extract dpiWidth
dpiWidth=$(echo "$output" | grep "dpiWidth" | awk '{print $2}')

# Display the values (optional)
echo "dpiHeight: $dpiHeight"
echo "dpiWidth: $dpiWidth"

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

# Prompt for custom signature
CUSTOM_SIG=$(osascript <<'END'
use AppleScript version "2.4"
use scripting additions

display dialog "Enter the custom signature:" default answer ""
set captionText to text returned of result
return captionText
END
)

# If no sig was provided, set a default empty signature
if [ -z "$CUSTOM_SIG" ]; then
    CUSTOM_SIG=""
fi

# Function to display color picker and return a hex color
get_hex_color() {
    osascript <<'END'
use AppleScript version "2.4"
use scripting additions

try
    set chosenColor to choose color default color {0, 0, 0}  -- default is white
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
COLOR3=$(get_hex_color)

# Prompt for vertical and horizontal positioning choices for line 1
read -r VERTICAL_POSITION1 HORIZONTAL_POSITION1 <<< $(osascript <<'END'
use AppleScript version "2.4"
use scripting additions

set verticalOptions to {"default", "top", "bottom", "lower-mid"}
set horizontalOptions to {"left", "center", "right"}

set verticalChoice1 to choose from list verticalOptions with prompt "Select vertical position for Line 1:"
set horizontalChoice1 to choose from list horizontalOptions with prompt "Select horizontal position for Line 1:"

return (item 1 of verticalChoice1) & " " & (item 1 of horizontalChoice1)
END
)

# Prompt for vertical and horizontal positioning choices for line 2
read -r VERTICAL_POSITION2 HORIZONTAL_POSITION2 <<< $(osascript <<'END'
use AppleScript version "2.4"
use scripting additions

set verticalOptions to {"default", "top", "bottom", "lower-mid"}
set horizontalOptions to {"left", "center", "right"}

set verticalChoice2 to choose from list verticalOptions with prompt "Select vertical position for Line 2:"
set horizontalChoice2 to choose from list horizontalOptions with prompt "Select horizontal position for Line 2:"

return (item 1 of verticalChoice2) & " " & (item 1 of horizontalChoice2)
END
)

# Prompt for vertical and horizontal positioning choices for line 3
read -r VERTICAL_POSITION3 HORIZONTAL_POSITION3 <<< $(osascript <<'END'
use AppleScript version "2.4"
use scripting additions

set verticalOptions to {"default", "top", "bottom", "lower-mid"}
set horizontalOptions to {"left", "center", "right"}

set verticalChoice3 to choose from list verticalOptions with prompt "Select vertical position for Line 3:"
set horizontalChoice3 to choose from list horizontalOptions with prompt "Select horizontal position for Line 3:"

return (item 1 of verticalChoice3) & " " & (item 1 of horizontalChoice3)
END
)

# Set vertical position percentages based on user choice for line 1
if [ "$VERTICAL_POSITION1" = "top" ]; then
    VERTICAL_PERCENTAGE1=95
elif [ "$VERTICAL_POSITION1" = "bottom" ]; then
    VERTICAL_PERCENTAGE1=1
elif [ "$VERTICAL_POSITION1" = "lower-mid" ]; then
    VERTICAL_PERCENTAGE1=11
else
    VERTICAL_PERCENTAGE1=7
fi

# Set vertical position percentages based on user choice for line 2
if [ "$VERTICAL_POSITION2" = "top" ]; then
    VERTICAL_PERCENTAGE2=95
elif [ "$VERTICAL_POSITION2" = "bottom" ]; then
    VERTICAL_PERCENTAGE2=1
elif [ "$VERTICAL_POSITION2" = "lower-mid" ]; then
    VERTICAL_PERCENTAGE2=11
else
    VERTICAL_PERCENTAGE2=4
fi

# Set vertical position percentages based on user choice for line 3
if [ "$VERTICAL_POSITION3" = "top" ]; then
    VERTICAL_PERCENTAGE3=95
elif [ "$VERTICAL_POSITION3" = "bottom" ]; then
    VERTICAL_PERCENTAGE3=1
elif [ "$VERTICAL_POSITION3" = "lower-mid" ]; then
    VERTICAL_PERCENTAGE3=11
else
    VERTICAL_PERCENTAGE3=2
fi

# Set horizontal alignment values for drawing based on user choice
# Left alignment is at 4% of image width, Center alignment is at the center, Right alignment is at 96%
get_horizontal_position() {
    local choice=$1
    if [ "$choice" = "left" ]; then
        echo "4"
    elif [ "$choice" = "right" ]; then
        echo "96"
    else
        echo "50"
    fi
}

HORIZONTAL_PERCENTAGE1=$(get_horizontal_position "$HORIZONTAL_POSITION1")
HORIZONTAL_PERCENTAGE2=$(get_horizontal_position "$HORIZONTAL_POSITION2")
HORIZONTAL_PERCENTAGE3=$(get_horizontal_position "$HORIZONTAL_POSITION3")

# Retrieve EXIF data for Camera, Lens, and Photographer using exiftool
CAMERA_MODEL=$(exiftool -s -s -s -Model "$IMAGE_FILE")
LENS_MODEL=$(exiftool -s -s -s -LensModel "$IMAGE_FILE")
FOCAL_LENGTH=$(exiftool -s -s -s -FocalLength "$IMAGE_FILE")
PHOTOGRAPHER=$(exiftool -s -s -s -Artist "$IMAGE_FILE")
ISO=$(exiftool -s -s -s -ISO "$IMAGE_FILE")
SHUTTER_SPEED=$(exiftool -s -s -s -ShutterSpeedValue "$IMAGE_FILE")
APERATURE=$(exiftool -s -s -s -ApertureValue "$IMAGE_FILE")

# Concatenate EXIF data for the captions
EXIF_LINE1="$CAMERA_MODEL $LENS_MODEL"
EXIF_LINE2="$FOCAL_LENGTH    $SHUTTER_SPEED s    ƒ/$APERATURE    ISO $ISO"
EXIF_LINE3_ALT1="$PHOTOGRAPHER"
EXIF_LINE3_ALT2="$CUSTOM_SIG"

# Get user preference for third line
THIRD_LINE_CHOICE=$(osascript <<'END'
use AppleScript version "2.4"
use scripting additions

set options to {"Custom Signature", "Photographer Name", "Logo", "None"}
set choice to choose from list options with prompt "Choose the third line option:"
return (item 1 of choice)
END
)

# Initialize variables for logo
LOGO_FILE=""
LOGO_SIZE_PERCENTAGE=10

# If logo is chosen, prompt for the PNG file and size percentage
if [ "$THIRD_LINE_CHOICE" = "Logo" ]; then
    LOGO_FILE=$(osascript <<'END'
use AppleScript version "2.4"
use scripting additions

set theFile to POSIX path of (choose file with prompt "Choose a PNG logo file" of type {"png"})
return theFile
END
)

    # Prompt for logo size percentage
    LOGO_SIZE_PERCENTAGE=$(osascript <<'END'
use AppleScript version "2.4"
use scripting additions

display dialog "Enter logo size as percentage of image width (1-30):" default answer "2"
set sizeText to text returned of result
if sizeText is "" then
    return "2"
else
    return sizeText
end if
END
)
fi

# Set the chosen alternative based on user preference
if [ "$THIRD_LINE_CHOICE" = "Custom Signature" ]; then
    CHOSEN_ALT="$EXIF_LINE3_ALT2"
elif [ "$THIRD_LINE_CHOICE" = "Photographer Name" ]; then
    CHOSEN_ALT="$EXIF_LINE3_ALT1"
else
    CHOSEN_ALT=""
fi

# Define parameters for primary caption with EXIF data
CAPTION_LINE1="$CUSTOM_CAPTION | $EXIF_LINE1"
FONT_NAME1="Space Mono"

# Define parameters for secondary caption
CAPTION_LINE2="$EXIF_LINE2"
FONT_NAME2="Space Mono"

# Define parameters for third caption
CAPTION_LINE3="$CHOSEN_ALT"
FONT_NAME3="Space Mono"

OUTPUT_FILE="${IMAGE_FILE%.*}-captioned.jpg"

# AppleScript to add three lines of text with custom fonts, colors, and positions to the image
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
    set fontSize1 to round (imageHeight * 0.016)
    set fontSize2 to round (imageHeight * 0.012)
    set fontSize3 to round (imageHeight * 0.012)

    -- Calculate vertical positions based on image height and percentages
    set verticalPosition1 to imageHeight * $VERTICAL_PERCENTAGE1 / 100
    set verticalPosition2 to imageHeight * $VERTICAL_PERCENTAGE2 / 100
    set verticalPosition3 to imageHeight * $VERTICAL_PERCENTAGE3 / 100

    -- Create a new NSImage for drawing
    set finalImage to current application's NSImage's alloc()'s initWithSize:{imageWidth, imageHeight}
    finalImage's addRepresentation:originalBitmapRep
    finalImage's lockFocus()

    -- Draw first line of text with adjusted horizontal alignment
    set theNSString1 to current application's NSString's stringWithString:"$CAPTION_LINE1"
    set customFont1 to current application's NSFont's fontWithName:"$FONT_NAME1" |size|:fontSize1
    if customFont1 is missing value then error "Font not found: $FONT_NAME1"
    
    -- Set color for first line
    set customColor1 to my colorFromHex("$COLOR1")
    
    -- Position the first line taking text width into account
    set attributesNSDictionary1 to current application's NSDictionary's dictionaryWithObjects:{customFont1, customColor1} forKeys:{current application's NSFontAttributeName, current application's NSForegroundColorAttributeName}
    set textSize1 to theNSString1's sizeWithAttributes:attributesNSDictionary1
    set textWidth1 to textSize1's width
    if "$HORIZONTAL_POSITION1" = "left" then
        set horizontalPosition1 to imageWidth * 0.04  -- 4% of image width
    else if "$HORIZONTAL_POSITION1" = "right" then
        set horizontalPosition1 to imageWidth * 0.96 - textWidth1  -- 96% minus text width
    else
        set horizontalPosition1 to (imageWidth - textWidth1) / 2  -- Centered
    end if
    theNSString1's drawAtPoint:{horizontalPosition1, verticalPosition1} withAttributes:attributesNSDictionary1

    -- Draw second line of text with adjusted horizontal alignment
    set theNSString2 to current application's NSString's stringWithString:"$CAPTION_LINE2"
    set customFont2 to current application's NSFont's fontWithName:"$FONT_NAME2" |size|:fontSize2
    if customFont2 is missing value then error "Font not found: $FONT_NAME2"

    -- Set color for second line
    set customColor2 to my colorFromHex("$COLOR2")
    
    -- Position the second line taking text width into account
    set attributesNSDictionary2 to current application's NSDictionary's dictionaryWithObjects:{customFont2, customColor2} forKeys:{current application's NSFontAttributeName, current application's NSForegroundColorAttributeName}
    set textSize2 to theNSString2's sizeWithAttributes:attributesNSDictionary2
    set textWidth2 to textSize2's width
    if "$HORIZONTAL_POSITION2" = "left" then
        set horizontalPosition2 to imageWidth * 0.04  -- 4% of image width
    else if "$HORIZONTAL_POSITION2" = "right" then
        set horizontalPosition2 to imageWidth * 0.96 - textWidth2  -- 96% minus text width
    else
        set horizontalPosition2 to (imageWidth - textWidth2) / 2  -- Centered
    end if
    theNSString2's drawAtPoint:{horizontalPosition2, verticalPosition2} withAttributes:attributesNSDictionary2

    -- Handle third line (either text or logo)
    if "$THIRD_LINE_CHOICE" = "Logo" then
        -- Load and draw the logo
        set logoPath to POSIX path of "$LOGO_FILE"
        set logoData to current application's NSData's alloc()'s initWithContentsOfFile:logoPath
        if logoData is not missing value then
            set logoImage to current application's NSImage's alloc()'s initWithData:logoData
            if logoImage is not missing value then
                -- Calculate logo size based on image width percentage
                set logoWidth to imageWidth * $LOGO_SIZE_PERCENTAGE / 100
                set logoHeight to logoWidth  -- Make it square for simplicity
                
                -- Calculate logo position
                if "$HORIZONTAL_POSITION3" = "left" then
                    set horizontalPosition3 to imageWidth * 0.04
                else if "$HORIZONTAL_POSITION3" = "right" then
                    set horizontalPosition3 to imageWidth * 0.96 - logoWidth
                else
                    set horizontalPosition3 to (imageWidth - logoWidth) / 2
                end if
                
                -- Draw the logo
                set destRect to current application's NSMakeRect(horizontalPosition3, verticalPosition3, logoWidth, logoHeight)
                set srcRect to current application's NSMakeRect(0, 0, logoImage's |size|()'s width, logoImage's |size|()'s height)
                logoImage's drawInRect:destRect fromRect:srcRect operation:(current application's NSCompositeSourceOver) fraction:1.0
            end if
        end if
    else if "$CAPTION_LINE3" is not "" then
        -- Draw third line of text
        set theNSString3 to current application's NSString's stringWithString:"$CAPTION_LINE3"
        set customFont3 to current application's NSFont's fontWithName:"$FONT_NAME3" |size|:fontSize3
        if customFont3 is missing value then error "Font not found: $FONT_NAME3"

        -- Set color for third line
        set customColor3 to my colorFromHex("$COLOR3")
        
        -- Position the third line taking text width into account
        set attributesNSDictionary3 to current application's NSDictionary's dictionaryWithObjects:{customFont3, customColor3} forKeys:{current application's NSFontAttributeName, current application's NSForegroundColorAttributeName}
        set textSize3 to theNSString3's sizeWithAttributes:attributesNSDictionary3
        set textWidth3 to textSize3's width
        if "$HORIZONTAL_POSITION3" = "left" then
            set horizontalPosition3 to imageWidth * 0.04  -- 4% of image width
        else if "$HORIZONTAL_POSITION3" = "right" then
            set horizontalPosition3 to imageWidth * 0.96 - textWidth3  -- 96% minus text width
        else
            set horizontalPosition3 to (imageWidth - textWidth3) / 2  -- Centered
        end if
        theNSString3's drawAtPoint:{horizontalPosition3, verticalPosition3} withAttributes:attributesNSDictionary3
    end if

    -- Unlock focus and save the final image
    finalImage's unlockFocus()
    set finalBitmapRep to current application's NSBitmapImageRep's alloc()'s initWithData:(finalImage's TIFFRepresentation())
    
    -- Adjust the size of the bitmap representation to set the PPI to 72
    set pixelWidth to finalBitmapRep's pixelsWide()
    set pixelHeight to finalBitmapRep's pixelsHigh()

    -- TODO Adjust the bitmap to have a resolution of 72 PPI 
    finalBitmapRep's setSize:{pixelWidth / 2, pixelHeight / 2} -- this isn't working to cut the ppi in half

    -- Create the JPEG data with the adjusted bitmap representation
    set newNSData to finalBitmapRep's representationUsingType:(current application's NSJPEGFileType) |properties|:{NSImageCompressionFactor:0.8, NSImageProgressive:false}

    -- Write the new image to the output path
    if newNSData's writeToFile:newPath atomically:true then
        display notification "Oh, hey! Image saved successfully!" with title "Image Caption Success"
    else
        display dialog "Error: Failed to save the image." buttons {"OK"} default button "OK"
    end if

on error errMsg number errNum
    display dialog "Error: " & errMsg & " (" & errNum & ")" buttons {"OK"} default button "OK"
end try
END

# Create `smaller` directory in the same location as the image

    # Shrink image
    echo "OUTPUT_DIR: $OUTPUT_DIR"
    echo "OUTPUT_FILE: $OUTPUT_FILE"
    SMALLER_OUTPUT_FILE="${IMAGE_FILE%.*}-captioned.jpg"
    echo "SMALLER_OUTPUT_FILE: $SMALLER_OUTPUT_FILE"
    sips -Z 2500 -s format jpeg -s formatOptions best $OUTPUT_FILE --out $SMALLER_OUTPUT_FILE
