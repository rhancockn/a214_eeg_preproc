function av_proc(SubjID, basedir, task)

if sum(strcmp(task, {'AVLT', 'AVNL', 'AVPW'})) ~= 1
    error('Task should be AVLT, AVNL or AVPW');
end

%CONN AV, congruent
%VSNN V
%AUNN A
%INNN AV, incongruent
%VSCN V catch
%AUCN A catch

if strcmp(task, 'AVLT')
    event_names = { 'AUNN','VSNN','CONN'};
elseif strcmp(task, 'AVPW')
    event_names = { 'AUNN','VSNN','CONN'};
elseif strcmp(task, 'AVNL')
    event_names={'AUNN','VSNN', 'AVNL'};
end



%event_names = {'DIN2'};

%set the pre- and post- stimulus intervals

%both pre and post stim must be positive values
%psw are 1000ms in duration
if strcmp(task, 'AVPW')
    prestim = .2+.25;
    poststim = 1+.25;
else %others are 500ms
    prestim = .2+.25;
    poststim = .5+.25;
end



cd([basedir '/' SubjID ])


%% find and process the data
%find any mff files with the task string in the name
data_files = dir(sprintf('*%s*.mff', task));
if isempty(data_files)
    error(' No *%s*.mff files found for %s', task, SubjID)
end

datasets = cell(1, length(data_files));
ds_cnt=0;
for dsi = 1:length(data_files)
    hdr=ft_read_header(data_files(dsi).name);
    
    if hdr.nSamples < hdr.Fs*60
        fprintf('Recording is too short. Skipping %s',  data_files(dsi).name);
        continue
    end
    
    %continue processing
    ds_cnt = ds_cnt+1;
    cfg = [];
    cfg.prestim = prestim;
    cfg.poststim = poststim;
    cfg.fname = data_files(dsi).name;
    cfg.event_names = event_names;
    cfg.prefix = sprintf('av/sub-%s_task-%s_run-%02d', SubjID, task, ds_cnt);
    cfg.lpfilter='yes';
    cfg.lpfreq=80;
    cfg.hpfreq=.1;
    cfg.baselinewindow=[-.2 0];
    datasets{ds_cnt} = a214_preproc(cfg);
end

%% merge
%remove empty cells
datasets=datasets(1:ds_cnt);

%merge
data=ft_appenddata([], datasets{:});
clear datasets;
data.elec = ft_read_sens('GSN-HydroCel-128.sfp');

if length(data.label) >200
    data.elec = ft_read_sens('GSN-HydroCel-256.sfp');
end


%% reference
cfg=[];
cfg.reref = 'yes';
cfg.refchannel = 'all';
if length(data.label) >200
    cfg.implicitref='E257';
else
    cfg.implicitref='E129';
end
data=ft_preprocessing(cfg, data);

%% baseline
cfg=[];
cfg.demean='yes';
cfg.baselinewindow = [-.2 0];
data = ft_preprocessing(cfg, data);
save(sprintf('av/sub-%s_task-%s_run-all_preproc.mat', SubjID, task), 'data', '-v7.3');


[erps, tfrs_pl, tfrs, itcs] = erp_tfr(data,event_names);

save(sprintf('av/sub-%s_task-%s_run-all_erps.mat', SubjID, task), 'erps', 'event_names');
save(sprintf('av/sub-%s_task-%s_run-all_tfrs.mat', SubjID, task), 'tfrs', 'event_names');
save(sprintf('av/sub-%s_task-%s_run-all_tfrs_pl.mat', SubjID, task), 'tfrs_pl', 'event_names');
save(sprintf('av/sub-%s_task-%s_run-all_itcs.mat', SubjID, task), 'itcs', 'event_names');

%% plot ERP
close all
h = figure;
set(h, 'PaperUnits', 'inches');
set(h, 'PaperPosition', [0 0 10 8]); %
set(h, 'Visible', 'off');
cfg=[];
cfg.xlim=[-.2 .5];
cfg.ylim=[-10 10];
ft_multiplotER(cfg, erps{1}, erps{2}, erps{3});
legend(event_names);

saveas(h,sprintf('av/sub-%s_task-%s_run-all_erps.pdf', SubjID, task));
close(h);

close all
for i=1:length(tfrs)
    %phase locked
    h = figure;
    set(h, 'PaperUnits', 'inches');
    set(h, 'PaperPosition', [0 0 10 8]); %
    set(h, 'Visible', 'off');
    cfg=[];
    cfg.xlim=[-.2 .5];
    cfg.baseline=[-.2 0];
    cfg.baselinetype='relative';
    cfg.zlim=[0 5];

    ft_multiplotTFR(cfg, tfrs{i});
    title(event_names{i})

    saveas(h,sprintf('av/sub-%s_task-%s_run-%s_tfr.pdf', SubjID, task, event_names{i}));
    close(h);

    %total
    h=figure;
    set(h, 'PaperUnits', 'inches');
    set(h, 'PaperPosition', [0 0 10 8]); %
    set(h, 'Visible', 'off');
    ft_multiplotTFR(cfg, tfrs_pl{i});

    saveas(h,sprintf('av/sub-%s_task-%s_run-%s_tfrpl.pdf', SubjID, task, event_names{i}));
    close(h);
end


