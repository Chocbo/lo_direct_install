#!/bin/bash
#
# Libreoffice download&install(update) packets from LO mirror script
# Autors - Rousk,Chocobo
# http://www.mintlinux.ru/blogs/lin-lichka/ustanovka-openoffice-libreoffice-cherez-terminal.html
# === Changelog ===
# 23/05/16 - v0.1 (First version)
# checking architecture and choice available versions with zenity
#
# 24/05/16 - v0.2 
# added zenity progressbar based on https://gist.github.com/felix-orduz/79f284a4d51a0171eac8
#
CHECK_BASE(){
if which dpkg >/dev/null; then
    BASE="deb"
    PM="dpkg -i"
elif which rpm >/dev/null; then
    BASE="rpm"
    if which dnf >/dev/null; then
        PM="dnf install -y"
    elif which yum >/dev/null; then
        PM="yum localinstall -y"
    else
        PM="rpm -i"
    fi
fi
}

# zenity-progressbar func
Z_DOWNLOAD() {
  echo $1
  rand="$RANDOM `date`"
  pipe="/tmp/LO/pipe.`echo '$rand' | md5sum | tr -d ' -'`"
  mkfifo $pipe
  wget -c $1 2>&1 | while read data;do
    if [ "`echo $data | grep '^Length:'`" ]; then
      total_size=`echo $data | grep "^Length:" | sed 's/.*\((.*)\).*/\1/' |  tr -d '()'`
    fi
    if [ "`echo $data | grep '[0-9]*%' `" ];then
      percent=`echo $data | grep -o "[0-9]*%" | tr -d '%'`
      current=`echo $data | grep "[0-9]*%" | sed 's/\([0-9BKMG.]\+\).*/\1/' `
      speed=`echo $data | grep "[0-9]*%" | sed 's/.*\(% [0-9BKMG.]\+\).*/\1/' | tr -d ' %'`
      remain=`echo $data | grep -o "[0-9A-Za-z]*$" `
      echo $percent
      echo "#Скачивается $1\n$current готово ($percent%)\nСкорость : $speed/сек\nОсталось времени : $remain"
    fi
  done > $pipe &

  wget_info=`ps ax |grep "wget.*$1" |awk '{print $1"|"$2}'`
  wget_pid=`echo $wget_info|cut -d'|' -f1 `

  zenity --progress --auto-close --text="Соединение с $1\n\n\n" --width="350" --title="Загрузка"< $pipe
  if [ "`ps -A |grep "$wget_pid"`" ];then
    kill $wget_pid
    STOP_IT
  fi
  rm -f $pipe
}
D_DOWNLOAD(){
wget "$1" 2>&1 | \
    stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' |\
    dialog --gauge "Скачиваем LO_$VERSION $2 (файл $3 из 3)" 10 100
}

# check what architecture is used
ARCH_CHECK(){
MACHINE_TYPE=`uname -m`
if [ ${MACHINE_TYPE} = 'x86_64' ]; then
  ARCH=x86_64
  ARCH2=x86-64
else
  ARCH=x86
  ARCH2=x86
fi
}
GET_VERSIONS(){
mkdir -p /tmp/LO/{download,$BASE} && cd /tmp/LO/download
touch /tmp/LO/lo_v_a
wget -qO- download.documentfoundation.org/libreoffice/stable/ | grep -o '[0-9]\.[0-9]\.[0-9]' | uniq > /tmp/LO/lo_v_a
}
GET_DL_LINKS(){
dllink_base=http://download.documentfoundation.org/libreoffice/stable/$VERSION/$BASE/$ARCH/LibreOffice_$VERSION\_Linux_$ARCH2\_$BASE.tar.gz
dllink_lang=http://download.documentfoundation.org/libreoffice/stable/$VERSION/$BASE/$ARCH/LibreOffice_$VERSION\_Linux_$ARCH2\_$BASE\_langpack_ru.tar.gz
dllink_help=http://download.documentfoundation.org/libreoffice/stable/$VERSION/$BASE/$ARCH/LibreOffice_$VERSION\_Linux_$ARCH2\_$BASE\_helppack_ru.tar.gz
}
# remove temporary downloads folder
RM_TMP_FOLDER(){
rm -rf /tmp/LO/
}
STOP_IT(){
zenity --error --text="Выполнена отмена или случилась непредвиденная ошибка.\nРабота инструмента прекращена." --title="Завершение" --width="350"
exit
}
RM_TMP_FOLDER

ARCH_CHECK
CHECK_BASE
if which zenity >/dev/null; then
    # first window (greetings)
    zenity --info --width=350 --text="Привет!\n\n Сейчас мы будем устанавливать LibreOffice из $BASE-пактов c оф.сайта. \n\n Сейчас можно быть уверенным в следующем- подойдёт $ARCH версия для $BASE-based систем. \n\n Давай уже выберем какую именно... "
    # get available version from LO mirror and show user choice
    GET_VERSIONS
    VERSION=`cat /tmp/LO/lo_v_a | \
            sed 's/^/FALSE\n/g' | \
            zenity --width=350 --height=250  --list --radiolist --separator=' ' \
                    --title="Выбор версии" \
                    --text="Пожалуйста выберите версию:" --column="" --column="Files"`
    case $? in
    0 )
         if [  -z "$VERSION" ]; then 
            STOP_IT; 
         fi
         ;;
    1 )
        STOP_IT
    esac
    GET_DL_LINKS
    Z_DOWNLOAD "$dllink_base"
    Z_DOWNLOAD "$dllink_lang"
    Z_DOWNLOAD "$dllink_help"
elif which dialog >/dev/null; then
    dialog --title "Hello" --msgbox "Привет!\n\n Сейчас мы будем устанавливать LibreOffice из .$BASE-пактов c оф.сайта. \n\n Сейчас можно быть уверенным в следующем- подойдёт $ARCH версия для $BASE-based систем. \n\n Давай уже выберем какую именно... " 15 50
    GET_VERSIONS
    ITEMS_COUNT=$(cat /tmp/LO/lo_v_a | wc -l)
    echo $ITEMS_COUNT
    ITEMS=$(cat -n /tmp/LO/lo_v_a | sed -z 's/\n/ off /'g)
    echo $ITEMS
    dialog --backtitle "Processor Selection" --radiolist "Select Processor type:" 10 40 $ITEMS_COUNT $ITEMS 2> /tmp/LO/dialog_result
    DIALOG_RESULT=$(cat /tmp/LO/dialog_result)
    VERSION=$(cat  /tmp/LO/lo_v_a | awk " NR == $DIALOG_RESULT ")
    echo $VERSION
    GET_DL_LINKS
    D_DOWNLOAD "$dllink_base" "base" 1
    D_DOWNLOAD "$dllink_lang" "langpack_ru" 2
    D_DOWNLOAD "$dllink_help" "helppack_ru" 3
else
    echo "Zenity or dialog is not installed, now quitting"
    exit
fi
#TODO - extract & install process to both of ui
tar -xvf LibreOffice_$VERSION\_Linux_$ARCH2\_$BASE.tar.gz 
tar -xvf LibreOffice_$VERSION\_Linux_$ARCH2\_$BASE\_langpack_ru.tar.gz 
tar -xvf LibreOffice_$VERSION\_Linux_$ARCH2\_$BASE\_helppack_ru.tar.gz 
find /tmp/LO/download/ -name *.$BASE -exec mv -t /tmp/LO/$BASE/ {} +
cd /tmp/LO/$BASE/
sudo $PM *.$BASE
