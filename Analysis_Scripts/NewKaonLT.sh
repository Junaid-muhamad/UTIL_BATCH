#!/bin/bash

### Stephen Kay, University of Regina
### 15/01/21
### stephen.kay@uregina.ca

echo "Starting Replay script"
echo "I take as arguments the Run Number and max number of events!"
RUNNUMBER=$1
MAXEVENTS=-1
### Check you've provided the an argument
if [[ $1 -eq "" ]]; then
    echo "I need a Run Number!"
    echo "Please provide a run number as input"
    exit 2
fi
if [[ ${USER} = "cdaq" ]]; then
    echo "Warning, running as cdaq."
    echo "Please be sure you want to do this."
    echo "Comment this section out and run again if you're sure."
    exit 2
fi          

# Set path depending upon hostname. Change or add more as needed  
if [[ "${HOSTNAME}" = *"farm"* ]]; then  
    REPLAYPATH="/group/c-kaonlt/USERS/${USER}/hallc_replay_lt"
    if [[ "${HOSTNAME}" != *"ifarm"* ]]; then
	source /site/12gev_phys/softenv.sh 2.3
    fi
    cd "$REPLAYPATH"
    source "$REPLAYPATH/setup.sh"
elif [[ "${HOSTNAME}" = *"qcd"* ]]; then
    REPLAYPATH="/group/c-kaonlt/USERS/${USER}/hallc_replay_lt"
    source /site/12gev_phys/softenv.sh 2.3
    cd "$REPLAYPATH"
    source "$REPLAYPATH/setup.sh" 
elif [[ "${HOSTNAME}" = *"cdaq"* ]]; then
    REPLAYPATH="/home/cdaq/hallc-online/hallc_replay_lt"
elif [[ "${HOSTNAME}" = *"phys.uregina.ca"* ]]; then
    REPLAYPATH="/home/${USER}/work/JLab/hallc_replay_lt"
fi
UTILPATH="${REPLAYPATH}/UTIL_KAONLT"
cd $REPLAYPATH
# Note, using the proton replay files is temporary! Need to fix up the replay scripts for KaonLT a little
# Ideally, you want to do the same thing here though
if [ ! -f "$REPLAYPATH/UTIL_KAONLT/ROOTfilesKaon/coin_replay_scalers_${RUNNUMBER}_150000.root" ]; then
    eval "$REPLAYPATH/hcana -l -q \"UTIL_KAONLT/scripts/replay/replay_coin_scalers.C($RUNNUMBER,150000)\""
    cd "$REPLAYPATH/CALIBRATION/bcm_current_map"
    root -b<<EOF 
.L ScalerCalib.C+
.x run.C("${REPLAYPATH}/UTIL_KAONLT/ROOTfilesKaon/coin_replay_scalers_${RUNNUMBER}_150000.root")
.q  
EOF
    mv bcmcurrent_$RUNNUMBER.param $REPLAYPATH/PARAM/HMS/BCM/CALIB/bcmcurrent_$RUNNUMBER.param
    cd $REPLAYPATH
else echo "Scaler replayfile already found for this run in $REPLAYPATH/UTIL_KAONLT/ROOTfilesKaon/ - Skipping scaler replay step"
fi
sleep 15
if [ ! -f "$REPLAYPATH/UTIL_KAONLT/ROOTfilesKaon/Kaon_coin_replay_production_${RUNNUMBER}_${MAXEVENTS}.root" ]; then
    if [[ "${HOSTNAME}" != *"ifarm"* ]]; then
	eval "$REPLAYPATH/hcana -l -q \"UTIL_KAONLT/scripts/replay/replay_production_coin.C($RUNNUMBER,$MAXEVENTS)\"" 
    elif [[ "${HOSTNAME}" == *"ifarm"* ]]; then
	eval "$REPLAYPATH/hcana -l -q \"UTIL_KAONLT/scripts/replay/replay_production_coin.C($RUNNUMBER,$MAXEVENTS)\""| tee $REPLAYPATH/UTIL_KAONLT/REPORT_OUTPUT/Proton_output_coin_production_${RUNNUMBER}_${MAXEVENTS}.report
    fi
else echo "Replayfile already found for this run in $REPLAYPATH/UTIL_KAONLT/ROOTfilesKaon/ - Skipping replay step"
fi
sleep 15
if [[ "${HOSTNAME}" = *"farm"* ]]; then  
    if [[ "${HOSTNAME}" != *"ifarm"* ]]; then
	source /apps/root/6.18.04/setroot_CUE.bash
    fi
elif [[ "${HOSTNAME}" = *"qcd"* ]]; then
    source /apps/root/6.18.04/setroot_CUE.bash
fi
sleep 15
cd "$UTILPATH/scripts/kaonyield"
## The line below needs tweaking with the run prefix!
eval '"Analyse_Kaons.sh" Kaon_coin_replay_production ${RUNNUMBER} ${MAXEVENTS}'
exit 0
