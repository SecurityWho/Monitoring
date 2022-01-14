#!/bin/bash
#====================================================================================================#
#       Script Info
#====================================================================================================#
#       File:                   check_PiHole.sh
#       Version:                1.1
#
#       Usage:                  .\check_PiHole.sh -h pihole.example.com -o ads_blocked -s 111jkjj11111lkl11111lk11111kl1l1113
#       Description:            inital public Version
#       Author:                 Daniel Eberhorn <github <at> securitywho.com>
#
#       Requirements:           None
#       Created:                22.12.2021
#       Last Changed:           14.01.2022
#       This check is currently tested with the following PiHole Versions:
#									Pi-hole v5.8.1 / FTL v5.13 / Web Interface v5.10.1
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
        echo -e "This script checks various parameters of the Pi-Server and displays the output in a Nagios friendly format."
        echo -e "This script always returns a OK state, if no errors are found."
        echo -e "#============================================================================================================================================# \n"
        echo -e "Usage: $0 -h <IP> -o <domains_being_blocked|ads_blocked|dns_queries_today|unique_clients|query_responce|gravity|querytype|forward_destinations> [options] \n"
        echo -e "Options (must always be set):"
        echo -e "  -h       	 	specify the IP of the PI-Server"
        echo -e "  -o        		specify the check - see Options declarations for the possible values"
        echo -e "General options:"
        echo -e "  -w        		specify the warning threshold - (currently unused)"
        echo -e "  -c        		specify the critical threshold - (currently unused)"
        echo -e "  -p        		specify the API Key"
		echo -e "  -s        		use saved credentials inside the script - for this to work, please have a look inside the script (must be set with -s yes)"
        echo -e "  --help  		display this help message"
        echo -e "\n \n#============================================================================================================================================#"
        echo -e "Options declaration:"
        echo -e "       domains_being_blocked                   Shows the current amount of Domains that are currently on all used gravity blacklists"
        echo -e "       ads_blocked                             Shows the current number of ADS blocked in the last 24 hours"
        echo -e "       dns_queries_today                       Shows the current number of DNS queries in the last 24 hours"
        echo -e "       unique_clients                          Shows the current number of Clients using the DNS server in the last 24 hours"
        echo -e "       query_responce                          Shows the number of Query Types (A, AAAA, CNAME, etc.) as a statistic for each type"
        echo -e "       gravity                                 Shows if the last Gravity Blacklist sync"
        echo -e "       querytype                               Shows the percentage of Query Types (A, AAAA, CNAME, etc.) as a statistic for all queries"
        echo -e "       forward_destinations                    Shows the how many queries have been answerd from cache, had been blocked or had been forwarded to an 3rd Party DNS"
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
piwarn=10
picrit=5	

# assign the arguments
while getopts h:o:w:c:p:s: flag
do
    case "${flag}" in
        h) checkhost=${OPTARG};;
        o) checkoption=${OPTARG};;
                w) piwarn=${OPTARG};;
                c) picrit=${OPTARG};;
                p) piapikey=${OPTARG};;
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
##      Option "p" -- Password
#piapikey='<REPLACE THIS WITH YOUR OWN VALUE>'
saved='yes'
fi

#
#====================================================================================================#
#       Begin Script
#====================================================================================================#

unset piholesummaryraw
unset piholequeryraw
unset piholeForwardDestinationsraw
piholesummaryraw=$(curl -s https://${checkhost}/admin/api.php?summary)
piholequeryraw=$(curl -s "https://${checkhost}/admin/api.php?getQueryTypes&auth=${piapikey}")
piholeForwardDestinationsraw=$(curl -s "https://${checkhost}/admin/api.php?getForwardDestinations&auth=${piapikey}")


if [[ "${checkoption}" == "domains_being_blocked" ]]; then
domains_being_blocked=$(echo ${piholesummaryraw} | jq | grep '"domains_being_blocked"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
echo "${domains_being_blocked} Domains are currently on the Blacklist | blacklist=${domains_being_blocked};;;;"
exit 0 
fi

if [[ "${checkoption}" == "ads_blocked" ]]; then
ads_blocked_today=$(echo ${piholesummaryraw} | jq | grep '"ads_blocked_today"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
ads_percentage_today=$(echo ${piholesummaryraw} | jq | grep '"ads_percentage_today"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
echo "${ads_blocked_today} Domains have been blocked today - this is ${ads_percentage_today}% of all DNS Querys today | ads_blocked_today=${ads_blocked_today};;;; ads_percentage_today=${ads_percentage_today};;;;"
exit 0 
fi

if [[ "${checkoption}" == "dns_queries_today" ]]; then
dns_queries_today=$(echo ${piholesummaryraw} | jq | grep '"dns_queries_today"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
echo "${dns_queries_today} DNS Requests in the last 24 hours | dns_queries_today=${dns_queries_today};;;;"
exit 0 
fi

if [[ "${checkoption}" == "unique_clients" ]]; then
unique_clients=$(echo ${piholesummaryraw} | jq | grep '"unique_clients"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
echo "${unique_clients} clients are using PiHole as an DNS-Server | unique_clients=${unique_clients};;;;"
exit 0 
fi

if [[ "${checkoption}" == "query_responce" ]]; then
reply_NODATA=$(echo ${piholesummaryraw} | jq | grep '"reply_NODATA"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
reply_NXDOMAIN=$(echo ${piholesummaryraw} | jq | grep '"reply_NXDOMAIN"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
reply_CNAME=$(echo ${piholesummaryraw} | jq | grep '"reply_CNAME"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
reply_IP=$(echo ${piholesummaryraw} | jq | grep '"reply_IP"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
echo "${reply_IP} Query Answers with IP / ${reply_CNAME} Query Answers with CNAME / ${reply_NXDOMAIN} Query Answers with NXDOMAIN / ${reply_NODATA} Query Answers with NODATA  | IP=${reply_IP};;;; CNAME=${reply_CNAME};;;; NXDOMAIN=${reply_NXDOMAIN};;;; NODATA=${reply_NODATA};;;;"
exit 0 
fi

if [[ "${checkoption}" == "gravity" ]]; then
gravity_last_updated_file=$(echo ${piholesummaryraw} | jq | grep -A 2 '"gravity_last_updated"' | grep '"file_exists"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
gravity_last_updated_update=$(echo ${piholesummaryraw} | jq | grep -A 2 '"gravity_last_updated"' | grep '"absolute"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
gravity_last_updated_date=$(date +'%H:%M:%S %d-%m-%Y' -d "@${gravity_last_updated_update}")
echo "Gravity Blacklist Database has been updated at ${gravity_last_updated_date}"
exit 0 
fi

if [[ "${checkoption}" == "querytype" ]]; then
querytype_A=$(echo ${piholequeryraw} | jq | grep '"A (' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_AAAA=$(echo ${piholequeryraw} | jq | grep '"AAAA' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_ANY=$(echo ${piholequeryraw} | jq | grep '"ANY"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_SRV=$(echo ${piholequeryraw} | jq | grep '"SRV"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_SOA=$(echo ${piholequeryraw} | jq | grep '"SOA"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_PTR=$(echo ${piholequeryraw} | jq | grep '"PTR"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_TXT=$(echo ${piholequeryraw} | jq | grep '"TXT"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_NAPTR=$(echo ${piholequeryraw} | jq | grep '"NAPTR"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_MX=$(echo ${piholequeryraw} | jq | grep '"MX"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_DS=$(echo ${piholequeryraw} | jq | grep '"DS"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_RRSIG=$(echo ${piholequeryraw} | jq | grep '"RRSIG"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_DNSKEY=$(echo ${piholequeryraw} | jq | grep '"DNSKEY"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_NS=$(echo ${piholequeryraw} | jq | grep '"NS"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_OTHER=$(echo ${piholequeryraw} | jq | grep '"OTHER"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_SVCB=$(echo ${piholequeryraw} | jq | grep '"SVCB"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
querytype_HTTPS=$(echo ${piholequeryraw} | jq | grep '"HTTPS"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
echo "${querytype_A}% A Queries  / ${querytype_AAAA}% AAAA Queries / ${querytype_PTR}% PTR Queries | A=${querytype_A};;;; AAAA=${querytype_AAAA};;;; PTR=${querytype_PTR};;;; SRV=${querytype_SRV};;;; SOA=${querytype_SOA};;;; ANY=${querytype_ANY};;;; TXT=${querytype_TXT};;;; NAPTR=${querytype_NAPTR};;;; MX=${querytype_MX};;;; DS=${querytype_DS};;;; RRSIG=${querytype_RRSIG};;;; DNSKEY=${querytype_DNSKEY};;;; NS=${querytype_NS};;;; OTHER=${querytype_OTHER};;;; SVCB=${querytype_SVCB};;;; HTTPS=${querytype_HTTPS};;;; "
exit 0 
fi

if [[ "${checkoption}" == "forward_destinations" ]]; then
pihole_blocklist=$(echo ${piholeForwardDestinationsraw} | jq | grep '"blocklist|blocklist"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
pihole_cache=$(echo ${piholeForwardDestinationsraw} | jq | grep '"cache|cache"' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g')
pihole_DNS_Forward=$(echo ${piholeForwardDestinationsraw} | jq | grep -v '"cache|cache"' | grep -v '"blocklist|blocklist"' | grep -v '{' | grep -v '}' | awk -F  ':' '{ print $2 }' | sed 's/\,//g' | sed 's/ //g' | awk '{s+=$1} END {print s}')
echo "${pihole_cache}% Queries answerd from cache / ${pihole_blocklist}% Queries blocked by an blacklist / ${pihole_DNS_Forward}% Queries forwarded to externel DNS Relays | pihole_cache=${pihole_cache};;;; pihole_blocklist=${pihole_blocklist};;;; pihole_DNS_Forward=${pihole_DNS_Forward};;;;"
exit 0 
fi


