#!/bin/ash

#======================================
#  System Functions Definitions
#======================================

#-----------------------------------------
#  Set System File Variables
#-----------------------------------------
fsshd="/etc/ssh/sshd_config"
fssh="/etc/ssh/ssh_config"
frepo="/etc/apk/repositories"
fprof="/etc/profile"



#======================================
#  System Functions Definitions
#======================================

#-------------------------------------------------
#   BackupSys()
#      Will backup copies of system files prior
#      to modification by the script.
#-------------------------------------------------
BackupSys() {
    echo "====== Create Backup of $fssh ======" >> $LOG 2>&1
    if [ ! -f "${fssh}.bak" ]; then
       cp $fssh "${fsshs}.bak" >> $LOG 2>&1
       SectionRow "Create Backup of $fssh" "DONE"
    else
       SectionRow "Create Backup of $fssh" "BYPASSED" 1
    fi

    echo "====== Create Backup of $fsshd ======" >> $LOG 2>&1
    if [ ! -f "${fsshd}.bak" ]; then
       cp $fsshd "${fsshd}.bak" >> $LOG 2>&1
       SectionRow "Create Backup of $fsshd" "DONE"
    else
       SectionRow "Create Backup of $fsshd" "BYPASSED" 1
    fi

    echo "====== Create Backup of $frepo ======" >> $LOG 2>&1
    if [ ! -f "${frepo}.bak" ]; then
       cp $frepo "${frepo}.bak" >> $LOG 2>&1
       SectionRow "Create Backup of $frepo" "DONE"
    else
       SectionRow "Create Backup of $frepo" "BYPASSED" 1
    fi
	
    echo "====== Create Backup of $fprof ======" >> $LOG 2>&1
    if [ ! -f "${fprof}.bak" ]; then
       cp $fprof "${fprof}.bak" >> $LOG 2>&1
       SectionRow "Create Backup of $fprof" "DONE"
    else
       SectionRow "Create Backup of $fprof" "BYPASSED" 1
    fi
}

#-------------------------------------------------
#   LogOpen() $1
#
#     where: $1 - filename of the log file
#-------------------------------------------------
LogOpen() {
   if [ -f $LOG ]; then rm -f $LOG; fi
   printf "===== %s =====\t\t%s\n\n" "$1" "$(date '+%Y-%m-%d')" > $LOG 2>&1
}


#--------------------------------------------
#  CheckPriv()  $1
#
#     where: $1 - (optional) print message
#---------------------------------------------
CheckPriv() {
   # Initialize ALPINE SETUP
   if [[ $(id -u) -ne 0 ]]; then
      printf "\n\n%s\n\n" "ERROR - This script must be run with elevated privileges" 
      exit 1
   fi
   if [ ! -z "$1" ]; then
      echo "====== Check Privileges ================" >> $LOG 2>&1
      SectionRow "Check for Elevated Privileges" "User: $(whoami)"   
   fi
   return 0
}
