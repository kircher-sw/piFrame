#!/bin/bash
#------------------------------------------------------------------------------

# Purpose: fits images into a specified size and adds blurred borders to fill
#          the entire area
#
# Requirements
#   sudo apt-get install imagemagick -y

#------------------------------------------------------------------------------

# Common root folder of source images
BASE_SRC_FOLDER="/media/Pictures"

# list of subfolder names contained in $BASE_SRC_FOLDER with source images
declare -a SRC_FOLDERS=(
  "2018-05 Pictures1" 
  "2019-08 Pictures2" 
)

# destination image folder
DEST_FOLDER="/media/ramdisk/Pictures"

# height of target screen
MAX_WIDTH=1280

# width of target screen
MAX_HEIGHT=1024

# blur intensity for background image
BG_BLUR_INTENSITY=25

# brightness for background image [-100..100]
BG_BRIGHTNESS=-10

# folder for temporary data (should be a tmpfs)
TEMP_FOLDER="/tmp"


#------------------------------------------------------------------------------


function blur_borders {
  SRC_FILE="$1"
  SRC_FILE_ESCAPED=$(echo "$SRC_FILE" | sed -r 's/ /_/g')
  DEST_FILE_NAME=$(basename "$SRC_FILE_ESCAPED")
  DEST_FOLDER_NAME=$(dirname "$SRC_FILE_ESCAPED" | xargs basename)

  DEST_FILE="$DEST_FOLDER/$DEST_FOLDER_NAME/$DEST_FILE_NAME"

  FG_FILE="$TEMP_FOLDER/fg.jpg"
  BG_FILE="$TEMP_FOLDER/bg.jpg"
  
  mkdir -p $DEST_FOLDER/$DEST_FOLDER_NAME

  echo "  $SRC_FILE  $(identify -format '%wx%h' "$SRC_FILE")"

  # resize image to fit entirely into screen
  convert "$SRC_FILE" -auto-orient -resize "${MAX_WIDTH}x${MAX_HEIGHT}" "$FG_FILE"
  
  # scale and blur background image to fill the screen
  convert "$SRC_FILE" -auto-orient -resize "${MAX_WIDTH}x${MAX_HEIGHT}^" -blur 0x${BG_BLUR_INTENSITY} -brightness-contrast $BG_BRIGHTNESS "$BG_FILE"  
  
  # compose foreground over background image and crop overflow borders
  convert -gravity center -composite "$BG_FILE" "$FG_FILE" -crop "${MAX_WIDTH}x${MAX_HEIGHT}+0+0" "$DEST_FILE"
}


export -f blur_borders
export DEST_FOLDER
export TEMP_FOLDER
export MAX_WIDTH
export MAX_HEIGHT
export BG_BLUR_INTENSITY
export BG_BRIGHTNESS


for SRC_FOLDER in "${SRC_FOLDERS[@]}"
do
  echo "$SRC_FOLDER"
  SRC_PATH=$BASE_SRC_FOLDER/$SRC_FOLDER
  
  find "${SRC_PATH}" -iname '*.jpg' -exec bash -c 'convert "$0"' \{} \;
done
