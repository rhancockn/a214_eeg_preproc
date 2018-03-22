#!/bin/bash
export FIELDTRIP_PATH="/Users/roh17004/matlab/fieldtrip"
export A214_SCRIPT_PATH="/Users/roh17004/Desktop/A214_samples/a214_eeg_preproc/matlab/"
export DATA_PATH="/Users/roh17004/Desktop/A214_samples/EEG Test"
export MATLAB_HOME=/Applications/MATLAB_R2016b.app
#for data on bowie, uncommenting the enxt line should work
#export DATA_PATH="/Volumes/EEGDATA/ EEG Data/A214/214 EEG Data"
export N_PROCS=1

#check for updates
git pull

export SCRIPT_VERSION=`git rev-parse HEAD`

tasks='ASSR AVLT AVNL AVPW'
#create a PID file so only one copy of the script runs
pid="${A214_SCRIPT_PATH}/preproc.pid"
if [ -f $pid ]; then
	echo "Already running ($pid)"
	cat "$pid"
	exit
fi

echo "$$" > "$pid"
date >> "$pid"


#list subjects
cd "$DATA_PATH"
subjects=`ls -d A214_*`

cd "$A214_SCRIPT_PATH"

#keep the display awake to avoid matlab initialization errors on macos
#this does not disable manually sleeping the display-avoid this
if [ "$OSTYPE"=="darwin"* ]; then
	echo "caffeinating $$"
	caffeinate -dsi -w $$ &
fi

for subj in $subjects; do
	if [ ! -d "${DATA_PATH}/${subj}/logs" ]; then
		mkdir "${DATA_PATH}/${subj}/logs"
		mkdir "${DATA_PATH}/${subj}/assr"
		mkdir "${DATA_PATH}/${subj}/av"
	fi

	for task in $tasks; do
		log_file="${DATA_PATH}/${subj}/logs/${task}.log"
		if [ -f "$log_file" ]; then
			echo "Skipping $subj $task-remove $log_file to reprocess"
		else
			echo "Processing $subj $task"
			${MATLAB_HOME}/bin/matlab -nodesktop -nosplash -r "try, a214_preproc_driver('$subj', '$task'); catch e, fprintf(2,getReport(e)), end, quit" > "$log_file" 2> "${log_file%.log}_error.log"
		fi
	done
done


rm "$pid"

