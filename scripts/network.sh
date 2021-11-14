#!/bin/ash

#-----------------------------------------
#  Set Network File Variables
#-----------------------------------------
fhosts="/etc/hosts"
fhostname="/etc/hostname"
finterfaces="/etc/network/interfaces"


#-----------------------------------------
#  Set Network Function Variables
#-----------------------------------------
nlist=
adapt=
dtype=
dnstype=
hostname=
hname=
ipaddr=
ipaddress=
nmask=
netmask=
gway=
gateway=


#===================================
#   Network Functions
#===================================
BackupNet() {
    echo "====== Create Backup of $fhosts ======" >> $LOG 2>&1
    if [ ! -f "${fhost}.bak" ]; then
       cp $fhosts "${fhost}.bak" >> $LOG 2>&1
       SectionRow "Create Backup of $fhosts" "CREATED"
    else
       SectionRow "Create Backup of $fhosts" "BYPASSED" 1
    fi
	
    echo "====== Create Backup of $fhostname ======" >> $LOG 2>&1
    if [ ! -f "${fhostname}.bak" ]; then
       cp $fhostname "${fhostname}.bak" >> $LOG 2>&1
       SectionRow "Create Backup of $fhostname" "CREATED"
    else
       SectionRow "Create Backup of $fhostname" "BYPASSED" 1
    fi
	
    echo "====== Create Backup of $finterfaces ======" >> $LOG 2>&1
    if [ ! -f "${finterfaces}.bak" ]; then
       cp $finterfaces "${finterfaces}.bak" >> $LOG 2>&1
       SectionRow "Create Backup of $finterfaces" "CREATED"
    else
       SectionRow "Create Backup of $finterfaces" "BYPASSED" 1
    fi
}

#-------------------------------------------------
#  GetNetAdapters()
#     Returns a filtered list of network adapters
#-------------------------------------------------
GetNetAdapters() {
   unset retval
   retval=$(ip link | awk -F: '$0 !~ "br-|vir|veth|dock|^[^0-9]"{print $2;getline}')
   retval=${retval//[$' \t']/}
   retval=${retval//[$'\r\n']/,}
}

#-------------------------------------------------
#  GetAdapterInfo()  $1 $2
#     where: $1 - the adapter name
#            $2 - query identifier to get info
#-------------------------------------------------
GetAdapterInfo() {
   if [ -z "$1" ]; then echo "ERROR - No adapter passed to GetAdapterInfo()"; return 1; fi
   if [ -z "$2" ]; then echo "ERROR - No query string passed to GetAdapterInfo()"; return 1; fi

   unset retval
   if [ ! -z $1 ]; then
      if [ ! -z $2 ]; then
         local adp=$(Lower $(Trim "$1"))
         local info=$(Lower $(Trim "$2"))

         case $info in
           "ipaddress")
                retval=$(ifconfig $adp | awk '/t addr:/{gsub(/.*:/,"",$2);print$2}');;
           "netmask")
                retval=$(ifconfig $adp | awk '/t addr:/{gsub(/.*:/,"",$4);print$4}');;
            "macaddr")
               retval=$(ifconfig $adp | awk '/Link encap:/{gsub(/.*:/,"",$4);print$5}');;
            "linktype")
               retval=$(ifconfig $adp | awk '/Link encap:/{gsub(/.*:/,"",$3);print$3}');;
            "dnstype")
               retval=$(grep -A 4 'iface '$adp "$finterfaces" | awk '{print $4}');;
            "hostname")
               retval=$(grep -A 4 'iface '$adp "$finterfaces" | grep 'hostname' | awk '{print $2}');;
            "gateway")
               retval=$(grep -A 4 'iface '$adp "$finterfaces" | grep 'gateway' | awk '{print $2}');;
           *) echo "Sorry, Invalid choice!";;
         esac
      fi
   fi
   
   if [ -z "$retval" ]; then retval=" "; fi
   return 0
}

#--------------------------------------------
#  ChangeHosts()
#     This will do an update of the host
#     name for machine.
#--------------------------------------------
ChangeHosts() {
    echo "====== Update the ALPINE HOSTS file with $hostname ======" >> $LOG 2>&1
    if [ -f "$fhosts" ]; then
       local tmp=$(grep -A 0 "127.0.0.1" $fhosts | awk '{print $2}' | awk -F "." '{print $1}')
       sed -i "s/$tmp/$hostname/g" $fhosts >> $LOG 2>&1
       SectionRow "Update the ALPINE HOSTS file with $hostname" "COMPLETED"
    else
       SectionRow "Update the ALPINE HOSTS file with $hostname" "NO FILE" 1
    fi

    # Change Hostname File
    echo "====== Update the ALPINE HOSTNAME file with $hostname ======" >> $LOG 2>&1
    if [ -f "$fhostname" ]; then
       tmp=$(awk '{print $1}' $fhostname)
       sed -i "s/$tmp/$hostname/g" $fhostname >>$LOG 2>&1
       SectionRow "Update the ALPINE HOSTNAME file with $hostname" "COMPLETED"
    else
       SectionRow "Update the ALPINE HOSTNAME file with $hostname" "NO FILE" 1
    fi
}



#--------------------------------------------
#  UpdateInterface()
#     This will do an update of the network
#     settings for either a static or DHCP
#     network setup.
#--------------------------------------------
UpdateInterface() {
   if [ -z "$adapt" ]; then echo "ERROR - no network adapter specified for UpdateInterface()"; return 1; fi
   if [ -z "$dtype" ]; then echo "ERROR - there is no old dns type specified for UpdateInterface()"; return 1; fi

   if [ -z "$hostname" ]; then hostname="$hname"; fi
   if [ -z "$dnstype" ]; then 
      dnstype="$dtype"
      address="$ipaddr"
      netmask="$nmask"
      gateway="$gway"
   fi

   sed -i "s/iface $adapt inet $dtype/iface $adapt inet $dnstype/" $finterfaces
   ChangeHosts
   if [ "$dnstype" == "static" ]; then
      UpdateStatic
   else
      UpdateDHCP
   fi
}

#--------------------------------------------
#  UpdateStatic()
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

      echo "====== Update the Network Interface Info ($finterfaces) ======" >> $LOG 2>&1
      sed -i "s/$ipaddr/$ipaddress/" $finterfaces
      sed -i "s/$nmask/$netmask/" $finterfaces
      sed -i "s/$gway/$gateway/" $finterfaces
      SectionRow "Update the Network Interface Information" "UPDATED"
   else
      #echo "DHCP --> Static Processing"
      if [ -z "$dnstype" ]; then echo "ERROR - no new dns type specified for UpdateStatic()"; return 1; fi
      if [ -z "$hostname" ]; then echo "ERROR - no new hostname specified for UpdateStatic()"; return 1; fi
      if [ -z "$ipaddress" ]; then echo "ERROR - no new ip address specified for UpdateStatic()"; return 1; fi
      if [ -z "$netmask" ]; then echo "ERROR - no new netmask specified for UpdateStatic()"; return 1; fi
      if [ -z "$gateway" ]; then echo "ERROR - no new gateway specified for UpdateStatic()"; return 1; fi

      echo "====== Update the Network Interface Info ($finterfaces) ======" >> $LOG 2>&1
      local value="\ \thostname $hostname\n\taddress $address\n\tnetmask $netmask\n\tgateway $gateway"
      local line=$(grep -nm1 "iface $adapt inet" $finterfaces | cut -d: -f1)
      sed -i "$((line+1)),$((line+2))d" $finterfaces
      sed -i "/iface $adapt inet $dnstype/a $value" $finterfaces
      SectionRow "Update the Network Interface Information" "UPDATED"
   fi
}

#--------------------------------------------
#  UpdateDHCP()
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

      echo "====== Update the Network Interface Info ($finterfaces) ======" >> $LOG 2>&1
      local line=$(grep -nm1 "iface $adapt inet" $finterfaces | cut -d: -f1)
      sed -i "$((line+1)),$((line+5))d" $finterfaces
      local value="\ \thostname $hostname"
      sed -i "/iface $adapt inet $dnstype/a $value" $finterfaces
      SectionRow "Update the Network Interface Information" "UPDATED"
   else
      echo "DHCP --> DHCP Processing"
      if [ -z "$hostname" ]; then echo "ERROR - no new hostname specified for UpdateDHCP()"; return 1; fi
      if [ -z "$dnstype" ]; then echo "ERROR - no new dns type specified for UpdateDHCP()"; return 1; fi

      echo "====== Update the Network Interface Info ($finterfaces) ======" >> $LOG 2>&1
      local line=$(grep -nm1 "iface $adapt inet" $finterfaces | cut -d: -f1)
      sed -i "$((line+1)),$((line+2))d" $finterfaces
      local value="\ \thostname $hostname"
      sed -i "/iface $adapt inet $dnstype/a $value" $finterfaces
      SectionRow "Update the Network Interface Information" "UPDATED"
   fi
}
