#!/bin/ash

#======================================
#  Global Variables
#=====================================
retval=""


#======================================
#  Input Functions Definitions
#======================================

#------------------------------------------
#  GetInput() $1 $2
#     Where: $1 - prompt for input
#            $2 - <optional> default value
#------------------------------------------
GetInput() {
   if [ -z "$1" ]; then echo "ERROR - Must provide a prompt for input"; return 1; fi

   unset retval
   if [ -z $2 ]; then printf "%s: " "$1"; else printf "%s [%s]: " "$1" "$2"; fi
   IFS="~"
   read retval
   if [ -z $retval ]; then retval=$(Trim "$2"); fi  
   retval=$(echo $retval | sed 's/^[ \t]*//;s/[ \t]*$//')
   retval=$(Trim "$retval")
   unset IFS
   return 0
}

#------------------------------------------
#  GetYesNo() $1 $2
#     Where: $1 - prompt for input
#            $2 - <optional> default value
#------------------------------------------
GetYesNo() {
   if [ -z "$1" ]; then echo "ERROR - Must provide a prompt for input"; return 1; fi
   GetInput "$1" "$2"
   if [ ! -z "$retval" ]; then
      retval=$(Upper "$retval")
      retval="${retval:0:1}"
   fi
}

#------------------------------------------
#  GetFromList() $1 $2 $3
#     Where: $1 - prompt for input
#            $2 - default value
#            $3 - csv list of choices
#------------------------------------------
GetFromList() {
   if [ -z "$1" ]; then echo "ERROR - Must provide a prompt for input"; return 1; fi
   if [ -z "$2" ]; then echo "ERROR - Must provide a default for input"; return 1; fi
   if [ -z "$3" ]; then echo "ERROR - Must provide a list of choices"; return 1; fi

   local list=$(Lower $(Trim "$3"))
   local prmpt=$(printf "%s <%s>" "$1" "$list")
   while [ 1 ]; do
      GetInput "$prmpt" $(Lower $(Trim "$2"))
      if [ -z "$retval" ]; then retval=$(Lower $(Trim "$2")); fi
      retval=$(Lower $(Trim "$retval"))

      if [ ! -z $list ]; then
         [[ "$list" =~ "$retval" ]] && break
      fi

      printf "ERROR - Invalid choice. Must be in list\n\n"
   done
   printf "\n"
}
