#!/bin/sh
TOKEN=TELEGRAM_BOT_TOKEN
ID=TELEGRAM_ID
PROJ=Project
#AUTNO=9
UPD_CN=codename
PACK_URL=https://example.com/update.tar.gz
CHCK_URL=https://example.comcheck.md5
LOGFILE=/tmp/update.log
DIRE=/home/root/app/
DST=update
CHCKFILE=check.md5
CTAB="crontab 0 2 1 1 MON systemctl reboot >/dev/null 2>&1"
AUTNO="$(sqlite3 $DIRE/conf.sqlite "SELECT value FROM settings WHERE key = 'SP'" | cut -d'|' -f2)"
#Strings
START_STG="👨‍💻 Aktualizator zaczyna prace na $PROJ 00$AUTNO. Kod aktualizacji: $UPD_CN."
CHCKN_STG="MD5 OK! Unpacking.."
CHCKE_STG="❌ Blad md5! Aktualizacja nie udała sie!"
END_STG="✅ Udana Aktualizacja!"

cd /tmp/
rm -r $UPD_CN
mkdir $UPD_CN
cd $UPD_CN
curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$ID -d text="$START_STG" > /dev/null
rm *
rm $LOGFILE 
echo "[SYSTEM] Pobieranie paczki aktualizacyjnej" >> $LOGFILE 2>&1
wget $PACK_URL >> $LOGFILE 2>&1
echo "[SYSTEM] Pobieranie checksums" >> $LOGFILE
wget $CHCK_URL >> $LOGFILE 2>&1
cat $CHCKFILE >> $LOGFILE 2>&1
if md5sum -c $CHCKFILE; then
    md5sum -c $CHCKFILE >> $LOGFILE 2>&1
    echo "[SYSTEM] Checksum zgodny." >> $LOGFILE 2>&1
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$ID -d text="$CHCKN_STG" > /dev/null
    # RUN
    echo "[SYSTEM] Tworzenie kopii zapasowej $DST " >> $LOGFILE 2>&1
    mv $DIRE/$DST $DIRE/$DST.bak
    echo "[SYSTEM] Stworzono kopie zapasowa $DST.bak " >> $LOGFILE 2>&1
    echo "[SYSTEM] Kopiowanie $DST.tar.gz do $DIRE " >> $LOGFILE 2>&1
    cp $DST.tar.gz $DIRE/
    cd $DIRE
    echo "[SYSTEM] Rozpakowanie $DST " >> $LOGFILE 2>&1
    tar -xzf $DST.tar.gz >> $LOGFILE 2>&1
    echo "[SYSTEM] Lista zawartosci $DIRE " >> $LOGFILE 2>&1
    ls -aFl $DIRE >> $LOGFILE 2>&1
    echo "[SYSTEM] Lista wszystkiego z $DST w $DIRE " >> $LOGFILE 2>&1
    ls -aFl $DIRE/$DST* >> $LOGFILE 2>&1
    #echo "[SYSTEM] Tworzenie CRONTAB'a do aktualizacji" >> $LOGFILE 2>&1
    #echo $CTAB > /tmp/$UPD_CN/cron.txt
    #crontab /tmp/$UPD_CN/cron.txt >> $LOGFILE 2>&1
    #echo "[SYSTEM] Tworzenie CRONTAB'a do aktualizacji" >> $LOGFILE 2>&1
    #crontab -l  >> $LOGFILE 2>&1
    echo "[SYSTEM] Udana aktualizacja" >> $LOGFILE 2>&1
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$ID -d text="$END_STG" > /dev/null
else
    echo "[SYSTEM] Blad checksum. Aktualizacja przerwana" >> $LOGFILE
    curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$ID -d text="$CHCKE_STG" > /dev/null
fi
LOGTR="$(cat $LOGFILE | curl -F 'sprunge=<-' http://sprunge.us)"
LOG_STG="🖨️ Log aktualizacji: $LOGTR"
curl -s -X POST https://api.telegram.org/bot$TOKEN/sendMessage -d chat_id=$ID -d text="$LOG_STG" > /dev/null
