#!/bin/bash
#------------------------------------------------------------------------------

# Purpose: fits images into a specified size and adds blurred borders to fill
#          the entire area
#
# Requirements
#   sudo apt-get install imagemagick -y

#------------------------------------------------------------------------------

# Common root directory with images to convert
SRC_BASE_DIR="/media//Pictures"

# list of subfolder names contained in $SRC_BASE_DIR with source images
declare -a SRC_SUB_DIRS=(
  "2018-05 Pictures1" 
  "2019-08 Pictures2" 
)

# destination image folder
DEST_DIR="/media/ramdisk/Pictures"

# height of target screen
MAX_WIDTH=1920

# width of target screen
MAX_HEIGHT=1080

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
  DEST_DIR_NAME=$(dirname "$SRC_FILE_ESCAPED" | xargs basename)

  DEST_FILE="$DEST_DIR/$DEST_DIR_NAME/$DEST_FILE_NAME"

  mkdir -p $DEST_DIR/$DEST_DIR_NAME

  # read image into memory
  # blur and scale-to-fill background image
  # scale-to-fit foreground image
  # compose background and foreground and crop overflow borders
  convert \
    \( "$SRC_FILE" -auto-orient -write mpr:src +delete \) \
    \( mpr:src -resize "${SCREEN_SIZE}^" -gravity center -crop "${SCREEN_SIZE}+0+0" -write mpr:bg +delete \) \
    \( mpr:bg -blur 0x${BG_BLUR_INTENSITY} -brightness-contrast $BG_BRIGHTNESS \) \
    \( mpr:src -resize "${SCREEN_SIZE}>" \) \
    -gravity center -composite "$DEST_FILE"
}



export -f blur_borders
export DEST_DIR
export MAX_WIDTH
export MAX_HEIGHT
export BG_BLUR_INTENSITY
export BG_BRIGHTNESS


for SRC_SUB_DIR in "${SRC_SUB_DIRS[@]}"
do
  echo "$SRC_SUB_DIR"
  SRC_PATH=$SRC_BASE_DIR/$SRC_SUB_DIR
  
  find "${SRC_PATH}" -iname '*.jpg' -print0 | xargs -0 -n 1 -P 8 -I {} $SHELL -c '
    blur_borders "$@" "${MAX_WIDTH}x${MAX_HEIGHT}"
  ' _ {}
done
