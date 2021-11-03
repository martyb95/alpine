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
