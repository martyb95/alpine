#!/bin/ash

#-------------------------
# Setup Global Variables
#-------------------------
WORKDIR="$HOME/alpine"
REPO="https://github.com/martyb95/alpine.git"
SBIN="/usr/sbin/"
INCL="/usr/includes/"

#----------------------------
#Setup Application Variables
#----------------------------
retval=
ulist=
iDock=
iBash=
iNano=
iGit=
iTele=
iComp=
iMOTD=

#====================================================================
#  Application User Input Functions
#====================================================================

#------------------------------------------
#  ChooseUsers()
#     Inputs users to be created into a
#     comma seperated list.  Blank name
#     ends the input loop.
#-----------------------------------------
ChooseUsers() {
   # Add User to System
   printf "\n"
   unset ulist
   while [ 1 ]; do
      GetInput "Enter Username"
      if [ -z "$retval" ]; then break; fi
      retval=$(Trim "$retval")
	  
      if [ -z $ulist ]; then
         ulist="$retval";
      else
         ulist=$(printf "%s,%s" "$ulist" "$retval");
      fi
   done
   printf "\n"
}

#------------------------------------------
#  ChoosePkgs()
#     Yes/No inputs to ask uer if they wish
#     to install a package on the system.
#-----------------------------------------
ChoosePkgs() {
    printf "\n"
    GetYesNo "Install Docker?" "No"; iDock="$retval"
    GetYesNo "Install Docker-Compose?" "No"; iComp="$retval"
    GetYesNo "Install Bash Shell?" "No"; iBash="$retval"
    GetYesNo "Install Nano Editor?" "Yes"; iNano="$retval"
    GetYesNo "Install GIT?" "No"; iGit="$retval"
    GetYesNo "Install Telegraf Agent?" "N"; iTele="$retval"
    printf "\n"
}

#------------------------------------------
#  ChooseSys()
#     Yes/No inputs to ask uer if they wish
#     to update systems functions.
#-----------------------------------------
ChooseSys() {
    printf "\n"
    GetYesNo "Remove Message of the Day (MOTD)?" "Yes"; iMOTD="$retval"
    printf "\n"
}

#------------------------------------------
#  ChooseAdapter()
#     User to select an adapter from a
#     filtered list of network adapters.
#-----------------------------------------
ChooseAdapter() {
   # Get the available network adapters
   unset retval
   GetNetAdapters; nlist=$(Lower "$retval")

   # Get the network adapter to use for configuration
   unset retval
   while [ 1 ]; do
      GetInput "Select Network Adapter <$nlist>" "eth0"; adapt=$(Lower "$retval")
      if [ -z "$adapt" ]; then
         printf "%s\n\n" "ERROR - Network adapter must be entered"
      else
         [[ "$nlist" =~ "$adapt" ]] && break
         printf "%s\n\n" "ERROR - Network adapter must be one of the listed"
      fi
   done

   # Get network info
   echo "====== Get Network Adapter info for $adapt ======" >> $LOG 2>&1
   GetAdapterInfo $adapt "dnstype" && dtype=$(Lower "$retval")
   GetAdapterInfo $adapt "hostname" && hname=$(Lower "$retval")
   GetAdapterInfo $adapt "ipaddress" && ipaddr=$retval
   GetAdapterInfo $adapt "netmask" && nmask=$retval
   GetAdapterInfo $adapt "gateway" && gway=$retval


   printf "\n      Adapter %s Settings\n" "$adapt"
   printf "     %-29s\n" $(printf "%-29s" | tr " " "-")
   printf '     %-12s %-16s %-16s \n' "Adapter:" "${adapt}"
   printf '     %-12s %-16s %-16s \n' "Hostname:" "${hname}"
   printf '     %-12s %-16s %-16s \n' "DNS Type:" "${dtype}"
   printf '     %-12s %-16s %-16s \n' "IP Address:" "${ipaddr}"
   printf '     %-12s %-16s %-16s \n' "Netmask:" "${nmask}"
   printf '     %-12s %-16s %-16s \n\n' "Gateway:" "${gway}"

   hname=$(Trim "$hname")
   dtype=$(Trim "$dtype")
   ipaddr=$(Trim "$ipaddr")
   nmask=$(Trim "$nmask")
   gway=$(Trim "$gway")

   local ChgNet="no"
   GetYesNo "Do you wish to change any of these settings?" "No"; ChgNet="$retval"
   if [ $ChgNet == "Y" ]; then ChooseNetwork; fi
}

#--------------------------------------------
#  ChooseNetwork()
#     If setting static IP this function
#     will prompt for hostname, dnstype,
#     ip address, network mask, and gateway.
#--------------------------------------------
ChooseNetwork() {
   printf "\n"
   # Change Hostname
   if [ -z "$hname" ]; then 
      GetInput "New Hostname" && hostname=$(Trim $(Lower "$retval"))
   else
      GetInput "New Hostname" "$hname" && hostname=$(Trim $(Lower "$retval"))
   fi

   local list="dhcp,static"
   GetFromList "New DNS Type" "$dtype" "$list" && dnstype=$(Trim $(Lower "$retval"))
   if [ "$dnstype" == "static" ]; then
      if [ -z "$ipaddr" ]; then
         GetInput "Enter New IP Address" && ipaddress=$(Trim "$retval")
      else
         GetInput "Enter New IP Address" "$ipaddr" && ipaddress=$(Trim "$retval")
      fi

      if [ -z "$nmask" ]; then
         GetInput "Enter New netmask" && netmask=$retval
      else
         GetInput "Enter New netmask" "$nmask" && netmask=$retval
      fi

      if [ -z "$gway" ]; then
         GetInput "Enter New Gateway" && gateway=$retval
      else
         GetInput "Enter New Gateway" "$gway"  && gateway=$retval
      fi
   fi
}



#==============================================================================
#   Application System Update Functions
#==============================================================================


#--------------------------------------------
#  UpdateRepos()
#     Function will update the APK repositories
#     and then perform and upgrade.
#--------------------------------------------
UpdateRepos() {
   echo "====== APK UPDATE ================" >> $LOG 2>&1
   apk update >> $LOG 2>&1
   SectionRow "Updating Repository with Updates" "UPDATED"

   echo "====== APK UPGRADE --purge ================" >> $LOG 2>&1
   apk upgrade --purge >> $LOG 2>&1
   SectionRow "Upgrading APK Repository" "UPGRADED"
   rm -rf /var/cache/apk/* /usr/src/* >> $LOG 2>&1
   SectionRow "Cleaning APK Repository" "CLEANED"
}

#------------------------------------------------
#  InstallPkgs()
#     Function will update the various
#     packages that were previously identified
#     as needing to be installed on the system.
#------------------------------------------------
InstallPkgs() {
   echo "====== APK ADD BASH ================" >> $LOG 2>&1
   if [ "$iBash" == "Y" ]; then
      apk add bash >> $LOG 2>&1
      SectionRow "Adding BASH package" "ADDED"
   else
      SectionRow "Adding BASH package" "BYPASSED" 1
   fi

   echo "====== APK ADD NANO ================" >> $LOG 2>&1
   if [ "$iNano" == "Y" ]; then
      apk add nano >> $LOG 2>&1
      SectionRow "Adding NANO editor package" "ADDED"
   else
      SectionRow "Adding NANO editor  package" "BYPASSED" 1
   fi

   echo "====== APK ADD GIT ================" >> $LOG 2>&1
   if [ "$iGit" == "Y" ]; then
      apk add git >> $LOG 2>&1
      SectionRow "Adding GIT package" "ADDED"
   else
      SectionRow "Adding GIT package" "BYPASSED" 1
   fi

   echo "====== APK ADD Docker ================" >> $LOG 2>&1
   if [ "$iDock" == "Y" ]; then
      apk add docker >> $LOG 2>&1
      SectionRow "Adding DOCKER package" "ADDED"
   else
      SectionRow "Adding DOCKER package" "BYPASSED" 1
   fi

   echo "====== APK ADD Docker-Compose ================" >> $LOG 2>&1
   if [ "$iComp" == "Y" ]; then
      apk add docker-compose >> $LOG 2>&1
      SectionRow "Adding Docker-Compose package" "ADDED"
   else
      SectionRow "Adding Docker-Compose package" "BYPASSED" 1
   fi

   echo "====== APK ADD Telegraph ================" >> $LOG 2>&1
   if [ "$iTele" == "Y" ]; then
      apk add telegraph >> $LOG 2>&1
      SectionRow "Adding Telegraph Agent package" "ADDED"
   else
      SectionRow "Adding Telegraph Agent package" "BYPASSED" 1
   fi

   UpdateRepos
}


#--------------------------------------------
#  SetupGIT()
#     Function will clone the repo from
#     GitHub.
#--------------------------------------------
SetupGIT () {
   # Check for existing alpine directory
   echo "====== CHECKING FOR GIT DIRECTORY ================" >> $LOG 2>&1
   if [[ ! -d $WORKDIR ]]; then
      echo "====== CD $HOME ================" >> $LOG 2>&1
      chdir $HOME >> $LOG 2>&1
      SectionRow "CD to $HOME Directory" "CHANGED"

      echo "====== MKDIR $WORKDIR ================" >> $LOG 2>&1
      mkdir $WORKDIR >> $LOG 2>&1
      SectionRow "Make $WORKDIR Directory" "CREATED"

      echo "====== CD $WORKDIR ================" >> $LOG 2>&1
      chdir $WORKDIR >> $LOG 2>&1
      SectionRow "CD to $WORKDIR Directory" "CHANGED"

      echo "====== GIT CLONE $REPO ======" >> $LOG    2>&1
      git clone $REPO >> $LOG 2>&1
      SectionRow "Cloning ALPINE Repository" "DONE"
   else
      SectionRow "Clone ALPINE Repository from GITHUB" "BYPASSED" 1
   fi
   
   ProcessGIT
}

#------------------------------------------------
#  ProcessGIT()
#     Function will update the permissions on
#     the various scripts in the cloned GIT.
#------------------------------------------------
ProcessGIT() {
   # change intop alpine and update permissions
   echo "====== CD $WORKDIR ======" >> $LOG 2>&1
   cd $WORKDIR >> $LOG 2>&1
   SectionRow "Changing to $WORKDIR" "CHANGED"

   echo "====== CHMOD +X * ======" >> $LOG 2>&1
   chmod +x *  >> $LOG 2>&1
   chmod +x *.sh  >> $LOG 2>&1
   SectionRow "Set EXECUTE permissions on all scripts" "CHANGED"

   echo "====== CD PACKAGES DIRECTORY ======" >> $LOG 2>&1
   cd "$WORKDIR/packages" >> $LOG 2>&1
   SectionRow "Changing to $WORKDIR/packages" "CHANGED"

   echo "====== CHMOD +X * ======" >> $LOG 2>&1
   chmod +x *  >> $LOG 2>&1
   chmod +x *.sh  >> $LOG 2>&1
   SectionRow "Set EXECUTE permissions on all scripts" "CHANGED"

   echo "====== CD SCRIPTS DIRECTORY ======" >> $LOG 2>&1
   cd "$WORKDIR/scripts" >> $LOG 2>&1
   SectionRow "Changing to $WORKDIR/scripts" "CHANGED"

   echo "===== CREATE Directory $INCL ======" >> $LOG 2>&1
   if [[ ! -d "$INCL" ]]; then
      mkdir "$INCL" >> $LOG 2>&1
      SectionRow "Creating Directory $INCL" "CREATED"
   else
      SectionRow "Creating Directory $INCL" "BYPASSED" 1
   fi

   echo "====== Move SCRIPTS to $INCL  ======" >> $LOG 2>&1
   cp -f *.sh "$INCL"  >> $LOG 2>&1
   chmod -R 407 "$INCL" >> $LOG 2>&1
   SectionRow "Copy scripts to $INCL" "COPIED"

   echo "====== CD $WORKDIR DIRECTORY ======" >> $LOG 2>&1
   cd "$WORKDIR" >> $LOG 2>&1
   SectionRow "Changing to $WORKDIR" "CHANGED"

   echo "====== Move program to $SBIN ======" >> $LOG 2>&1
   cp -f alpine-setup "$SBIN"  >> $LOG 2>&1
   cp -f *.sh "$INCL"  >> $LOG 2>&1
   chmod -R 407 "$INCL" >> $LOG 2>&1
   SectionRow "Copy main program to $SBIN" "COPIED"
}

#------------------------------------------------
#  AddUser() $1 $2
#     Function will update the various
#     packages that were previously identified
#     as needing to be installed on the system.
#
#     where: $1 - username to add to system
#            $2 - group to add user to
#------------------------------------------------
AddUser() {
   if [ -z "$1" ]; then echo "ERROR - no user specified for AddUser()"; return 1; fi
   if [ -z "$2" ]; then echo "ERROR - no user group specified for AddUser()"; return 1; fi

   local USR=$(Lower $(Trim "$1"))
   local GRP=$(Lower $(Trim "$2"))
   echo "====== CHECK FOR USER $USR ======" >> $LOG 2>&1
   if [[ $(id -u "$USR") -ne 0 ]]; then
      echo "====== USER $USR ALREADY EXISTS ======" >> $LOG 2>&1
      SectionRow "Add User $USR" "BYPASSED" 1
   else
      echo "====== Adding User $USR =====" >> $LOG 2>&1
      SectionPrt "Adding User $USR to system"
      adduser -G "$GRP" "$USR"
      SectionRow "Add User $USR" "ADDED"
   fi

   echo "===== CREATE Directory /home/$USR/.ssh =====" >> $LOG 2>&1
   if [[ ! -d "/home/$USR/.ssh" ]]; then
      mkdir /home/$USR/.ssh >> $LOG 2>&1
      chown -R $USR /home/$USR/.ssh >> $LOG 2>&1
      chmod 744 /home/$USR/.ssh >> $LOG 2>&1
      SectionRow "Creating Directory /home/$USR/.ssh" "CREATED"
   else
      SectionRow "Creating Directory /home/$USR/.ssh" "BYPASSED" 1
   fi

   echo "===== Moving SSH KEYS to /home/$USR/.ssh =====" >> $LOG 2>&1
   if [[ -f "authorized_keys" ]]; then
      cp -f authorized_keys /home/$USR/.ssh >> $LOG 2>&1
      chown -R $USR /home/$USR/.ssh >> $LOG 2>&1
      chmod 644 /home/$USR/.ssh/authorized_keys >> $LOG 2>&1
      SectionRow "Moving SSH KEYS to /home/$USR/.ssh" "MOVED"
   else
      SectionRow "Moving SSH KEYS to /home/$USR/.ssh" "NOT FOUND" 1
   fi

   echo "===== CREATE Directory /root/.ssh =====" >> $LOG 2>&1
   if [[ ! -d "/root/.ssh" ]]; then
      mkdir /root/.ssh >> $LOG 2>&1
      chown -R $USR /home/$USR/.ssh >> $LOG 2>&1
      chmod 744 /root/.ssh >> $LOG 2>&1
      SectionRow "CREATE Directory /root/.ssh" "CREATED"
   else
      SectionRow "CREATE Directory /root/.ssh" "BYPASSED" 1
   fi

   echo "===== Moving SSH KEYS to /root/.ssh =====" >> $LOG 2>&1
   if [[ -f "authorized_keys" ]]; then 
      cp -f authorized_keys /root/.ssh >> $LOG 2>&1
      chown -R $USR /root/.ssh >> $LOG 2>&1
      chmod 644 /root/.ssh/authorized_keys >> $LOG 2>&1
      SectionRow "Moving SSH KEYS to /root/.ssh" "MOVED"
   else
      SectionRow "Moving SSH KEYS to /root/.ssh" "NOT FOUND" 1
   fi

   echo "====== CD $HOME ======" >> $LOG 2>&1
   cd $HOME >> $LOG 2>&1
   SectionRow "Changing to $HOME" "CHANGED"

   echo "===== Restart the SSH Daemon =====" >> $LOG 2>&1
   service sshd restart >> $LOG 2>&1
   SectionRow "Restart the SSH Daemo" "RESTARTED"

   UpdateProfile
}


#------------------------------------------------
#  UpdateProfile()
#     Function will update the PROFILE file in
#     the /etc directory to have an updated
#     terminal prompt for SSH sessions.
#------------------------------------------------
UpdateProfile() {
   echo "====== CD $WORKDIR/linux ======" >> $LOG 2>&1
   cd $WORKDIR/linux  >> $LOG 2>&1
   SectionRow "Changing to $WORKDIR/linux" "DONE"

   echo "====== MOVE PROFILE to $fprof ======" >> $LOG 2>&1
   if [[ -f "profile" ]]; then mv -f profile $fprof >> $LOG 2>&1; fi
   SectionRow "Moving PROFILE script to $fprof" "DONE"
}

#------------------------------------------------
#  SystemSetup()
#     Function will backup files that are going
#     to be modified as part of this operation.
#------------------------------------------------
SystemSetup() {
    # Update the ALPINE package repository
    echo "====== Update the ALPINE package repository ======" >> $LOG 2>&1
    if [ -f "$frepo" ]; then
       sed -i '1,10d' $frepo >> $LOG 2>&1
       echo 'http://dl-cdn.alpinelinux.org/alpine/latest-stable/main' >> $frepo
       echo 'http://dl-cdn.alpinelinux.org/alpine/latest-stable/community' >> $frepo
       echo 'http://dl-cdn.alpinelinux.org/alpine/edge/main' >> $frepo
       echo '#http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> $frepo
       echo 'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> $frepo
       apk update >> $LOG 2>&1
       SectionRow "Update the ALPINE package repository" "COMPLETED"
    else
       SectionRow "Update the ALPINE package repository" "NO FILE" 1
    fi

    echo "====== CD $WORKDIR/ssh/ ======" >> $LOG 2>&1
    cd $WORKDIR/ssh >> $LOG 2>&1
    SectionRow "Changing to $WORKDIR/ssh/" "CHANGED"

    #  Move files to SSH directories
    echo "===== Moving SSH config file to $fssh =====" >> $LOG 2>&1
    if [[ -f "ssh_config" ]]; then
      cp -f ssh_config $fssh >> $LOG 2>&1
      SectionRow "Moving SSHD config file to $fssh" "MOVED"
    else
      SectionRow "Moving SSHD config file to $fssh" "NO FILE"
    fi

    #  Move files to SSH directories
    echo "===== Moving SSHD config files to $fsshd =====" >> $LOG 2>&1
    if [[ -f "sshd_config" ]]; then
      cp -f sshd_config $fsshd >> $LOG 2>&1
      SectionRow "Moving SSHD config file to $fsshd" "MOVED"
    else
      SectionRow "Moving SSHD config file to $fsshd" "NO FILE"
    fi

    # Remove MOTD
    echo "====== Removing MOTD File ======" >> $LOG 2>&1
    if [ -f "/etc/motd" ]; then
       if [ "$iMOTD" == "Y" ]; then
          rm /etc/motd >> $LOG 2>&1
          SectionRow "Removing Message Of The Day(MOTD) File" "REMOVED"
       else
          SectionRow "Removing Message Of The Day(MOTD) File" "BYPASSED" 1
       fi
    else
       SectionRow "Removing Message Of The Day(MOTD) File" "NO FILE" 1
    fi
}
