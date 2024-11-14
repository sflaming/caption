# Caption

This script creates a custom captioned version of an image selected by the user. Here’s a summary of its key functionalities:

**Image Selection:** The script prompts the user to choose an image file using an AppleScript dialog, capturing the file path.

**Custom Caption Input:** It asks the user to input a custom caption. If left blank, it defaults to “Look around you.”

**Color Picker for Text:** The script uses AppleScript to present a color picker twice, allowing the user to select two colors (one for each line of text), outputting the values in hex format.

**Text Positioning:** The script prompts for vertical and horizontal alignment options for each line of text. Each line has adjustable top, bottom, or percentage-based positions, with left, center, or right horizontal alignment.

**EXIF Metadata Extraction:** Using exiftool, the script extracts camera-related metadata (e.g., camera model, lens model, ISO, shutter speed, and aperture) from the chosen image.

**Caption Formatting:**
- Line 1 includes the custom caption and camera details.
- Line 2 displays exposure settings: shutter speed, aperture, and ISO.

**AppleScript for Image Manipulation:**
The script uses the AppKit framework to load the image, set the font size, and calculate positions for both lines.
It applies colors and fonts, then positions the text based on user choices and saves the final image.

**Output File:** The resulting image is saved as a new file (with `-captioned.jpg` appended to the original filename), and the user is notified of the saved file location.

