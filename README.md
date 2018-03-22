# Installation

1. Install fieldtrip: `git clone https://github.com/fieldtrip/fieldtrip`
1. Clone this repository: `git clone https://github.com/rhancockn/a214_eeg_preproc.git`
2. Edit `a214_driver.sh`:
	3. Set `FIELDTRIP_PATH` to the FieldTrip installation directory
	4. Set `A214_SCRIPT_PATH` 
	5. Set `DATA_PATH` to the directory where new EEG subject folders are added
	6. `N_PROCS` sets the number of parallel processes, if supported. Note that preprocessing is very RAM intensive.
3. Copy the provided `ft_read_event.m` to `$FIELDTRIP_PATH/fileio/ft_read_event.m`. This provides a minor fix to the XML parser to resolve issues parsing some mff files.
4. Install python requirements: `pip install -r requirements.txt`


## Automated Processing
To automatically run the script, you can install a crontab by either manually editing the crontab (`crontab -e`; see [format](https://crontab.guru)) to run the `a214_driver.sh` script on a schedule.

To do this automatically:

```
cd a214_eeg_preproc
./install_crontab.sh
```

This will add a line to your current crontab that runs the preprocessing every Sunday at 10pm.


# Directory Structure

The script assumes the directory `$DATA_PATH` is organized as:
- A214_NNN/
	- *ASSR*.mff
	- *AVLT*.mff
	- *AVNL*.mff
	- *AVPW*.mff

The recordings can be split into multiple files. For example, if you have raw data files named `214013_AVNL_2.mff` and `214013_AVNL.mff`, these will be preprocessed individually and then merged to produce a single processed AVNL dataset.

Running the script will create:
- A214_NNN/
 - assr/
 - av/
 - logs/

The output files are:
- A partially preprocessed dataset for each MFF file (`_run-01_preproc.mat`)
- A single processed dataset containing all remaining trials (`_run-all_preproc.mat`)
- ERPs (`_run-all_erps.mat`) for each condition
- Total power TFRs (`_run-all_tfrs.mat`) for each condition
- Phase-locked TFRs (`_run-all_tfrs_pl.mat`) for each condition
- Intertrial coherence (`_run-all_itcs.mat`) for each condition
- Various ERP and TFR plots


# Troubleshooting

## Crashed jobs
The script checks if `${A214_SCRIPT_PATH}/preproc.pid` exists. If this file is found, the scirpt assumes that a job is already running and will immediately exit. If the script crashes for some reason, you may need to remove this file.

Logs for each processed subject and task are in the respective subject's `logs/` directory. The logfile for a given task (e.g. `logs/ASSR.log` for the ASSR task) needs to be deleted if you want to reprocess a subject.


