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


#------------------------------------------------------------------------------


function blur_borders {
  SRC_FILE="$1"
  SCREEN_SIZE="$2"

  echo "  $SRC_FILE  $(identify -format '%wx%h' "$SRC_FILE") -> $SCREEN_SIZE"

  SRC_FILE_ESCAPED=$(echo "$SRC_FILE" | sed -r 's/ /_/g')
  DEST_FILE_NAME=$(basename "$SRC_FILE_ESCAPED")
  DEST_FOLDER_NAME=$(dirname "$SRC_FILE_ESCAPED" | xargs basename)

  if [[ "$DEST_FOLDER_NAME" == "auswahl" ]] || [[ "$DEST_FOLDER_NAME" == "Auswahl" ]]; then
    DEST_FOLDER_NAME=$(dirname "$SRC_FILE_ESCAPED" | xargs dirname | xargs basename)
  fi

  DEST_FILE="$DEST_FOLDER/$DEST_FOLDER_NAME/$DEST_FILE_NAME"

  mkdir -p $DEST_FOLDER/$DEST_FOLDER_NAME

  # read image into memory
  # blur and scale-to-fill background image
  # scale-to-fit foreground image
  # compose background and foreground and crop overflow borders
  convert \
    \( "$SRC_FILE" -auto-orient -write mpr:tmp0 +delete \) \
    \( mpr:tmp0 -resize "${SCREEN_SIZE}^" -blur 0x${BG_BLUR_INTENSITY} -brightness-contrast $BG_BRIGHTNESS \) \
    \( mpr:tmp0 -resize "${SCREEN_SIZE}" \) \
    -gravity center -composite -crop "${SCREEN_SIZE}+0+0" "$DEST_FILE"
}



export -f blur_borders
export DEST_FOLDER
export MAX_WIDTH
export MAX_HEIGHT
export BG_BLUR_INTENSITY
export BG_BRIGHTNESS


for SRC_FOLDER in "${SRC_FOLDERS[@]}"
do
  echo "$SRC_FOLDER"
  SRC_PATH=$BASE_SRC_FOLDER/$SRC_FOLDER
  
  find "${SRC_PATH}" -iname '*.jpg' -print0 | xargs -0 -n 1 -P 8 -I {} $SHELL -c '
    blur_borders "$@" "${MAX_WIDTH}x${MAX_HEIGHT}"
  ' _ {}
done
