#!/bin/bash
##########################################
# biz-balance - Cron-System - Controller #
# Ver: 1.00003  BB-Ver: 2013.8.00003     #
##########################################

# Backup and Replace IFS
OLD_IFS=${IFS}
IFS=$'\n'

BBCRON_OPENVPN_CONF="/etc/openvpn/openvpn.conf"
BBCRON_OPENVPN_REMOTE="vpn.biz-balance.de 443"

TMP_BBCRON_DB="/tmp/bb_cron_systems.bbcron"
TMP_BBHW_SIGNATURE="/tmp/bb_hw.signature"
TMP_BBFIO_TESTLOG="/tmp/bbdiskperftest.log"

TMP_BBREBOOT="/bbCron.reboot"
TMP_BBREBOOT_RUNNING="${TMP_BBREBOOT}.running"
TMP_BBRELOADSERVER="/bbCron.reload"

TMP_BBUNLOCKDB="/tmp/bb_cron_unlockdb.x17"

#
# Function - Block
#

create_hw_signature ()
{
	CPU_INFO=(`cat /proc/cpuinfo | egrep "^model name" | sed 's/^model name\s*: \(.*\)\s*$/\1/'`)
	SCSI_INFO=(`cat /proc/scsi/scsi | grep "Model:" | sed 's/^\s*Vendor:\s*\(.*\?[[:graph:]]\)\s*Model:\s*\(.*\?[[:graph:]]\)\s*Rev:\s*\(.*\?[[:graph:]]\)\s*$/\1|\2|\3/'`)
	IDE_INFO=""
	if [ -d "/proc/ide" ]
	then
		for HD in `ls -1 /proc/ide/`
		do
			if [[ "$HD" == hd* ]]
			then
				if [ "$IDE_INFO" != "" ]
				then
					IDE_INFO=${IDE_INFO}$'\n'
				fi
			IDE_INFO=${IDE_INFO}"${HD}:"`cat /proc/ide/${HD}/model`
			fi
		done
	fi
	
	IDE_INFO=("${IDE_INFO}")
	NETWORK_INFO=(`/sbin/ifconfig | egrep "HWaddr|Hardware Adress" | sed 's/^\([[:graph:]]\+\) .*\? \(HWaddr\|Hardware Adresse\?\) \([0-9a-f:\-]\+\).*$/\1|\3/' | grep -v "^tun"`)

# Daten sortieren
	bbCron_sort "CPU_INFO"
	bbCron_sort "SCSI_INFO"
	bbCron_sort "IDE_INFO"
	bbCron_sort "NETWORK_INFO"
	
# Datensaetze toString
	CPU_INFO_STRING="${CPU_INFO[*]}"
	SCSI_INFO_STRING="${SCSI_INFO[*]}"
	IDE_INFO_STRING="${IDE_INFO[*]}"
	NETWORK_INFO_STRING="${NETWORK_INFO[*]}"
	
# Signatur-String erstellen
	SIG_OLD_IFS=${IFS}
	IFS='';
	
	SIGNATURE_STRING="[CPU]"$'\n'"${CPU_INFO_STRING}"$'\n'"[IDE]"$'\n'"${IDE_INFO_STRING}"$'\n'"[SCSI]"$'\n'"${SCSI_INFO_STRING}"$'\n'"[NETWORK]"$'\n'"${NETWORK_INFO_STRING}";
	
	SIGNATURE=`echo -e "${SIGNATURE_STRING}\c" | md5sum`
	SIGNATURE=${SIGNATURE%% -*}
	
	echo ${SIGNATURE} > ${TMP_BBHW_SIGNATURE}.new
	echo ${SIGNATURE_STRING} >> ${TMP_BBHW_SIGNATURE}.new
	
	mv -f ${TMP_BBHW_SIGNATURE}.new ${TMP_BBHW_SIGNATURE}

	# echo "${SIGNATURE} > ${TMP_BBHW_SIGNATURE}"
	# echo "SIGNATURE_STRING:"
	# echo "${SIGNATURE_STRING}"
	# echo "END SIGNATURE_STRING"
	
	IFS=${SIG_OLD_IFS}
}

bbCron_sort()
{
	local SOURCE_ARRAYNAME="\${${1}[@]}"
	eval BBCRONSORT_ARRAY=("${SOURCE_ARRAYNAME}")
	local BBCRONSORT_NUMELEMS=${#BBCRONSORT_ARRAY[@]}
	let "BBCRONSORT_COMPARISONS = ${BBCRONSORT_NUMELEMS} - 1"
	local BBCRONSORT_COUNT=1 # Pass number

	while [ "${BBCRONSORT_COMPARISONS}" -gt 0 ]
	do
		local BBCRONSORT_IDX=0
		
		while [ "${BBCRONSORT_IDX}" -lt "${BBCRONSORT_COMPARISONS}" ]
		do
			if [[ ${BBCRONSORT_ARRAY[${BBCRONSORT_IDX}]} < ${BBCRONSORT_ARRAY[`expr ${BBCRONSORT_IDX} + 1`]} ]]
			then
				bbCron_sortExchange ${BBCRONSORT_IDX} `expr ${BBCRONSORT_IDX} + 1`
			fi
			
			let "BBCRONSORT_IDX += 1"
		done
		
		let "BBCRONSORT_COMPARISONS -= 1"
		let "BBCRONSORT_COUNT += 1"
	done
	
	eval "$1=(\"\${BBCRONSORT_ARRAY[@]}\")"
}

bbCron_sortExchange()
{
# Swaps two members of the array.
	local temp=${BBCRONSORT_ARRAY[$1]} #  Temporary storage
	
	BBCRONSORT_ARRAY[$1]=${BBCRONSORT_ARRAY[$2]}
	BBCRONSORT_ARRAY[$2]=$temp
	
	return
}

bbCron_unlockDB()
{
	# anlegen eines neuen Unlock-Keys:
	#
	# <keyfile>    :  bb_<kd_kuerzel>_dbcrypt.key
	# <headerfile> :  bb_<kd_kuerzel>_mysqlcrypt.header
	#
	# > dd if=/dev/urandom of=<keyfile> bs=1k count=2
	# > cryptsetup luksAddKey /dev/<device_partition> <keyfile>
	# >     cryptsetup luksHeaderBackup --header-backup-file <headerfile> /dev/<device_partition>
	#
	#
	# loeschen eines bestehenden Keys:
	# > cryptsetup luksRemoveKey /dev/<device_partition> <keyfile>
	# oder
	# > cryptsetup luksKillSlot /dev/<device_partition> <keyslotnumber>
	#
	#
	# Keyfile und Headerfile müssen von NFC im entsprechenden Projekt hinterlegt werden.
	# TODO: Integration der Keyerstellung und Ablage ins Installations-Management.
	#
	# Im Rahmen der Ersteinrichtung für einen Kunden, dessen Datenbankpartition bereits verschlüsselt ist.
	# - erzeugen eines neuen Key-Files einrichten dieses als Schlüssel für die Partition
	# - Übergabe des Key-Files auf einem dedizierten Datenträger (z.B. USB-Stick) an den Kunden,
	#   evtl. auch per Upload in das kunden-biz-balance an einen mit dem Kunden bestimmten Ort
	#   (z.B. Arbeitsverzeichnis im bb-Verwaltungsprojekt des Kunden, oder ins Dateimanagement)
	# - Einweisung des Kunden in die Bedienung des Systems
	# - Informierung des Kunden, das KeyFile auf einen eigenen, sicher zu verwahrenden Datenträge zu kopieren.
	#
	
	if [ -f ${TMP_BBUNLOCKDB}.lock ]
	then
	# UnlockDB noch gelockt, CronJob abbrechen...
		exit 90
	fi
	
# Lock-Datei erzeugen...
	touch "${TMP_BBUNLOCKDB}.lock"
	
	chown root:root "${TMP_BBUNLOCKDB}"
	chmod 400 "${TMP_BBUNLOCKDB}"
	
# MySQL-Server anhalten...
	service mysql stop >"${TMP_BBUNLOCKDB}.status" 2>&1
	
	# MySQL-Datenpartition entschlüsseln und mounten...
	
	# Test-Aufrufe (Development)
	#cryptdisks_start test_crypt >>"${TMP_BBUNLOCKDB}.status" 2>&1
	#mount /mnt/testCrypt >>"${TMP_BBUNLOCKDB}.status" 2>&1
	
# Produktiv-Aufrufe (Kundensysteme)
	cryptdisks_start mysql_crypt >>"${TMP_BBUNLOCKDB}.status" 2>&1
	mount /var/lib/mysql >>"${TMP_BBUNLOCKDB}.status" 2>&1
	
# MySQL-Server starten...
	service mysql start >>"${TMP_BBUNLOCKDB}.status" 2>&1
	
	# ggf. neuen Key erzeugen und alten zerstören...
	
# Lock-Datei entfernen...
	unlink "${TMP_BBUNLOCKDB}"
	unlink "${TMP_BBUNLOCKDB}.lock"
	
	return
}

#
# Main - Scriptblock
#

if [ -f ${TMP_BBREBOOT_RUNNING} ]
then
	rm ${TMP_BBREBOOT_RUNNING}
	exit 0
fi

# Reboot-Requests pruefen
if [ -f ${TMP_BBREBOOT} ]
then
	# Reboot-Request gesetzt.
	CRON_COUNT=`ps ch -C lynx -C curl | wc -l`
	
	if [ ${CRON_COUNT} -eq 0 ]
	then
		echo "Keine Cron-Jobs laufend, Server wird neugestartet!"
		logger -i -t biz-balance  -p local0.warning "Keine Cron-Jobs laufend, Server wird neugestartet!"
		mv ${TMP_BBREBOOT} ${TMP_BBREBOOT_RUNNING}
		/sbin/shutdown -r now
		exit 0
	else
		echo "Reboot-Request! Crons still running... Queued..."
		logger -i -t biz-balance  -p local0.info "Reboot-Request! Crons still running... Queued..."
		echo ${CRON_COUNT} > ${TMP_BBREBOOT}
	fi
fi

# Unlock-DB pruefen
if [ -f ${TMP_BBUNLOCKDB} ]
then
	logger -i -t biz-balance  -p local0.info "DB-Unlock Requested! Trying to unlock the DB-Partition an mount it..."
	bbCron_unlockDB
	logger -i -t biz-balance  -p local0.info "... DB-Unlock-Done!"
	exit 0
fi

# Reload-Request f. Cron-DB pruefen
if [ -f ${TMP_BBRELOADSERVER} ]
then
	# Reload fuer Mandanten/Server-Cache angefordert.
	rm ${TMP_BBCRON_DB}
	rm ${TMP_BBRELOADSERVER}
fi

# Cron-DB neu erstellen wenn nicht mehr vorhanden...
if [ ! -f ${TMP_BBCRON_DB} ] || [ ! -s ${TMP_BBCRON_DB} ]
then
	# Document-Roots raussuchen
	DOCUMENT_ROOTS=`cat /etc/apache2/sites-enabled/* | sed -n '1h;1!{/<VirtualHost\s*\(.*\?\)>.*\?\(DocumentRoot .*\)/ !H;g;/<VirtualHost\s*\(.*\?\)>.*\?\(DocumentRoot .*\)/ { /ServerName/ !{ s/DocumentRoot/ServerName localhost\n  DocumentRoot/ }; s/.*<VirtualHost\s*\(.*\?\)>.*\?\(ServerName\s*[[:graph:]]*\).*\?\(DocumentRoot .*\)/\1 -- \2 -- \3/g; p; n; }; h;};'`
	
	DOC_ROOT_ARRAY=()

	# Document-Roots verarbeiten
	for DOC_ROOT in ${DOCUMENT_ROOTS}
	do
		DOC_ROOT=`echo "${DOC_ROOT}" | sed 's/\s*DocumentRoot\s*\(\S.*\?\S\)\s*$/ \1/g' | sed 's/\s*ServerName\s*\([^:]*\)\(:[0-9]\+\)\?/ \1/g' | sed 's/\(\*\|_default_\)\(:[0-9]\+\)/localhost\2/'`
		DOC_ROOT=${DOC_ROOT%%/}
		
		THIS_SERVER=${DOC_ROOT%% --*}
		
		DOC_SERVER=${DOC_ROOT#*-- }
		DOC_SERVER=${DOC_SERVER% --*}
		
		echo "Find Mandanten... ${DOC_ROOT}"
		THIS_DOC_ROOT=${DOC_ROOT##*--}
		THIS_DOC_ROOT=${THIS_DOC_ROOT## }
		THIS_PROFILE_ROOT="${THIS_DOC_ROOT}/profiles"
		
		if [ -f ${THIS_DOC_ROOT}/cron.php ]
		then
			if [ -d ${THIS_PROFILE_ROOT} ]
			then
				echo "DocRoot exists: "${THIS_PROFILE_ROOT}
				echo "HW-Signature: ${THIS_DOC_ROOT}/tmp/hw.signature"
				
				if [ ! -e "${THIS_DOC_ROOT}/tmp/hw.signature" -a ! -h "${THIS_DOC_ROOT}/tmp/hw.signature" ]
				then
					ls -al "${THIS_DOC_ROOT}/tmp/hw.signature"
					echo "HW-SIG verlinken"
					echo "ln -s \"${TMP_BBHW_SIGNATURE}\" \"${THIS_DOC_ROOT}/tmp/hw.signature\""
					ln -s "${TMP_BBHW_SIGNATURE}" "${THIS_DOC_ROOT}/tmp/hw.signature"
				else
					echo "HW-SIG bereits verlinkt..."
				fi
				
				if [ ! -e "${THIS_DOC_ROOT}/tmp/fio.log" -a ! -h "${THIS_DOC_ROOT}/tmp/fio.log" ]
				then
					echo "link fio-log"
					ln -s "${TMP_BBFIO_TESTLOG}" "${THIS_DOC_ROOT}/tmp/fio.log"
				fi
				
				# Mandanten-Systeme herausfinden
				echo "/usr/bin/curl --fail -H \"Host: ${DOC_SERVER}\" http://${THIS_SERVER%%:443}/cron.php?action=get_mandanten"
				MANDANTEN_LISTE=`/usr/bin/curl --fail -H "Host: ${DOC_SERVER}" http://${THIS_SERVER%%:443}/cron.php?action=get_mandanten`
				echo "Mandanten-Liste: ${MANDANTEN_LISTE}"
				
				if [[ "${MANDANTEN_LISTE}" != *"DOCTYPE HTML PUBLIC"* ]]
				then
					for MANDANT in ${MANDANTEN_LISTE}
					do
						echo "Register Mandant-System: ${MANDANT}"
						DOC_ROOT_ARRAY[${#DOC_ROOT_ARRAY[*]}]="${THIS_SERVER} -- ${DOC_SERVER} -- ${THIS_DOC_ROOT} -- ${MANDANT}"
					done
				fi
			fi
		fi
	done
	
	# Doubletten entfernen
	DOC_ROOT_ARRAY=( $( printf "%s\n" "${DOC_ROOT_ARRAY[@]}" | sed 's/:80\b\|:443\b//' | awk 'x[$0]++ == 0' ) )
	
	# Gefundene, Document-Roots ausgeben...
	printf "%s\n" "${DOC_ROOT_ARRAY[@]}" > ${TMP_BBCRON_DB}
else
	echo "Datei bereits angelegt... "
fi

# bbCron-Mandanten-DB laden...
DOC_ROOT_ARRAY=`cat ${TMP_BBCRON_DB}`

# Alter der Hardware-Signatur feststellen
# pruefen ob HW-Signatur veraltet / aelter als 24h / wenn ja, neu erstellen...
# wenn HW-Signatur geaendert, in DOC_ROOTs aktualisieren / cp /
HW_SIG_NEW=0

if [ -f ${TMP_BBHW_SIGNATURE} ]
then
	echo "signature present"
	HW_SIG_DATE=`stat --format %Z ${TMP_BBHW_SIGNATURE}`
else
	echo "signature lost"
	HW_SIG_DATE=0
fi

HW_ACT_DATE=`date +%s`
HW_SIG_AGE=`expr ${HW_ACT_DATE} - ${HW_SIG_DATE}`

# Veraltete Signatur erneuern.
if [ ${HW_SIG_AGE} -gt 3600 ]
then
	echo "HW SIG outDated"
	create_hw_signature
	HW_SIG_NEW=1
fi

# CronJobs fuer die einzelnen  Mandanten ausfuehren...
# jeden Document-Root verarbeiten
# und pruefen welche Mandanten darin enthalten sind...

for DOC_ROOT in ${DOC_ROOT_ARRAY}
do
	echo "Mangling: ${DOC_ROOT}"
	MANDANT="${DOC_ROOT##*-- }"
	SERVER="${DOC_ROOT%% --*}"
	HOST="${DOC_ROOT#*-- }"
	HOST="${HOST%% --*}"
	
	SERVERDIR="${DOC_ROOT#*-- }"
	SERVERDIR="${SERVERDIR% --*}"
	
	if [ ${SERVERDIR} = ${HOST} ]
	then
		HOST=${SERVER}
		SERVER="localhost"
	fi
	
	echo "http://${HOST}/cron.php?dbname=${MANDANT}"
	
	if [ -e /usr/bin/curl ]
	then
		# curl vorhanden. Cron mit curl starten...
		/usr/bin/curl -s -S -H "Host: ${HOST}" http://${SERVER}/cron.php?dbname=${MANDANT} > /dev/null 2>&1 &
	else
		# kein curl vorhanden, lynx muss aber da sein.
		/usr/bin/lynx -source http://${HOST}/cron.php?dbname=${MANDANT} > /dev/null 2>&1 &
	fi
done

#
# Pruefen ob neue Config-Scripts vorhanden sind...
# TODO: wie genau... muss ggf. bereits im Cron-Teil passieren...
#
#

# local-Workfolder-Check fuer jeden Mandanten

echo "local Workfolder Check"
LBTW_START=8
LBTW_END=18
ACT_HOUR=`date +%H`

if [ ${ACT_HOUR} -ge ${LBTW_START} -a ${ACT_HOUR} -le ${LBTW_END} ]
then
	for DOC_ROOT in ${DOC_ROOT_ARRAY}
	do
		MANDANT="${DOC_ROOT##*-- }"
		logger -i -t ${MANDANT}  -p local0.debug "Verarbeite Cron fuer Arbeitsverzeichnisse fuer ${DOC_ROOT}"
		WORKFOLDER_DIR="${DOC_ROOT#*-- }"
		WORKFOLDER_DIR="${WORKFOLDER_DIR#*-- }"
		WORKFOLDER_DIR="${WORKFOLDER_DIR% --*}"
		WORKFOLDER_DIR="${WORKFOLDER_DIR}/profiles/${MANDANT}/work_folder/_cron/"
		
		if [ -d ${WORKFOLDER_DIR} ]
		then
			TMP_IFS=${IFS}
			IFS=${OLD_IFS}
			for WORKFOLDER in ${WORKFOLDER_DIR}*.sh
			do
				if [ -f ${WORKFOLDER} -a ! -f ${WORKFOLDER}.lock ]
				then
					echo "Running workfolder-script ${WORKFOLDER} for: ${MANDANT}..."
					logger -i -t ${MANDANT}  -p local0.debug "verarbeite Arbeitsverzeichnis-Datei: ${WORKFOLDER}"
					touch ${WORKFOLDER}.lock
					${WORKFOLDER}
					if [ ! -f ${WORKFOLDER} ]
					then
						unlink ${WORKFOLDER}.lock
					fi
					echo "...done"
				fi
			done
			IFS=${TMP_IFS}
		else
			logger -i -t ${MANDANT}  -p local0.debug "kein Cron-Verzeichnis fuer die Arbeitsverzeichnisse vorhanden"
		fi
	done
fi

# Integration Local-Backup...
#
# Local-Backup-Scripte der Mandanten sollten im Zeitfenster zwischen 1 (LBTW_START) und 5 Uhr (LBTW_END) geprueft und ggf. ausgefuehrt werden.
# eine "zeitlich fixe" Integration wie bisher direkt ueber die CronJob-Funktion ist nicht moeglich,
# da bei Ausfall bzw. zeitlicher Verzoegerung eines CronJob-Laufes die Backups ggf. nicht ausgefuehrt wuerden.
# Daher doppelte Absicherung ueber eine explizite .lock-Datei waehrend Ausfuehrung...

# local-Backup-Check fuer jeden Mandanten';
LBTW_START=1
LBTW_END=5
ACT_HOUR=`date +%H`

IONICE=""

if [ -x /usr/bin/ionice ]
then
	IONICE="ionice -c 2 -n 7"
fi

if [ ${ACT_HOUR} -ge ${LBTW_START} -a ${ACT_HOUR} -le ${LBTW_END} ]
then
	for DOC_ROOT in ${DOC_ROOT_ARRAY}
	do
		MANDANT="${DOC_ROOT##*-- }"
		logger -i -t ${MANDANT} -p local0.debug "Performing local-Backup for: ${DOC_ROOT}"
		BACKUP_DIR="${DOC_ROOT#*-- }"
		BACKUP_DIR="${BACKUP_DIR#*-- }"
		BACKUP_DIR="${BACKUP_DIR% --*}"
		BACKUP_DIR="${BACKUP_DIR}/profiles/${MANDANT}/work_folder/_backup"
		
		if [ -f ${BACKUP_DIR}/backup_local.sh -a ! -f /tmp/backup_local.sh.lock ]
		then
			TMP_IFS=${IFS}
			IFS=${OLD_IFS}
			logger -i -t ${MANDANT} -p local0.debug "Running backup_local.sh for: ${MANDANT}..."
			touch /tmp/backup_local.sh.lock
			nice -n 10 ${IONICE} ${BACKUP_DIR}/backup_local.sh
			unlink ${BACKUP_DIR}/backup_local.sh
			IFS=${TMP_IFS}
			
			if [ $? -eq 0 ]
			then
				unlink /tmp/backup_local.sh.lock
			fi
			
			logger -i -t ${MANDANT} -p local0.debug "done backup_local.sh for: ${MANDANT}..."
		fi
	done
fi

# OpenVPN - Check
# pruefen ob eine OpenVPN-Config zu uns existiert...
if [ -f ${BBCRON_OPENVPN_CONF} ]
then
	# OpenVPN-Conf existiert, pruefen ob zu uns...
	grep "remote ${BBCRON_OPENVPN_REMOTE}" ${BBCRON_OPENVPN_CONF}
	
	if [ $? -eq 0 ]
	then
		# ja, zu uns...
		# dann pruefen ob Verbindung steht...
		logger -i -t biz-balance -p local0.debug "check OpenVPN-Service..."
		
		/etc/init.d/openvpn status
		
		if [ $? -ne 0 ]
		then
			logger -i -t biz-balance -p local0.debug "OpenVPN-Service not running... trying to restart..."
			/etc/init.d/openvpn restart
		fi
	else
		# nein, nicht zu uns... warnung!?
		logger -i -t biz-balance -p local0.debug "OpenVPN Config error... Wrong Remote-target..."
	fi
fi

# Integration HardDisk-Performance-Test...
#
# sollte einmal woechentlich automatisch geschehen
# zusaetzlich per Request gesetzt...

FIOTEST_DAY=7
ACT_WDAY=`date +%u`
ACT_TIME=`date +%s`
FIOTEST_FILETIME=`stat --printf=%Y /tmp/bbdiskperftest.log`
FIOTEST_REFTIME=`expr ${ACT_TIME} - 86400`;

if [ ! -f /bbdiskperftest.dat -a -x /usr/bin/fio ] && ( [ ! -f "${TMP_BBFIO_TESTLOG}" ] || [ ${FIOTEST_FILETIME} -lt ${FIOTEST_REFTIME} -a ${ACT_WDAY} -eq ${FIOTEST_DAY} ] )
then
	/usr/bin/fio --rw=randrw --rwmixread=75 --name=bbdiskperftest --size=200M --bs=64k --direct=1 --refill_buffers --filename=/bbdiskperftest.dat --minimal --output="${TMP_BBFIO_TESTLOG}"
	rm /bbdiskperftest.dat
fi

# Restore IFS
IFS=${OLD_IFS}

