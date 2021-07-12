#!/bin/bash


#Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White


allppepods=$(kubectl get pods -n fed-upf -o json | jq -r '.items[].metadata.name' | grep '^(ppe|ippe)' -i -E)

#iterate over each bad pods
badppepods=()
mkdir -p output
for pod in $allppepods
do
  echo -e "Scanning the pod: ${Cyan}$pod${Color_Off}"
  searchLogs=$(kubectl logs $pod -n fed-upf -c ppe | grep -i 'vl_api_sw_interface_add_del_mac_address_reply_t_handler(): Reply code : -')
  searchResult=$?
  if [ $searchResult -eq 0 ] ; then 
    #echo -e "Error found in pod: ${Red}$pod${Color_Off}"
    echo "$searchLogs" > "output/$pod"
    #echo -e "Search results written to the file: output/$pod"
    badppepods+=($pod)
  #else
  #  echo -e "No error found in pod: ${Green}$pod${Color_Off}"
  fi
done


if (( ${#badppepods[@]} )); then
    echo -e "\n${BRed}Bad PPE pods are ${Color_Off} : ${badppepods[@]}"
else 
    echo -e "\n${BGreen}No bad PPE pod found. No action required!${Color_Off}"
    exit
fi

if [[ "$*" == "--fixPPE" ]]; then
  echo -e "\nFixing the PPE pods....."
else
  echo -e "\nPlease specify ${BYellow}--fixPPE${Color_Off} parameter to fix the PPE pods. Exiting the program!"
  exit
fi

#loop over the problematic pods and fix them
for badpod in ${badppepods[@]}
do
  echo -e "\n${Yellow}***********************${Color_Off} Fixing bad pod ${Cyan}$badpod${Color_Off} ${Yellow}***********************${Color_Off}"
  kubectl exec -it $badpod -n fed-upf -c ppe -- vppctl show ip6 neighbors | grep -i VirtualFuncEthernet0 | grep -v fe80 > output/${badpod}_neighbors_pre.txt
  #echo -e "Neighbors of the pod before fix are written to: output/${badpod}_neighbors_pre.txt"
  rowcount=$(cat output/${badpod}_neighbors_pre.txt | wc -l)
  echo -e "Total # of neighbors: ${rowcount}"
  i=0
  for (( i=1; i<=$rowcount; i++ )); 
  do
    ipaddress=$(cat output/${badpod}_neighbors_pre.txt | awk -v i=1 -v j=2 'FNR == i {print $j}')
    macaddress=$(cat output/${badpod}_neighbors_pre.txt | awk -v i=1 -v j=4 'FNR == i {print $j}')
    device=$(cat output/${badpod}_neighbors_pre.txt | awk -v i=1 -v j=5 'FNR == i {print $j}')
    #echo -e "Refreshing the neighbor: $ipaddress"
    kubectl exec -it $badpod -n fed-upf -c ppe -- vppctl set ip neighbor del $device $ipaddress $macaddress
    kubectl exec -it $badpod -n fed-upf -c ppe -- vppctl ping $ipaddress source $device > output/${badpod}_neighbors_ping.txt 
    # verify that entry has been deleted, needs to be done on table values returned on vppctl not helpful 
    echo -e "Refreshed neighbor: $ipaddress"
  done
  #echo -e "Neighbors of the pod after fix are written to: output/${badpod}_neighbors_post.txt"
  kubectl exec -it $badpod -n fed-upf -c ppe -- vppctl show ip6 neighbors | grep -i VirtualFuncEthernet0 | grep -v fe80 > output/${badpod}_neighbors_post.txt
  echo -e "${Yellow}-----------------------------------------${Color_Off} Fixed pod ${Yellow}-----------------------------------------${Color_Off}"
done
