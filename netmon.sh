#!/bin/bash
#
# quickie network monitoring script for the pi
#
# vinceskahan@gmail.com
#
# credits: this is based on a posting somebody made to
#  one of the raspi related howtos or the like back in
#  approximately 2012, but I've long since lost the 
#  original posting so I can't credit the smart person
#  who cooked up the original idea.  Sorry.
#
#  I've cleaned up the attached quite a bit so any bugs
#  would be mine regardless.
#
#------ call this out of crontab periodically ----
#
# warning - default cron will log 'each' run so you
# can definitely burn out your SD card if you don't
# tune your pi to not log cron jobs !!!
#
# this example, every two minutes
# */2 * * * * /home/pi/netmon.sh
#

# this is to a tmpfs partition always there on raspbian
FLAGFILE=/run/netmon.flag

# likely ok for most systems, but you could of course
# monitor your wired nic by editing the device name here
NIC="wlan0"

#------ probably stop editing here ----

PATH=/sbin:/usr/sbin:$PATH

NOW=`date +%c`

# -- this is the monitoring magic - try to restart the nic
if [ -f "${FLAGFILE}" ]
then
	# is the nic there in the ifconfig output ?
	if ip link show "${NIC}" | grep -q ",UP," ;
	then
        	echo "wifi ok at ${NOW}" > ${FLAGFILE}
	else
		# nope - try to fix it
            logger "${0}: ${NIC} down - attempting fix"
        	ifup --force "${NIC}"
        	OUT=$? #save exit status of last command to decide what to do next
        	if [ $OUT -eq 0 ] ; then
                    STATE=$(ip link show "${NIC}" | grep ",UP,")
                	logger "${0}: ${NIC} reset ok -  Current state is ${STATE}"
        	else
               	 	logger "${0}: ${NIC} reset failed - status ${OUT}"
        	fi
	fi
else
	# -- first time we see the nic up, touch a flag file
	#    so subsequent runs know we should attempt to self-heal
	#    if it goes away for any reason
	if ip link show "${NIC}" | grep -q ",UP," ;
	then
		logger "${0}: touching ${FLAGFILE}"
        	echo "wifi ok at ${NOW}" > ${FLAGFILE}
	fi
fi

