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
  "2018-05 Picutures1" 
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
TEMP_FOLDER="/media/ramdisk"

#------------------------------------------------------------------------------


function convert {
  SRC_FILE="$1"
  SRC_FILE_ESCAPED=$(echo "$SRC_FILE" | sed -r 's/ /_/g')
  DEST_FILE_NAME=$(basename "$SRC_FILE_ESCAPED")
  DEST_FOLDER_NAME=$(dirname "$SRC_FILE_ESCAPED" | xargs basename)

  DEST_FILE="$DEST_FOLDER/$DEST_FOLDER_NAME/$DEST_FILE_NAME"

  BG_FILE="$TEMP_FOLDER/bg.jpg"
  FG_FILE="$TEMP_FOLDER/fg.jpg"
  BG_FILE_TOP="$TEMP_FOLDER/top.jpg"
  BG_FILE_BOTTOM="$TEMP_FOLDER/bottom.jpg"
  
  mkdir -p $DEST_FOLDER/$DEST_FOLDER_NAME

  # resize main image
  convert "$SRC_FILE" -auto-orient -resize "${MAX_WIDTH}x${MAX_HEIGHT}" "$FG_FILE"

  WIDTH=$(identify -format '%w' "$FG_FILE")
  HEIGHT=$(identify -format '%h' "$FG_FILE")

  DEST_RATIO=$(($MAX_WIDTH * 100 / $MAX_HEIGHT))
  RATIO=$(($WIDTH * 100 / $HEIGHT))

  echo "  $SRC_FILE  $WIDTH x $HEIGHT  $DEST_RATIO x $RATIO"

  BG_TRANSFORM="-blur 0x${BG_BLUR_INTENSITY} -brightness-contrast $BG_BRIGHTNESS"

  if [[ "$RATIO" -gt "$DEST_RATIO" ]]; then # landscape images

    # scale background image
    convert "$SRC_FILE" -auto-orient -resize "x${MAX_HEIGHT}" "$BG_FILE"
    CURRENT_WIDTH=$(identify -format '%w' "$BG_FILE")
    LEFT=$((($CURRENT_WIDTH-$MAX_WIDTH)/2))

    # calc blank borders of main image
    CURRENT_HEIGHT=$(identify -format '%h' "$FG_FILE")
    HEIGHT_BORDER=$((($MAX_HEIGHT-$CURRENT_HEIGHT)/2))
    TOP=$(($HEIGHT_BORDER+$CURRENT_HEIGHT))

    # cut background and fill blank borders of main image
    convert "$BG_FILE" -crop "${MAX_WIDTH}x${HEIGHT_BORDER}+${LEFT}+0" $BG_TRANSFORM "$BG_FILE_TOP"
    convert "$BG_FILE" -crop "${MAX_WIDTH}x${HEIGHT_BORDER}+${LEFT}+${TOP}" $BG_TRANSFORM "$BG_FILE_BOTTOM"
    convert "$BG_FILE_TOP" "$FG_FILE" "$BG_FILE_BOTTOM" -append "$DEST_FILE"

  else # portrait images

    # scale background image
    convert "$SRC_FILE" -auto-orient -resize "${MAX_WIDTH}x" "$BG_FILE"
    CURRENT_HEIGHT=$(identify -format '%h' "$BG_FILE")
    TOP=$((($CURRENT_HEIGHT-$MAX_HEIGHT)/2))

    # calc blank borders of main image
    CURRENT_WIDTH=$(identify -format '%w' "$FG_FILE")
    WIDTH_BORDER=$((($MAX_WIDTH-$CURRENT_WIDTH)/2))
    RIGHT=$(($WIDTH_BORDER+$CURRENT_WIDTH))

    # cut background and fill blank borders of main image
    convert "$BG_FILE" -crop "${WIDTH_BORDER}x${MAX_HEIGHT}+0+${TOP}" $BG_TRANSFORM "$BG_FILE_TOP"
    convert "$BG_FILE" -crop "${WIDTH_BORDER}x${MAX_HEIGHT}+${RIGHT}+${TOP}" $BG_TRANSFORM "$BG_FILE_BOTTOM"
    convert "$BG_FILE_TOP" "$FG_FILE" "$BG_FILE_BOTTOM" +append "$DEST_FILE"

  fi
}


export -f convert
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
