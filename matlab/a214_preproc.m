function data=a214_preproc(pcfg)
SCRIPT_VERSION = getenv('SCRIPT_VERSION');
%% read the events and define epochs
trl = [];
trialinfo = [];
events = ft_read_event(pcfg.fname,'headerformat', 'egi_mff_v2', 'dataformat', 'egi_mff_v2');
hdr = ft_read_header(pcfg.fname,'headerformat', 'egi_mff_v2', 'dataformat', 'egi_mff_v2');
event_values = {events.value};
event_samples = [events.sample];

for evt_i = 1:length(pcfg.event_names)
    idxs = strcmp(pcfg.event_names{evt_i}, event_values);
    trl1 = [event_samples(idxs)-ceil(pcfg.prestim*hdr.Fs); event_samples(idxs)+ceil(pcfg.poststim*hdr.Fs)-1]';
    trialinfo1 = ones(sum(idxs),1)*evt_i;
    trl = [trl; trl1];
    trialinfo = [trialinfo;trialinfo1];
    
end

%add the offset to the trl structure
trl(:,3) = -ceil(hdr.Fs * pcfg.prestim);

%% preprocess the data
cfg=[];
cfg.datafile=pcfg.fname;
cfg.headerfile=pcfg.fname;
cfg.dataformat = 'egi_mff_v2';
cfg.headerformat = 'egi_mff_v2';
cfg.dftfilter='yes';
cfg.dftfreq=[60 120];
cfg.lpfilter = pcfg.lpfilter;
cfg.lpfilttype = 'fir';
cfg.lpfreq = pcfg.lpfreq;
cfg.hpfreq = pcfg.hpfreq;
cfg.hpfilter = 'yes';
cfg.hpfilttype = 'fir';
cfg.demean='yes';
data=ft_preprocessing(cfg);

if length(data.label) > 200
data.elec = ft_read_sens('GSN-HydroCel-256.sfp');
else
    data.elec = ft_read_sens('GSN-HydroCel-128.sfp');
end


%remove the reference
cfg=[];
cfg.channel = ft_channelselection({'E*', '-E129'}, data.label);
if length(data.label) > 200
    cfg.channel = ft_channelselection({'E*', '-E257'}, data.label);
end

data = ft_selectdata(cfg, data);

% identify and repair bad channels
[data, channel_outliers] = faster_repair_channels(data);

%% epoch and baseline
cfg=[];
cfg.trl=trl;
data = ft_redefinetrial(cfg, data);
data.trialinfo = trialinfo;

cfg = [];
cfg.demean = 'yes';
cfg.baselinewindow = pcfg.baselinewindow;
data = ft_preprocessing(cfg, data);


%% artifact removal
% cleanup certain artifacts before ICA
[data_preica,trial_outliers, trial_info] = faster_remove_epochs(data);

%% ICA

[data_rej, comp_outliers,comp] = faster_ica_clean(data_preica);

%rebaseline after ICA
cfg = [];
cfg.demean = 'yes';
cfg.baselinewindow = pcfg.baselinewindow;
data_rej = ft_preprocessing(cfg, data_rej);

v_thresh=100;
bad_trials=zeros(1,length(data_rej.trial));
 for i=1:length(data_rej.trial)
     if max(max(abs(data_rej.trial{i}))) > v_thresh
         bad_trials(i)=1;
     end
 end

cfg = [];
cfg.trials=~bad_trials;
data = ft_selectdata(cfg,data_rej);

 
save(sprintf('%s_preproc.mat', pcfg.prefix), 'data', 'comp', 'comp_outliers', 'channel_outliers', 'trial_outliers', 'trial_info','bad_trials', 'SCRIPT_VERSION', '-v7.3');


