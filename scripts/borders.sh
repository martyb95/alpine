#!/bin/ash

. "$SCRIPTDIR/string.sh"
#======================================
#   Colored Text Attributes
#======================================
RSET='\e[0m'    # Text Reset

# Regular           Bold                Underline           High Intensity      BoldHigh Intens     Background          High Intensity Backgrounds
BLK='\e[0;30m';     BBLK='\e[1;30m';    UBLK='\e[4;30m';    IBLK='\e[0;90m';    BIBLK='\e[1;90m';   On_BLK='\e[40m';    On_IBLK='\e[0;100m';
RED='\e[0;31m';     BRED='\e[1;31m';    URED='\e[4;31m';    IRED='\e[0;91m';    BIRED='\e[1;91m';   On_RED='\e[41m';    On_IRED='\e[0;101m';
GRE='\e[0;32m';     BGRE='\e[1;32m';    UGRE='\e[4;32m';    IGRE='\e[0;92m';    BIGRE='\e[1;92m';   On_GRE='\e[42m';    On_IGRE='\e[0;102m';
YEL='\e[0;33m';     BYEL='\e[1;33m';    UYEL='\e[4;33m';    IYEL='\e[0;93m';    BIYEL='\e[1;93m';   On_YEL='\e[43m';    On_IYEL='\e[0;103m';
BLU='\e[0;34m';     BBLU='\e[1;34m';    UBLU='\e[4;34m';    IBLU='\e[0;94m';    BIBLU='\e[1;94m';   On_BLU='\e[44m';    On_IBLU='\e[0;104m';
PUR='\e[0;35m';     BPUR='\e[1;35m';    UPUR='\e[4;35m';    IPUR='\e[0;95m';    BIPUR='\e[1;95m';   On_PUR='\e[45m';    On_IPUR='\e[0;105m';
CYA='\e[0;36m';     BCYA='\e[1;36m';    UCYA='\e[4;36m';    ICYA='\e[0;96m';    BICYA='\e[1;96m';   On_CYA='\e[46m';    On_ICYA='\e[0;106m';
WHI='\e[0;37m';     BWHI='\e[1;37m';    UWHI='\e[4;37m';    IWHI='\e[0;97m';    BIWHI='\e[1;97m';   On_WHI='\e[47m';    On_IWHI='\e[0;107m';



#======================================
#   Global Variables
#======================================
TWIDTH=65

#======================================
#   Form Printing Function Definitions
#======================================


#--------------------------------------------
# PrintHdr() $1 $2
#
#       where: $1 is the string for the title
#              $2 is the width of the border
#---------------------------------------------
PrintHdr() {
   if [ -z "$1" ]; then echo "ERROR - Must provide a title to PrintHdr()"; return 1; fi
   if [ -z "$2" ]; then echo "ERROR - Must provide a form width to PrintHdr()"; return 1; fi

   TWIDTH=$2
   if [ -z $2 ]; then  TWIDTH=40; fi
   if [ $TWIDTH -lt 40 ]; then TWIDTH=40; fi

   local sp=$(printf "%-150s")
   local dash=$(printf "%150s" | tr " " "-")
   local wdsh1=$(($TWIDTH - 2))
   local wdsh2=$(($TWIDTH - 31))
   local fil1=0
   local fil2=0

   printf "\n\n+%s+\n" "${dash:0:$wdsh1}"
   printf "++%s++%s++\n" "${dash:0:$wdsh2}" "${dash:0:25}"
   printf "||%s||%s||\n" "${sp:0:$wdsh2}" "${sp:0:25}"

   fil1=$((14 - ${#AUTHOR}))
   printf "||%s||   Author: %-s%s||\n" "${sp:0:$wdsh2}" "$AUTHOR" "${sp:0:$fil1}"

   local TITL=$(Center "$1" $wdsh2)
   fil1=$(($wdsh2 - ${#TITL}))
   fil2=$((14 - ${#VER}))
   printf "||${BIYEL}%s${RSET}%s||  Version: %-s%s||\n" "$TITL" "${sp:0:$fil1}" "$VER" "${sp:0:$fil2}"

   local dt="$(date '+%Y-%m-%d')"
   fil1=$((14 - ${#dt}))
   printf "||%s||     Date: %-s%s||\n" "${sp:0:$wdsh2}" "$dt" "${sp:0:$fil1}"
   printf "||%s||%s||\n" "${sp:0:$wdsh2}" "${sp:0:25}"
   printf "++%s++%s++\n" "${dash:0:$wdsh2}" "${dash:0:25}"
   printf "+%s+\n" "${dash:0:$wdsh1}"
   return 0
}

#--------------------------------------------
# SectionHdr() $1 $2
#
#       where: $1 is the string for the title
#              $2 (optional) is a flag to not
#                 print a blank line at the
#                 bottom of the header
#---------------------------------------------
SectionHdr() {
   if [ -z "$1" ]; then echo "ERROR - Must provide a section header to SectionHdr()"; return 1; fi

   local sp=$(printf "%-150s")
   local dash=$(printf "%150s" | tr " " "-")
   local wdsh1=$(($TWIDTH - 2))

   printf "\n+%s+\n" "${dash:0:wdsh1}"
   local TITL=$(Center "$1" $wdsh1)
   fil1=$(($wdsh1 - ${#TITL}))
   printf "|${BICYA}%s${RSET}%s|\n" "$TITL" "${sp:0:$fil1}"
   printf "+%s+\n" "${dash:0:wdsh1}"
   if [ -z $2 ]; then printf "|%s|\n" "${sp:0:wdsh1}" ; fi
   return 0
}

#--------------------------------------------
# SectionFtr() $1
#
#       where: $1 - (optional) flag to not
#                   print a blank line at the
#                   top of the footer
#---------------------------------------------
SectionFtr() {
   local sp=$(printf "%-150s")
   local dash=$(printf "%100s" | tr " " "-")
   local wdsh1=$(($TWIDTH - 2))
   if [ -z $1 ]; then printf "|%s|\n" "${sp:0:$wdsh1}"  ; fi
   printf "+%s+\n" "${dash:0:$wdsh1}"
   return 0
}

#----------------------------------------------------------------
# SectionRow() $1 $2 $3
#
#       where: $1 - the string for the comment
#              $2 - data element to report
#              $3 - (optional) flag for data element color change
#-----------------------------------------------------------------
SectionRow() {
   if [ -z "$1" ]; then echo "ERROR - No comment string provided to SectionRow()"; return 1; fi
   if [ -z "$2" ]; then echo "ERROR - No data string provided to SectionRow()"; return 1; fi

   local sp=$(printf "%-150s")
   local fill=$(( $((${TWIDTH} - 21)) - ${#1}))
   if [ -z "$3" ]; then
      printf "| %-s%s [${BIGRE}%-12s${RSET}]   |\n" "$1" "${sp:0:$fill}" "$(Center "$2" 12)"
   else
      printf "| %-s%s [${BIRED}%-12s${RSET}]   |\n" "$1" "${sp:0:$fill}" "$(Center "$2" 12)"
   fi
   printf "     %-s [%-s]\n" "$1" "$2" >> $LOG
   return 0
}

#---------------------------------------------------------
# SectionPrt() $1 $2
#
#       where: $1 - the string for the comment
#              $2 - (optional) flag for string color change
#----------------------------------------------------------
SectionPrt() {
   if [ -z "$1" ]; then echo "ERROR - No comment string provided to SectionRow()"; return 1; fi

   local sp=$(printf "%-150s")
   local fill=$(( $((${TWIDTH} - 4)) - ${#1}))
   if [ -z "$2" ]; then
      printf "| %-s%s |\n" "$1" "${sp:0:$fill}"
   else
      printf "| ${BIRED}%-s${RSET}%s |\n" "$1" "${sp:0:$fill}"
   fi
   printf "     %-s\n" "$1" >> $LOG
   return 0
}
