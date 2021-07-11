#!/bin/bash
#====================================================================================================#
#       Script Info
#====================================================================================================#
#       File:                   check_down_ports.sh
#       Version:                1.3.4
#
#       Usage:                  ./check_down_ports.sh -h <IP> -v <v2c | v3> [options]
#       Description:            extended the extended option and added delta correction option
#       Author:                 Daniel Eberhorn <github <at> securitywho.com>
#
#       Requirements:           snmpwalk
#       Created:                25.06.2021
#       Last Changed:           11.07.2021
#       Comments:               This check is written to be compatible with the if64 mib that most
#                               vendors use.
#       This check is currently tested with:
#                               HPE ProCurve
#                               Extreme ExtremeXOS
#       Credits:

#====================================================================================================#
#       License
#====================================================================================================#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#====================================================================================================#
#       Help and Argument handling
#====================================================================================================#
display_usage() {
        echo -e "\n \n#=================================================================================================================#"
        echo -e "This script evaluates the number of ports in a down state and displays the count in a Nagios friendly format."
        echo -e "This script always returns a OK state, if no errors are found."
        echo -e "#=================================================================================================================# \n"
        echo -e "Usage: $0 -h <IP> -v <v2c|v3> [options] \n"
        echo -e "Options (must always be set):"
        echo -e "  -h       	 	specify the IP of the switch"
        echo -e "  -v       	 	specify the SNMP Version (v2c or v3) \n"
        echo -e "SNMPv2 specific:"
        echo -e "  -c        		specify the SNMPv2 community \n"
        echo -e "SNMPv3 specific:"
        echo -e "  -l        		specify the SNMPv3 security level (noAuthNoPriv|authNoPriv|authPriv)"
        echo -e "  -a        		specify the SNMPv3 authentication protocol (MD5|SHA)"
        echo -e "  -A        		specify the SNMPv3 authentication protocol pass phrase"
        echo -e "  -x        		specify the SNMPv3 privacy protocol (DES|AES)"
        echo -e "  -X        		specify the SNMPv3 privacy protocol pass phrase"
        echo -e "  -u        		specify the SNMPv3 security name \n"
        echo -e "General options:"
        echo -e "  -d <option>		enable debug output (must be set with -d yes or -d full)"
	echo -e "  -k			delta correction of the values - the DOWN count is always reduced by the set amount. This does not take effect to ADMIN DOWN ports!"
        echo -e "  -s        		use saved credentials inside the script for the SNMP specific options - for this to work, please have a look inside the script (must be set with -s yes)"
        echo -e "  -e <option>		extended check"
	echo -e "   -e speed 		if ifspeed is zero, ignore the port"
	echo -e "   -e type 		if iftype is not ethernet, ignore the port"
        echo -e "  --help  		display this help message \n"
}
# check if help is requested
        if [[ ( $# == "--help") ]]
        then
                display_usage
                exit 3
        fi

        if [  $# -le 5 ]
        then
                display_usage
                exit 3
        fi
# assign the arguments
while getopts h:v:c:l:a:A:x:X:u:d:s:e:k: flag
do
    case "${flag}" in
        h) checkhost=${OPTARG};;
        v) snmpversion=${OPTARG};;
                c) snmpv2community=${OPTARG};;
                u) v3user=${OPTARG};;
                A) v3Apass=${OPTARG};;
                X) v3Xpass=${OPTARG};;
                a) authproto=${OPTARG};;
                x) privproto=${OPTARG};;
                l) v3mode=${OPTARG};;
                d) debug=${OPTARG};;
                s) saved=${OPTARG};;
                e) extended=${OPTARG};;
		k) delta=${OPTARG};;
                *) echo "usage: $0 --help" >&2
                exit 3 ;;
    esac
done

if [[ ${debug} == "yes" ]]
then
        echo "#==============================================#"
        echo "Argument handling - only CLI arguments!"
        echo "#==============================================#"
        echo "checkhost: $checkhost";
        echo "snmpv2community: $snmpv2community";
        echo "snmpversion: $snmpversion";
        echo "v3user: $v3user";
        echo "v3apass: $v3Apass";
        echo "v3xpass: $v3Xpass";
        echo "authproto: $authproto";
        echo "privproto: $privproto";
        echo "v3mode: $v3mode";
        echo "debug: $debug";
        echo "saved: $saved";
        echo "extended: $extended";
	echo "delta correction: $delta";
fi
if [[ ${debug} == "full" ]]
then
        set -x
fi
#====================================================================================================#
#       saved credentials
#=======================================================================#
#       Uncomment the lines you want to manually define inside the script.
#       this is only valid, if the script is called with "-s yes".
#====================================================================================================#
if [[ ${saved} == "yes" ]]
then
##      Option "c" -- SNMP v2 Commnuity
#snmpv2community='<REPLACE THIS WITH YOUR OWN VALUE>'

##      Option "l" -- SNMPv3 security level (noAuthNoPriv|authNoPriv|authPriv)
#v3mode='<REPLACE THIS WITH YOUR OWN VALUE>'

##      Option "u" -- SNMPv3 security name
#v3user='<REPLACE THIS WITH YOUR OWN VALUE>'

##      Option "A" -- SNMPv3 authentication protocol pass phrase
#v3Apass='<REPLACE THIS WITH YOUR OWN VALUE>'

##      Option "X" -- SNMPv3 privacy protocol pass phrase
#v3Xpass='<REPLACE THIS WITH YOUR OWN VALUE>'

##      Option "a" -- SNMPv3 authentication protocol (MD5|SHA)
#authproto='<REPLACE THIS WITH YOUR OWN VALUE>'

##      Option "x" -- SNMPv3 privacy protocol (DES|AES)
#privproto='<REPLACE THIS WITH YOUR OWN VALUE>'
saved='yes'
	if [[ ${debug} == "yes" ]]
	then
			echo "#==============================================#"
			echo "Argument handling - saved values and CLI arguments!"
			echo "#==============================================#"
			echo "checkhost: $checkhost";
			echo "snmpv2community: $snmpv2community";
			echo "snmpversion: $snmpversion";
			echo "v3user: $v3user";
			echo "v3apass: $v3Apass";
			echo "v3xpass: $v3Xpass";
			echo "authproto: $authproto";
			echo "privproto: $privproto";
			echo "v3mode: $v3mode";
			echo "debug: $debug";
			echo "saved: $saved";
			echo "extended: $extended";
			echo "delta correction: $delta";
	fi
fi

#====================================================================================================#
#       Begin Script
#====================================================================================================#
ifoperoid='.1.3.6.1.2.1.2.2.1.8'
ifadminoid='.1.3.6.1.2.1.2.2.1.7'
iftype='.1.3.6.1.2.1.2.2.1.3'
ifspeed='.1.3.6.1.2.1.2.2.1.5'

if [[ ${snmpversion} == "v2c" ]]
then
	if [[ ${extended} == "speed" ]]
	then
		opercount=0
		admincount=0
		iftype_array=( $(snmpwalk -M / -L n -v2c -c "${snmpv2community}" "${checkhost}" ${iftype} | grep 'INTEGER: 6' | awk '{print $1}' | awk -F "." '{print $NF}'))
		ifspeed_array=( $(snmpwalk -M / -L n -v2c -c "${snmpv2community}" "${checkhost}" ${ifspeed} | grep -v 'Gauge32: 0' | awk '{print $1}' | awk -F "." '{print $NF}'))
		if_array=()
		for e in "${iftype_array[@]}";
		do
			for j in "${ifspeed_array[@]}";
			do
				if [ "$e" -eq "$j" ]
				then
					if_array+=("$e")
				fi
			done
		done

		if [[ ${debug} == "yes" ]]
		then
			echo "Extended: ${extended}"
			echo "IF-Array"
			echo "${if_array[@]}"
			echo "iftype_array"
			echo "${iftype_array[@]}"
			echo "ifspeed_array"
			echo "${ifspeed_array[@]}"
		fi

		for i in "${!if_array[@]}";
		do
			unset opercount_arraycount
			unset admincount_arraycount
			opercount_arraycount=$(snmpwalk -M / -L n -v2c -c "${snmpv2community}" "${checkhost}" ${ifoperoid}."${if_array[$i]}" | grep -c 'INTEGER: 2')
			if [[ ${opercount_arraycount} -eq 1 ]]
			then
				opercount=$((opercount+1))
			fi
			admincount_arraycount=$(snmpwalk -M / -L n -v2c -c "${snmpv2community}" "${checkhost}" ${ifadminoid}."${if_array[$i]}" | grep -c 'INTEGER: 2')
			if [[ ${admincount_arraycount} -eq 1 ]]
			then
				admincount=$((admincount+1))
			fi
		done
	fi

	if [[ ${extended} == "type" ]]
	then
		opercount=0
		admincount=0
		if_array=( $(snmpwalk -M / -L n -v2c -c "${snmpv2community}" "${checkhost}" ${iftype} | grep 'INTEGER: 6' | awk '{print $1}' | awk -F "." '{print $NF}'))

		if [[ ${debug} == "yes" ]]
		then
			echo "Extended: ${extended}"
			echo "IF-Array"
			echo "${if_array[@]}"
		fi

		for i in "${!if_array[@]}";
		do
			unset opercount_arraycount
			unset admincount_arraycount
			opercount_arraycount=$(snmpwalk -M / -L n -v2c -c "${snmpv2community}" "${checkhost}" ${ifoperoid}."${if_array[$i]}" | grep -c 'INTEGER: 2')
			if [[ ${opercount_arraycount} -eq 1 ]]
			then
				opercount=$((opercount+1))
			fi
			admincount_arraycount=$(snmpwalk -M / -L n -v2c -c "${snmpv2community}" "${checkhost}" ${ifadminoid}."${if_array[$i]}" | grep -c 'INTEGER: 2')
			if [[ ${admincount_arraycount} -eq 1 ]]
			then
				admincount=$((admincount+1))
			fi
		done
	fi

	if [[ ${extended} == '' ]]
	then
			opercount=$(snmpwalk -v2c -c "${snmpv2community}" "${checkhost}" ${ifoperoid} | grep -c 'INTEGER: 2')
			admincount=$(snmpwalk -v2c -c "${snmpv2community}" "${checkhost}" ${ifadminoid} | grep -c 'INTEGER: 2')
	fi

opercountcheck=$(echo "${opercount}" | grep -E ^\-?[0-9]+$)
admincountcheck=$(echo "${admincount}" | grep -E ^\-?[0-9]+$)
if [[ ${opercountcheck} == '' ]] || [[ ${admincountcheck} == '' ]]
then
	echo "Returned values are not valid. Please check the device and debug the script. (opercount=${opercount} // admindownports=${admincount})"
	exit 3
fi

if [[ ${delta} != '' ]]
then
	deltacheck=$(echo "${delta}" | grep -E ^\-?[0-9]+$)
	if [[ ${deltacheck} == '' ]]
	then
		echo "Delta correction value is not an valid! (delta=${delta})"
		exit 3
	fi
	opercount=$(echo "$((opercount-delta))")
	if [[ ${opercount} -lt 0 ]]
	then
		echo "Delta correction value is not valid! The calculation result is negative!  (delta=${delta} // opercount=${opercount})"
		exit 2	
	fi
fi

echo "${opercount} switchports are in a DOWN state - of them ${admincount} are in an ADMIN DOWN state | downports=${opercount};;;; admindownports=${admincount};;;;"
exit 0
fi

if [[ ${snmpversion} == "v3" ]]
then
	if [[ ${extended} == "speed" ]]
	then
		opercount=0
		admincount=0
		
		if [[ ${v3mode} == "authPriv" ]]
		then
			snmpwalkv3c="snmpwalk -M / -L n -v3 -l authPriv -u ${v3user} -a ${authproto} -A ${v3Apass} -x ${privproto} -X ${v3Xpass} ${checkhost}"
		elif [[ ${v3mode} == "authNoPriv" ]]
		then
			snmpwalkv3c="snmpwalk -M / -v3 -L n -l authNoPriv -u ${v3user} -a ${authproto} -A ${v3Apass} ${checkhost}"
		elif [[ ${v3mode} == "noAuthNoPriv" ]]
		then
			snmpwalkv3c="snmpwalk -M / -v3 -L n -l noAuthNoPriv -u ${v3user} ${checkhost}"
		fi
		
		
		iftype_array=( $( ${snmpwalkv3c} ${iftype} | grep 'INTEGER: 6' | awk '{print $1}' | awk -F "." '{print $NF}'))
		ifspeed_array=( $( ${snmpwalkv3c} ${ifspeed} | grep -v 'Gauge32: 0' | awk '{print $1}' | awk -F "." '{print $NF}'))

		if_array=()
		for e in "${iftype_array[@]}";
		do
			for j in "${ifspeed_array[@]}";
			do
				if [ "$e" -eq "$j" ]
				then
					if_array+=("$e")
				fi
			done
		done

		if [[ ${debug} == "yes" ]]
		then
			echo "Extended: ${extended}"
			echo "IF-Array"
			echo "${if_array[@]}"
			echo "iftype_array"
			echo "${iftype_array[@]}"
			echo "ifspeed_array"
			echo "${ifspeed_array[@]}"
		fi

		for i in "${!if_array[@]}";
		do
			unset opercount_arraycount
			unset admincount_arraycount
			opercount_arraycount=$( ${snmpwalkv3c} ${ifoperoid}."${if_array[$i]}" | grep -c 'INTEGER: 2')
			if [[ ${opercount_arraycount} -eq 1 ]]
			then
				opercount=$((opercount+1))
			fi
			admincount_arraycount=$( ${snmpwalkv3c} ${ifadminoid}."${if_array[$i]}" | grep -c 'INTEGER: 2')
			if [[ ${admincount_arraycount} -eq 1 ]]
			then
				admincount=$((admincount+1))
			fi
		done
	fi
		
	if [[ ${extended} == "type" ]]
	then
		opercount=0
		admincount=0
			
		if [[ ${v3mode} == "authPriv" ]]
		then
			snmpwalkv3c="snmpwalk -M / -L n -v3 -l authPriv -u ${v3user} -a ${authproto} -A ${v3Apass} -x ${privproto} -X ${v3Xpass} ${checkhost}"
		elif [[ ${v3mode} == "authNoPriv" ]]
		then
			snmpwalkv3c="snmpwalk -M / -v3 -L n -l authNoPriv -u ${v3user} -a ${authproto} -A ${v3Apass} ${checkhost}"
		elif [[ ${v3mode} == "noAuthNoPriv" ]]
		then
			snmpwalkv3c="snmpwalk -M / -v3 -L n -l noAuthNoPriv -u ${v3user} ${checkhost}"
		fi

		if_array=( $( ${snmpwalkv3c} ${iftype} | grep 'INTEGER: 6' | awk '{print $1}' | awk -F "." '{print $NF}'))

		if [[ ${debug} == "yes" ]]
		then
			echo "Extended: ${extended}"
			echo "IF-Array"
			echo "${if_array[@]}"
		fi

		for i in "${!if_array[@]}";
		do
			unset opercount_arraycount
			unset admincount_arraycount
			opercount_arraycount=$( ${snmpwalkv3c} ${ifoperoid}."${if_array[$i]}" | grep -c 'INTEGER: 2')
			if [[ ${opercount_arraycount} -eq 1 ]]
			then
				opercount=$((opercount+1))
			fi
			admincount_arraycount=$( ${snmpwalkv3c} ${ifadminoid}."${if_array[$i]}" | grep -c 'INTEGER: 2')
			if [[ ${admincount_arraycount} -eq 1 ]]
			then
				admincount=$((admincount+1))
			fi
		done
	fi		
	
if [[ ${extended} == '' ]]
then
        if [[ ${v3mode} == "authPriv" ]]
        then
                opercount=$(snmpwalk -M / -L n -v3 -l authPriv -u "${v3user}" -a "${authproto}" -A "${v3Apass}" -x "${privproto}" -X "${v3Xpass}" "${checkhost}" ${ifoperoid} | grep -c 'INTEGER: 2')
                admincount=$(snmpwalk -M / -L n -v3 -l authPriv -u "${v3user}" -a "${authproto}" -A "${v3Apass}" -x "${privproto}" -X "${v3Xpass}" "${checkhost}" ${ifadminoid} | grep -c 'INTEGER: 2')
        elif [[ ${v3mode} == "authNoPriv" ]]
        then
                opercount=$(snmpwalk -M / -v3 -L n -l authNoPriv -u "${v3user}" -a "${authproto}" -A "${v3Apass}" "${checkhost}" ${ifoperoid} | grep -c 'INTEGER: 2')
                admincount=$(snmpwalk -M / -v3 -L n -l authNoPriv -u "${v3user}" -a "${authproto}" -A "${v3Apass}" "${checkhost}" ${ifadminoid} | grep -c 'INTEGER: 2')
        elif [[ ${v3mode} == "noAuthNoPriv" ]]
        then
                opercount=$(snmpwalk -M / -v3 -L n -l noAuthNoPriv -u "${v3user}" "${checkhost}" ${ifoperoid} | grep -c 'INTEGER: 2')
                admincount=$(snmpwalk -M / -v3 -L n -l noAuthNoPriv -u "${v3user}" "${checkhost}" ${ifadminoid} | grep -c 'INTEGER: 2')
        fi
fi

opercountcheck=$(echo "${opercount}" | grep -E ^\-?[0-9]+$)
admincountcheck=$(echo "${admincount}" | grep -E ^\-?[0-9]+$)

if [[ ${opercountcheck} == '' ]] || [[ ${admincountcheck} == '' ]]
then
    echo "Returned values are not valid. Please check the device and debug the script. (opercount=${opercount} // admindownports=${admincount})"
    exit 3
fi

if [[ ${delta} != '' ]]
then
	deltacheck=$(echo "${delta}" | grep -E ^\-?[0-9]+$)
	if [[ ${deltacheck} == '' ]]
	then
		echo "Delta correction value is not an valid! (delta=${delta})"
		exit 3
	fi
	opercount=$(echo "$((opercount-delta))")
	if [[ ${opercount} -lt 0 ]]
	then
		echo "Delta correction value is not valid! The calculation result is negative!  (delta=${delta} // opercount=${opercount})"
		exit 2	
	fi
fi
	
echo "${opercount} switchports are in a DOWN state - of them ${admincount} are in an ADMIN DOWN state | downports=${opercount};;;; admindownports=${admincount};;;;"
exit 0
fi

display_usage
exit 3
