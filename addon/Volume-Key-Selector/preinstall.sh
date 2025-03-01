﻿# External Tools

chmod -R 0755 $TMPDIR/addon/Volume-Key-Selector/tools
cp -R $TMPDIR/addon/Volume-Key-Selector/tools $UF 2>/dev/null

keytest() {
  ui_print "- 音量按键测试 "
  ui_print "  Vol Key Test "
  ui_print "- 请按下任意音量按键 "
  ui_print "  Press a Vol Key"
  ui_print "  如果你的设备是没有对应按键的，例如WSA，你只需要手动点击屏幕即可执行默认安装"
  ui_print "  If your device does not have a physical button, such as WSA, you just need to manually tap the screen to perform the default installation.  "
  (/system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $TMPDIR/events) || return 1
  return 0
}

chooseport() {
  # Original idea by chainfire @xda-developers, improved on by ianmacd @xda-developers
  #note from chainfire @xda-developers: getevent behaves weird when piped, and busybox grep likes that even less than toolbox/toybox grep
  while true; do
    /system/bin/getevent -lc 1 2>&1 | /system/bin/grep VOLUME | /system/bin/grep " DOWN" > $TMPDIR/events
    if (`cat $TMPDIR/events 2>/dev/null | /system/bin/grep VOLUME >/dev/null`); then
      break
    fi
  done
  if (`cat $TMPDIR/events 2>/dev/null | /system/bin/grep VOLUMEUP >/dev/null`); then
    return 0
  else
    return 1
  fi
}

chooseportold() {
  # Keycheck binary by someone755 @Github, idea for code below by Zappo @xda-developers
  # Calling it first time detects previous input. Calling it second time will do what we want
  keycheck
  keycheck
  SEL=$?
  if [ "$1" == "UP" ]; then
    UP=$SEL
  elif [ "$1" == "DOWN" ]; then
    DOWN=$SEL
  elif [ $SEL -eq $UP ]; then
    return 0
  elif [ $SEL -eq $DOWN ]; then
    return 1
  else
    abort "  Vol key not detected! Aborting!"
  fi
}

# Have user option to skip vol keys
OIFS=$IFS; IFS=\|; MID=false; NEW=false
case $(echo $(basename $ZIPFILE) | tr '[:upper:]' '[:lower:]') in
  *novk*) ui_print "- Skipping Vol Keys -";;
  *) if keytest; then
       VKSEL=chooseport
     else
       VKSEL=chooseportold
       ui_print "-  ! 使用旧的方法进行按键校验"
       ui_print "  ! Legacy device detected! Using old keycheck method"
       ui_print " "
       ui_print "- Vol Key Programming -"
       ui_print "-  请再按一次音量+:"
       ui_print "  Press Vol Up Again:"
       $VKSEL "UP"
       ui_print "-  请再按一次音量-:"
       ui_print "  Press Vol Down"
       $VKSEL "DOWN"
     fi;;
esac
IFS=$OIFS
