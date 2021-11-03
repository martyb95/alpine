#!/bin/ash

#======================================
#  String Functions Definitions
#======================================

#-------------------------------------------------------------------
# Upper() $1
#
#     where: $1 - string to be converted to upper case
#-------------------------------------------------------------------
Upper() {
   if [ -z "$1" ]; then echo "ERROR - No string passed to Upper()";  return 1; fi
   printf "%s" $(echo "$1" | tr '[:lower:]' '[:upper:]')
}

#-------------------------------------------------------------------
#  Lower() $1
#
#     where: $1 - string to be converted to lower case
#-------------------------------------------------------------------
Lower() {
   if [ -z "$1" ]; then echo "ERROR - No string passed to Lower()"; return 1; fi
   printf "%s" $(echo "$1" | tr '[:upper:]' '[:lower:]')
}

#------------------------------------------------
# Trim() $1
#
#     where: $1 - string to be trimmed
#------------------------------------------------
Trim () {
   if [ -z "$1" ]; then echo "ERROR - No string passed to Trim()";  return 1; fi
   printf "%s" $(echo "$1" | xargs)
}

#--------------------------------------------
# Center() $1 $2
#
#     where: $1 - string to be centered
#            $2 - number of charachters to
#                 output  in total
#---------------------------------------------
Center() {
    if [ -z "$1" ]; then echo "ERROR - No string to center provided to Center()"; return 1; fi
    if [ -z "$2" ]; then echo "ERROR - No total number of characters provided to Center()"; return 1; fi

    # Set input parameters
    local text=$(Trim "$1")         # trimmed text to center

    if [ ${#text} -gt $2 ]; then
       retvar="$text"
       return 1
    fi

    printf '%*s%s' "$(( $(($2 / 2)) + $((${#text} / 2)) ))" "$text"
    return 0
}

#-------------------------------------------------------
# LFilll() $1 $2
#
#     where: $1 - string for the to be left padded
#            $2 - number of character to make the string
#--------------------------------------------------------
LFill() {
    if [ -z "$1" ]; then echo "ERROR - Must provide an input string for RFill()"; fi
    if [ -z "$2" ]; then echo "ERROR - Must provide total characters for RFill()"; fi

    # Set input parameters
    local text="$1"
    if [ ${#text} -gt $2 ]; then
       retvar="$text"
       return 1
    fi
    printf '%*s%s' "$(($2))" "$text"
    return 0
}

#-------------------------------------------------------
# RFilll() $1 $2
#
#     where: $1 - string for the to be right padded
#            $2 - number of character to make the string
#--------------------------------------------------------
RFill() {
    if [ -z "$1" ]; then echo "ERROR - Must provide an input string for RFill()"; fi
    if [ -z "$2" ]; then echo "ERROR - Must provide total characters for RFill()"; fi

    # Set input parameters
    local text="$1"
    if [ ${#text} -gt $2 ]; then
       retvar="$text"
       return 1
    fi
    printf '%s%*s' "$text" $(($2 - ${#1}))
    return 0
}
