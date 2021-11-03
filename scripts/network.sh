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
   return 0
}
