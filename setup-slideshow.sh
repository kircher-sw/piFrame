#!/bin/sh
#------------------------------------------------------------------------------
# 
# 1. install Raspian
# 2. run this script with sudo
# 3. disable screensaver in Raspian
#
#------------------------------------------------------------------------------

# Requirements
sudo apt-get install feh exiv2 xscreensaver

INFO_SCRIPT=/home/pi/print-info.sh
RUN_SCRIPT=/home/pi/start-slideshow.sh


# create script for info text
echo "#!/bin/sh" > $INFO_SCRIPT

echo "SRC_FILE=\"\$1\"" >> $INFO_SCRIPT
echo "NAME=\$(echo \$SRC_FILE | xargs dirname | xargs basename | cut -d _ -f 2-)" >> $INFO_SCRIPT
echo "DATE=\$(exiv2 -g Exif.Image.DateTime -Pv \$SRC_FILE | sed -e 's:\:: :g' | awk '{print \$3 \".\" \$2 \".\" \$1 \" \" \$4 \":\" \$5}')" >> $INFO_SCRIPT
echo "echo \"\$NAME - \$DATE\"" >> $INFO_SCRIPT

chmod a+x $INFO_SCRIPT


# create slideshow script
echo "#!/bin/sh" > $RUN_SCRIPT

echo "feh -YxqFZz -B black -D 12 --auto-rotate --draw-tinted --info \"./printinfo.sh %F\" -C /usr/share/fonts/truetype/freefont/ -e FreeSans/25 -r /home/pi/Pictures" >> $RUN_SCRIPT

chmod a+x $RUN_SCRIPT


# add slideshow to autostart
AUTOSTART_FILE=/home/pi/.config/autostart/start-feh.desktop
mkdir /home/pi/.config/autostart
echo "[Desktop Entry]" > $AUTOSTART_FILE
echo "Name=Autostart-Script" >> $AUTOSTART_FILE
echo "Comment=FEHSlideshow" >> $AUTOSTART_FILE
echo "Type=Application" >> $AUTOSTART_FILE
echo "Exec=$RUN_SCRIPT" >> $AUTOSTART_FILE
echo "Terminal=false" >> $AUTOSTART_FILE
