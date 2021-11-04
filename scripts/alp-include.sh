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
#   Application Network Functions
#==============================================================================


#--------------------------------------------
#  UpdateInterface()
#     This will do an update of the network
#     settings for either a static or DHCP
#     network setup.
#--------------------------------------------
UpdateInterface() {
   if [ -z "$adapt" ]; then echo "ERROR - no network adapter specified for UpdateInterface()"; return 1; fi
   if [ -z "$dtype" ]; then echo "ERROR - there is no old dns type specified for UpdateInterface()"; return 1; fi
   if [ -z "$dnstype" ]; then echo "ERROR - there is no new dns type specified for UpdateInterface()"; return 1; fi

   sed -i "s/iface $adapt inet $dtype/iface $adapt inet $dnstype/" $finterfaces
   if [ "$dnstype" == "static" ]; then
      UpdateStatic
   else
      UpdateDHCP
   fi
}

#--------------------------------------------
#  ChooseNetwork()
#     If setting static IP this function
#     will prompt for hostname, dnstype,
#     ip address, network mask, and gateway.
#--------------------------------------------
UpdateStatic() {
   if [ -z "$adapt" ]; then echo "ERROR - no network adapter specified for UpdateStatic()"; return 1; fi
   if [ -z "$dtype" ]; then echo "ERROR - no existing dns type specified for UpdateStatic()"; return 1; fi

   if [ "$dtype" == "static" ]; then
      #echo "Static --> DHCP Processing"
      if [ -z "$hname" ]; then echo "ERROR - no existing hostname specified for Static()"; return 1; fi
      if [ -z "$hostname" ]; then echo "ERROR - no new hostname specified for UpdateStatic()"; return 1; fi
      if [ -z "$ipaddr" ]; then echo "ERROR - no existing ip address specified for UpdateStatic()"; return 1; fi
      if [ -z "$nmask" ]; then echo "ERROR - no existing netmask specified for UpdateStatic()"; return 1; fi
      if [ -z "$gway" ]; then echo "ERROR - no existing gateway specified for UpdateStatic()"; return 1; fi

      sed -i "s/hostname $hname/hostname $hostname/" $finterfaces
      sed -i "s/$ipaddr/$address/" $finterfaces
      sed -i "s/$nmask/$netmask/" $finterfaces
      sed -i "s/$gway/$gateway/" $finterfaces
   else
      #echo "DHCP --> Static Processing"
      if [ -z "$dnstype" ]; then echo "ERROR - no new dns type specified for UpdateStatic()"; return 1; fi
      if [ -z "$hostname" ]; then echo "ERROR - no new hostname specified for UpdateStatic()"; return 1; fi
      if [ -z "$ipaddress" ]; then echo "ERROR - no new ip address specified for UpdateStatic()"; return 1; fi
      if [ -z "$netmask" ]; then echo "ERROR - no new netmask specified for UpdateStatic()"; return 1; fi
      if [ -z "$gateway" ]; then echo "ERROR - no new gateway specified for UpdateStatic()"; return 1; fi

      local value="\ \thostname $hostname\n\taddress $address\n\tnetmask $netmask\n\tgateway $gateway"
      local line=$(grep -nm1 "iface $adapt inet" $finterfaces | cut -d: -f1)
      sed -i "$((line+1)),$((line+2))d" $finterfaces
      sed -i "/iface $adapt inet $dnstype/a $value" $finterfaces
   fi
}

#--------------------------------------------
#  ChooseNetwork()
#     If setting static IP this function
#     will prompt for hostname, dnstype,
#     ip address, network mask, and gateway.
#--------------------------------------------
UpdateDHCP() {
   if [ -z "$adapt" ]; then echo "ERROR - no network adapter specified for UpdateDHCP()"; return 1; fi
   if [ -z "$dtype" ]; then echo "ERROR - no existing dns type specified for UpdateDHCP()"; return 1; fi

   if [ "$dtype" == "static" ]; then
      echo "Static --> DHCP Processing"
      if [ -z "$hostname" ]; then echo "ERROR - no new hostname specified for UpdateDHCP()"; return 1; fi
      if [ -z "$dnstype" ]; then echo "ERROR - no new dns type specified for UpdateDHCP()"; return 1; fi

      local line=$(grep -nm1 "iface $adapt inet" $finterfaces | cut -d: -f1)
      sed -i "$((line+1)),$((line+5))d" $finterfaces
      local value="\ \thostname $hostname"
      sed -i "/iface $adapt inet $dnstype/a $value" $finterfaces
   else
      echo "DHCP --> DHCP Processing"
      if [ -z "$hostname" ]; then echo "ERROR - no new hostname specified for UpdateDHCP()"; return 1; fi
      if [ -z "$dnstype" ]; then echo "ERROR - no new dns type specified for UpdateDHCP()"; return 1; fi

      local line=$(grep -nm1 "iface $adapt inet" $finterfaces | cut -d: -f1)
      sed -i "$((line+1)),$((line+2))d" $finterfaces
      local value="\ \thostname $hostname"
      sed -i "/iface $adapt inet $dnstype/a $value" $finterfaces
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
   if [ "$iBash" == "Y" ]; then
      echo "====== APK ADD BASH ================" >> $LOG 2>&1
      apk add bash >> $LOG 2>&1
      SectionRow "Adding BASH package" "ADDED"
   fi

   if [ "$iNano" == "Y" ]; then
      echo "====== APK ADD NANO ================" >> $LOG 2>&1
      apk add nano >> $LOG 2>&1
      SectionRow "Adding NANO editor package" "ADDED"
   fi

   if [ "$iGit" == "Y" ]; then
      echo "====== APK ADD GIT ================" >> $LOG 2>&1
      apk add git >> $LOG 2>&1
      SectionRow "Adding GIT package" "ADDED"
   fi

   if [ "$iDock" == "Y" ]; then
      echo "====== APK ADD Docker ================" >> $LOG 2>&1
      apk add docker >> $LOG 2>&1
      SectionRow "Adding Docker package" "ADDED"
   fi

   if [ "$iComp" == "Y" ]; then
      echo "====== APK ADD Docker-Compose ================" >> $LOG 2>&1
      apk add docker-compose >> $LOG 2>&1
      SectionRow "Adding Docker-Compose package" "ADDED"
   fi

   if [ "$iTele" == "Y" ]; then
      echo "====== APK ADD Telegraph ================" >> $LOG 2>&1
      apk add telegraph >> $LOG 2>&1
      SectionRow "Adding Telegraph Agent package" "ADDED"
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

      echo "====== GIT CLONE $REPO ======" >> $LOG    2>&1
      git clone $REPO >> $LOG 2>&1
      SectionRow "Cloning ALPINE Repository" "DONE"
   else
      SectionRow "Clone ALPINE Repository from GITHUB" "BYPASSED" 1
   fi
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
   SectionRow "Set EXECUTE permissions on all scripts" "DONE"

   echo "====== CD PACKAGES DIRECTORY ======" >> $LOG 2>&1
   cd "$WORKDIR/packages" >> $LOG 2>&1
   SectionRow "Changing to $WORKDIR/packages" "CHANGED"

   echo "====== CHMOD +X * ======" >> $LOG 2>&1
   chmod +x *  >> $LOG 2>&1
   chmod +x *.sh  >> $LOG 2>&1
   SectionRow "Set EXECUTE permissions on all scripts" "DONE"

   echo "====== CD SCRIPTS DIRECTORY ======" >> $LOG 2>&1
   cd "$WORKDIR/scripts" >> $LOG 2>&1
   SectionRow "Changing to $WORKDIR/packages" "CHANGED"

   echo "====== CHMOD +X *.sh ======" >> $LOG 2>&1
   chmod +x *.sh  >> $LOG 2>&1
   SectionRow "Set EXECUTE permissions on all scripts" "DONE"

   echo "===== CREATE Directory $INCL ======" >> $LOG 2>&1
   if [[ ! -d "$INCL" ]]; then
      mkdir "$INCL" >> $LOG 2>&1
      chmod -R 407 "$INCL" >> $LOG 2>&1
      SectionRow "Creating Directory $INCL" "CREATED"
   else
      SectionRow "Creating Directory $INCL" "BYPASSED" 1
   fi

   echo "====== Move SCRIPTS to $INCL  ======" >> $LOG 2>&1
   cp *.sh "$INCL"  >> $LOG 2>&1
   chmod -R 407 "$INCL" >> $LOG 2>&1
   SectionRow "Copy scripts to $INCL" "COPIED"

   echo "====== CD $WORKDIR DIRECTORY ======" >> $LOG 2>&1
   cd "$WORKDIR" >> $LOG 2>&1
   SectionRow "Changing to $WORKDIR" "CHANGED"

   echo "====== Move program to  to $SBIN ======" >> $LOG 2>&1
   cp alpine-setup "$SBIN"  >> $LOG 2>&1
   cp *.sh "$SBIN"  >> $LOG 2>&1
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
      adduser -G "$GRP" "$USR"  >> $LOG 2>&1
      SectionRow "Add User $USR" "ADDED"
   fi

   echo "====== CD $WORKDIR/ssh/ ======" >> $LOG 2>&1
   cd $WORKDIR/ssh >> $LOG 2>&1
   SectionRow "Changing to $WORKDIR/ssh/" "CHANGED"

   #  Move files to SSH directories
   echo "===== Moving SSH files to /etc/ssh/ =====" >> $LOG 2>&1
   if [[ -f "sshd_config" ]]; then
      cp -f sshd_config /etc/ssh/ >> $LOG 2>&1
      SectionRow "Moving SSH files to /etc/ssh/" "MOVED"
   else
      SectionRow "Moving SSH files to /etc/ssh/" "NOT FOUND" 1
   fi

   echo "===== CREATE Directory /home/$USR/.ssh =====" >> $LOG 2>&1
   if [[ ! -d "/home/$USR/.ssh" ]]; then
      mkdir /home/$USR/.ssh >> $LOG 2>&1
      SectionRow "Creating Directory /home/$USR/.ssh" "CREATED"
   else
      SectionRow "Creating Directory /home/$USR/.ssh" "BYPASSED" 1
   fi

   echo "===== Moving SSH KEYS to /home/$USR/.ssh =====" >> $LOG 2>&1
   if [[ -f "authorized_keys" ]]; then
      cp -f authorized_keys /home/$USR/.ssh >> $LOG 2>&1
      SectionRow "Moving SSH KEYS to /home/$USR/.ssh" "MOVED"
   else
      SectionRow "Moving SSH KEYS to /home/$USR/.ssh" "NOT FOUND" 1
   fi

   echo "===== CREATE Directory /root/.ssh =====" >> $LOG 2>&1
   if [[ ! -d "/root/.ssh" ]]; then
      mkdir /root/.ssh >> $LOG 2>&1
      SectionRow "CREATE Directory /root/.ssh" "CREATED"
   else
      SectionRow "CREATE Directory /root/.ssh" "BYPASSED" 1
   fi

   echo "===== Moving SSH KEYS to /root/.ssh =====" >> $LOG 2>&1
   if [[ -f "authorized_keys" ]]; then 
      cp -f authorized_keys /root/.ssh >> $LOG 2>&1
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
#  MoveScripts()
#     Function will move scripts from the GIT
#     clone directory to /USR/SBIN.
#------------------------------------------------
MoveScripts() {
   #  Move scripts to /USR/SBIN
   #  change intop alpine and update permissions
   echo "====== CD $WORKDIR ======" >> $LOG 2>&1
   cd $WORKDIR  >> $LOG 2>&1
   SectionRow "Changing to $WORKDIR" "DONE"

   echo "====== MOVE ALP-SETUP to $SBIN ======" >> $LOG 2>&1
   if [[ -f "alp-setup" ]]; then mv -f alp-setup "$SBIN" >> $LOG 2>&1; fi
   SectionRow "Moving ALP-SETUP script to $SBIN" "DONE"

   echo "====== MOVE UPDATE-ALP to $SBIN ======" >> $LOG 2>&1
   if [[ -f "update-alp" ]]; then mv -f update-alp "$SBIN" >> $LOG 2>&1; fi
   SectionRow "Moving UPDATE-ALP script to $SBIN" "DONE"

   echo "====== CD $HOME ======" >> $LOG 2>&1
   cd $HOME  >> $LOG 2>&1
   SectionRow "Changing to $HOME" "DONE"
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
    # Create backup of modified files
    echo "====== Create Backup of $fhosts ======" >> $LOG 2>&1
    cp $fhosts /etc/hosts.bak  >> $LOG 2>&1
    SectionRow "Create Backup of $fhosts" "DONE"

    echo "====== Create Backup of $fhostname ======" >> $LOG 2>&1
    cp $fhostname /etc/hostname.bak >> $LOG 2>&1
    SectionRow "Create Backup of $fhostname" "DONE"

    echo "====== Create Backup of $finterfaces ======" >> $LOG 2>&1
    cp $finterfaces /etc/network/interfaces.bak >> $LOG 2>&1
    SectionRow "Create Backup of $finterfaces" "DONE"

    echo "====== Create Backup of $fssh ======" >> $LOG 2>&1
    cp $fssh /etc/ssh/ssh_config.bak >> $LOG 2>&1
    SectionRow "Create Backup of $fssh" "DONE"

    echo "====== Create Backup of $fsshd ======" >> $LOG 2>&1
    cp $fsshd /etc/ssh/sshd_config.bak >> $LOG 2>&1
    SectionRow "Create Backup of $fsshd" "DONE"

    echo "====== Create Backup of $frepo ======" >> $LOG 2>&1
    cp $frepo /etc/apk/repositories.bak >> $LOG 2>&1
    SectionRow "Create Backup of $frepo" "DONE"

    echo "====== Create Backup of $fprof ======" >> $LOG 2>&1
    cp $fprof /etc/profile.bak >> $LOG 2>&1
    SectionRow "Create Backup of $fprof" "DONE"

    # Update the ALPINE package repository
    echo "====== Update the ALPINE package repository ======" >> $LOG 2>&1
    sed -i '1,10d' $frepo >> $LOG 2>&1
    echo 'http://dl-cdn.alpinelinux.org/alpine/latest-stable/main' >> $frepo
    echo 'http://dl-cdn.alpinelinux.org/alpine/latest-stable/community' >> $frepo
    echo 'http://dl-cdn.alpinelinux.org/alpine/edge/main' >> $frepo
    echo '#http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> $frepo
    echo 'http://dl-cdn.alpinelinux.org/alpine/edge/community' >> $frepo
    apk update >> $LOG 2>&1
    SectionRow "Update the ALPINE package repository" "COMPLETED"

    # Change SSH Config File
    echo "====== Update the SSH Port to 9922 ======" >> $LOG 2>&1
    sed -i "s/#   Port/Port/" $fssh >> $LOG 2>&1
    sed -i "s/Port 22/Port 9922/" $fssh >> $LOG 2>&1
    sed -i "s/#Port/Port/" $fsshd >> $LOG 2>&1
    sed -i "s/Port 22/Port 9922/" $fsshd >> $LOG 2>&1
    SectionRow "Update the SSH Port to 9922" "UPDATED"


    # Change Hosts File
    echo "====== Update the ALPINE HOSTS file with $hostname ======" >> $LOG 2>&1
    local tmp=$(grep -A 0 "127.0.0.1" $fhosts | awk '{print $2}' | awk -F "." '{print $1}')
    sed -i "s/$tmp/$hostname/g" $fhosts >> $LOG 2>&1
    SectionRow "Update the ALPINE HOSTS file with $hostname" "COMPLETED"


    # Change Hostname File
    echo "====== Update the ALPINE HOSTNAME file with $hostname ======" >> $LOG 2>&1
    tmp=$(awk '{print $1}' $fhostname) 
    sed -i "s/$tmp/$hostname/g" $fhostname >>$LOG 2>&1
    SectionRow "Update the ALPINE HOSTS file with $hostname" "COMPLETED"


    # Remove MOTD
    echo "====== Removing MOTD File ======" >> $LOG 2>&1
    if [ "$iMOTD" == "Y" ]; then
       rm /etc/motd >> $LOG 2>&1
       SectionRow "Removing Message Of The Day(MOTD) File" "REMOVED"
    else
       SectionRow "Removing Message Of The Day(MOTD) File" "BYPASSED" 1
    fi
}
