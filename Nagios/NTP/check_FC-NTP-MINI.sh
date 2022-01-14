#!/bin/bash
#====================================================================================================#
#       Script Info
#====================================================================================================#
#       File:                   check_FC-NTP-MINI.sh
#       Version:                1.0
#
#       Usage:                  .\check_FC-NTP-MINI.sh -h ntp.example.com -o gps -w 10 -c 5 -u admin -p admin
#       Description:            inital public Version
#       Author:                 Daniel Eberhorn <github <at> securitywho.com>
#
#       Requirements:           Package "html2txt" for the subcheck "ntpstatus" is required.
#       Created:                11.01.2022
#       Last Changed:           11.01.2022
#       Credits:                -
#
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
#
#====================================================================================================#
#       Help and Argument handling
#====================================================================================================#
display_usage() {
        echo -e "\n \n#============================================================================================================================================#"
        echo -e "This script checks various parameters for the NTP-Server (FC-NTP-MINI) and displays the output in a Nagios friendly format."
        echo -e "This script always returns a OK state, if no errors are found."
        echo -e "#============================================================================================================================================# \n"
        echo -e "Usage: $0 -h <IP> -o <antenna|satellite|gps|beidou|glonass|ntpstatus|time> [options] \n"
        echo -e "Options (must always be set):"
        echo -e "  -h       	 	specify the IP of the NTP-Server"
        echo -e "  -o        		specify the check (antenna|satellite|gps|beidou|glonass|ntpstatus|time)"
        echo -e "General options:"
        echo -e "  -w        		specify the warning threshold - mandatory for the options (satellite|gps|beidou|glonass) // Default value: 10"
        echo -e "  -c        		specify the critical threshold - mandatory for the options (satellite|gps|beidou|glonass) // Default value: 5"
        echo -e "  -u        		specify the username"
        echo -e "  -p        		specify the password"
		echo -e "  -s        		use saved credentials inside the script - for this to work, please have a look inside the script (must be set with -s yes)"
        echo -e "  --help  		display this help message"
        echo -e "\n \n#============================================================================================================================================#"		
        echo -e "Options declaration:"		
        echo -e "	antenna			Shows the current status of the Antenna (OK / not OK) - normally means if the antenna is connected or not"		
        echo -e "	satellite		Shows the current number of all satellites (GPS, BeiDou, GLONASS) used for time sync"		
        echo -e "	gps			Shows the used and seen number of GPS satellites"
        echo -e "	beidou			Shows the used and seen number of BeiDou satellites"		
        echo -e "	glonass			Shows the used and seen number of GLONASS satellites"		
        echo -e "	ntpstatus		Shows if the NTP Server is Active and the Stratum"
        echo -e "	time			Shows the current time and date reported by the NTP-Server in UTC"
        echo -e "#============================================================================================================================================# \n"		
}
# check if help is requested
        if [[ ( $# == "--help") ]]
        then
                display_usage
                exit 3
        fi

        if [  $# -le 4 ]
        then
                display_usage
                exit 3
        fi

# assain default values
ntpwarn=10
ntpcrit=5	

# assign the arguments
while getopts h:o:w:c:u:p:s: flag
do
    case "${flag}" in
        h) checkhost=${OPTARG};;
        o) checkoption=${OPTARG};;
                w) ntpwarn=${OPTARG};;
                c) ntpcrit=${OPTARG};;
                u) ntpuser=${OPTARG};;
                p) ntppass=${OPTARG};;
                s) saved=${OPTARG};;
                *) echo "usage: $0 --help" >&2
                exit 3 ;;
    esac
done

#====================================================================================================#
#       saved credentials
#=======================================================================#
#       Uncomment the lines you want to manually define inside the script.
#       this is only valid, if the script is called with "-s yes".
#====================================================================================================#
if [[ ${saved} == "yes" ]]; then
##      Option "u" -- Username
#ntpuser='<REPLACE THIS WITH YOUR OWN VALUE>'

##      Option "p" -- Password
#ntppass='<REPLACE THIS WITH YOUR OWN VALUE>'
saved='yes'
fi

#====================================================================================================#
#       Begin Script
#====================================================================================================#

if [[ "${checkoption}" == "antenna" ]]; then
gnssxmlant=$(curl -s -u ${ntpuser}:${ntppass} http://${checkhost}/xml/gnss.xml | grep '<ant>' | awk -F  '>' '{ print $2 }' | awk -F  '<' '{ print $1 }')
if [[ "${gnssxmlant}" == "OK" ]]; then
echo "Antenna Status is: ${gnssxmlant}"
exit 0
else
echo "Antenna Status is: ${gnssxmlant}"
exit 2
fi
fi

if [[ "${checkoption}" == "satellite" ]]; then
gnssxmlsv=$(curl -s -u ${ntpuser}:${ntppass} http://${checkhost}/xml/gnss.xml | grep '<svused>' | awk -F  '>' '{ print $2 }' | awk -F  '<' '{ print $1 }')
if [[ ${gnssxmlsv} -gt ${ntpwarn} ]]; then
echo "Total satellites used: ${gnssxmlsv} | satellites=${gnssxmlsv};;;;"
exit 0
elif  [[ ${gnssxmlsv} -ge ${ntpcrit} ]] && [[ ${gnssxmlsv} -lt ${ntpwarn} ]]; then
echo "Total satellites used: ${gnssxmlsv}  (warn!: ${ntpwarn} / crit: ${ntpcrit}) | satellites=${gnssxmlsv};;;;"
exit 1
else
echo "Total satellites used: ${gnssxmlsv} (warn: ${ntpwarn} / crit!: ${ntpcrit}) | satellites=${gnssxmlsv};;;;"
exit 2
fi
fi

if [[ "${checkoption}" == "gps" ]]; then
gnssxmlgpsused=$(curl -s -u ${ntpuser}:${ntppass} http://${checkhost}/xml/gnss.xml | grep '<gpsinfo>' | awk -F  '>' '{ print $2 }' | awk -F  '<' '{ print $1 }' | awk -F  '/' '{ print $1 }')
gnssxmlgpsseen=$(curl -s -u ${ntpuser}:${ntppass} http://${checkhost}/xml/gnss.xml | grep '<gpsinfo>' | awk -F  '>' '{ print $2 }' | awk -F  '<' '{ print $1 }' | awk -F  '/' '{ print $2 }')
if [[ ${gnssxmlgpsused} -gt ${ntpwarn} ]]; then
echo "Total GPS satellites used: ${gnssxmlgpsused} / seen: ${gnssxmlgpsseen} | GPSused=${gnssxmlgpsused};;;; GPSseen=${gnssxmlgpsseen};;;;"
exit 0
elif  [[ ${gnssxmlgpsused} -ge ${ntpcrit} ]] && [[ ${gnssxmlgpsused} -le ${ntpwarn} ]]; then
echo "Total GPS satellites used: ${gnssxmlgpsused} / seen: ${gnssxmlgpsseen} (warn!: ${ntpwarn} / crit: ${ntpcrit}) | GPSused=${gnssxmlgpsused};;;; GPSseen=${gnssxmlgpsseen};;;;"
exit 1
else
echo "Total GPS satellites used: ${gnssxmlgpsused} / seen: ${gnssxmlgpsseen} (warn: ${ntpwarn} / crit!: ${ntpcrit}) | GPSused=${gnssxmlgpsused};;;; GPSseen=${gnssxmlgpsseen};;;;"
exit 2
fi
fi

if [[ "${checkoption}" == "beidou" ]]; then
gnssxmlbeidouused=$(curl -s -u ${ntpuser}:${ntppass} http://${checkhost}/xml/gnss.xml | grep '<bdinfo>' | awk -F  '>' '{ print $2 }' | awk -F  '<' '{ print $1 }' | awk -F  '/' '{ print $1 }')
gnssxmlbeidouseen=$(curl -s -u ${ntpuser}:${ntppass} http://${checkhost}/xml/gnss.xml | grep '<bdinfo>' | awk -F  '>' '{ print $2 }' | awk -F  '<' '{ print $1 }' | awk -F  '/' '{ print $2 }')
if [[ ${gnssxmlbeidouused} -gt ${ntpwarn} ]]; then
echo "Total BeiDou satellites used: ${gnssxmlbeidouused} / seen: ${gnssxmlbeidouseen} | BeiDouused=${gnssxmlbeidouused};;;; BeiDouseen=${gnssxmlbeidouseen};;;;"
exit 0
elif  [[ ${gnssxmlbeidouused} -ge ${ntpcrit} ]] && [[ ${gnssxmlbeidouused} -le ${ntpwarn} ]]; then
echo "Total BeiDou satellites used: ${gnssxmlbeidouused} / seen: ${gnssxmlbeidouseen} (warn!: ${ntpwarn} / crit: ${ntpcrit}) | BeiDouused=${gnssxmlbeidouused};;;; BeiDouseen=${gnssxmlbeidouseen};;;;"
exit 1
else
echo "Total BeiDou satellites used: ${gnssxmlbeidouused} / seen: ${gnssxmlbeidouseen} (warn: ${ntpwarn} / crit!: ${ntpcrit}) | BeiDouused=${gnssxmlbeidouused};;;; BeiDouseen=${gnssxmlbeidouseen};;;;"
exit 2
fi
fi

if [[ "${checkoption}" == "glonass" ]]; then
gnssxmlglonassused=$(curl -s -u ${ntpuser}:${ntppass} http://${checkhost}/xml/gnss.xml | grep '<glinfo>' | awk -F  '>' '{ print $2 }' | awk -F  '<' '{ print $1 }' | awk -F  '/' '{ print $1 }')
gnssxmlglonassseen=$(curl -s -u ${ntpuser}:${ntppass} http://${checkhost}/xml/gnss.xml | grep '<glinfo>' | awk -F  '>' '{ print $2 }' | awk -F  '<' '{ print $1 }' | awk -F  '/' '{ print $2 }')
if [[ ${gnssxmlglonassused} -gt ${ntpwarn} ]]; then
echo "Total GLONASS satellites used: ${gnssxmlglonassused} / seen: ${gnssxmlglonassseen} | GLONASSused=${gnssxmlglonassused};;;; GLONASSseen=${gnssxmlglonassseen};;;;"
exit 0
elif  [[ ${gnssxmlglonassused} -ge ${ntpcrit} ]] && [[ ${gnssxmlglonassused} -le ${ntpwarn} ]]; then
echo "Total GLONASS satellites used: ${gnssxmlglonassused} / seen: ${gnssxmlglonassseen} (warn!: ${ntpwarn} / crit: ${ntpcrit}) | GLONASSused=${gnssxmlglonassused};;;; GLONASSseen=${gnssxmlglonassseen};;;;"
exit 1
else
echo "Total GLONASS satellites used: ${gnssxmlglonassused} / seen: ${gnssxmlglonassseen} (warn: ${ntpwarn} / crit!: ${ntpcrit}) | GLONASSused=${gnssxmlglonassused};;;; GLONASSseen=${gnssxmlglonassseen};;;;"
exit 2
fi
fi

if [[ "${checkoption}" == "ntpstatus" ]]; then
ntpstate=$(curl -s -u ${ntpuser}:${ntppass} http://${checkhost}/ntpstate.shtml | html2text | head -n 1 | sed 's/ //g')
ntpstatestratum=$(curl -s -u ${ntpuser}:${ntppass} http://${checkhost}/ntpstate.shtml | html2text | head -n 3 | tail -n 1 | sed 's/ //g')
if [[ "${ntpstate}" == "Active" ]]; then
echo "NTP Server Status: ${ntpstate} / Stratum: ${ntpstatestratum} | stratum=${ntpstatestratum};;;;"
exit 0
else
echo "NTP Server Status: ${ntpstate} / Stratum: ${ntpstatestratum} | stratum=${ntpstatestratum};;;;"
exit 2
fi
fi

if [[ "${checkoption}" == "time" ]]; then
timexml=$(curl -s -u ${ntpuser}:${ntppass} http://${checkhost}/xml/time.xml | grep '<ctime>' | awk -F  '>' '{ print $2 }' | awk -F  '<' '{ print $1 }')
timexmldate=$(echo ${timexml} | awk -F  ' ' '{ print $1 }')
timexmltime=$(echo ${timexml} | awk -F  ' ' '{ print $2 }')
echo "Current Time: ${timexmltime} (UTC) ${timexmldate}"
exit 0
fi