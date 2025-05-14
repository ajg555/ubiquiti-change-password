#!/bin/bash

# Auth login
USER_LIST={"ubnt admin"}
PASSWD_LIST={"ubnt admin passwd3"}
SSH_PORT_LIST={"22 9090 9999"}

echo $USERS_NUMBER $PASSWDS_NUMBER $SSH_PORTS_NUMBER

# Variables to know the number of different users, passwords and ports used for authentication
USERS_NUMBER=${#USER_LIST[@]}
PASSWDS_NUMBER=${#PASSWD_LIST[@]}
SSH_PORTS_NUMBER=${#SSH_PORT_LIST[@]}

# New Ubiquti password (encrypted format!!!)
NEW_PASSWD="newPasswd"

# List containing equipment IPs
RADIOS_LIST="ubiquitiList.txt"

# Variable containing the radio's IP
RADIOS=$(/bin/cat $RADIOS_LIST)

# Function to change the password
changePasswd()
  {
    USER=$1        # user
    PASSWD=$2      # password
    PORT=$3        # SSH port
    DEVICE=$4      # radio IP
    NEW_PASSWD=$5  # new password


    # Using sshpass to enter password and data directly into terminal without direct interaction
    /usr/bin/sshpass -p $PASSWD ssh -p $PORT -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $USER@$DEVICE << EXIT

        # Remove users created on the device
        sed -i "/users./d" /tmp/system.cfg

        # changing user password
        echo users.status=enabled >> /tmp/system.cfg
        echo users.1.status=enabled >> /tmp/system.cfg
        echo users.1.password=$NEW_PASSWD >> /tmp/system.cfg
        echo users.1.name=admin >> /tmp/system.cfg

        # apply and restart device
        cfgmtd -w -p /etc
        reboot
EXIT
    # Tests whether radio access was obtained or not and logs it
    if [ $(echo $?) -eq 0 ];
      then
        echo "Success in accessing operation on the device: "$DEVICE >> log_changePasswdUbiquiti.txt
        # Tempo de espera até a tentativa de acessar o próximo rádio
		sleep 10;
      else
        echo "Failed to access operation on device: "$DEVICE " user:" $USER "/ password :" $PASSWD " port:" $PORT >> log_changePasswdUbiquiti.txt
    fi
}


echo -e  "\n\n\n\tRunning: "$(date) >> log_changePasswdUbiquiti.txt

#Loop containing the IPs from the device list
for IP in $RADIOS
do

  # Loop that determines the user in authentication
  for ((i=0;i<=(USERS_NUMBER-1);i++))
    do

    # Loop that determines the password during authentication
    for ((j=0;j<=(PASSWDS_NUMBER-1);j++))
      do

      # Loop that determines the port in authentication
      for ((k=0;k<=(SSH_PORTS_NUMBER-1);k++))
        do
          changePasswd ${USER_LIST[i]} ${PASSWD_LIST[j]} ${SSH_PORT_LIST[k]} $IP $NEW_PASSWD
      done
    done
  done

done

