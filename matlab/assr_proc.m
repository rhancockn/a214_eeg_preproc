function assr_proc(SubjID, basedir)


event_names = {'AM30', 'AM40', 'AM50'};
%event_names = {'DIN2'};

%set the pre- and post- stimulus intervals
prestim = .5+.250;
poststim = 1+.250;



cd([basedir '/' SubjID ])


%% find and process the data
%find any mff files with ASSR in the name
data_files = dir('*ASSR*.mff');
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
    cfg.prefix = sprintf('assr/sub-%s_task-assr_run-%0d', SubjID, ds_cnt);
    cfg.lpfilter='yes';
    cfg.lpfreq=80;
    cfg.hpfreq=.1;
    cfg.baselinewindow=[-.5 0];
    datasets{ds_cnt} = a214_preproc(cfg);
end

%remove empty cells
datasets=datasets(1:ds_cnt);

%merge
data=ft_appenddata([], datasets{:});
clear datasets;
data.elec = ft_read_sens('GSN-HydroCel-128.sfp');

if length(data.label) >200
    data.elec = ft_read_sens('GSN-HydroCel-256.sfp');
end


cfg=[];
cfg.demean='yes';
cfg.baselinewindow = [-.5 0];
data = ft_preprocessing(cfg, data);
save(sprintf('assr/sub-%s_task-assr_run-all_preproc.mat', SubjID), 'data','-v7.3');

%TF measures for each event
[erps, tfrs_pl, tfrs, itcs] = erp_tfr(data,event_names);

save(sprintf('assr/sub-%s_task-%s_run-all_erps.mat', SubjID, 'assr'), 'erps', 'event_names');
save(sprintf('assr/sub-%s_task-%s_run-all_tfrs.mat', SubjID, 'assr'), 'tfrs', 'event_names');
save(sprintf('assr/sub-%s_task-%s_run-all_tfrs_pl.mat', SubjID, 'assr'), 'tfrs_pl', 'event_names');
save(sprintf('assr/sub-%s_task-%s_run-all_itcs.mat', SubjID, 'assr'), 'itcs', 'event_names');


%% plot
close all
h = figure;
set(h, 'PaperUnits', 'inches');
set(h, 'PaperPosition', [0 0 10 8]); %
set(h, 'Visible', 'off');
cfg=[];
cfg.xlim=[-.2 1];
cfg.ylim=[-10 10];
ft_multiplotER(cfg, erps{1}, erps{2}, erps{3});
legend(event_names);

saveas(h,sprintf('assr/sub-%s_task-%s_run-all_erps.pdf', SubjID, 'ASSR'));
close(h);

%% plot

close all
for i=1:length(tfrs)
    %total
    h = figure;
    set(h, 'PaperUnits', 'inches');
    set(h, 'PaperPosition', [0 0 10 8]); %
    set(h, 'Visible', 'off');
    cfg=[];
    cfg.xlim=[-.2 1];
    cfg.baseline=[-.5 0];
    cfg.baselinetype='relative';
    cfg.zlim=[0 5];

    ft_multiplotTFR(cfg, tfrs{i});
    title(event_names{i})

    saveas(h,sprintf('assr/sub-%s_task-%s_run-%s_tfr.pdf', SubjID, 'ASSR', event_names{i}));
    close(h);

    %phase locked
    h=figure;
    set(h, 'PaperUnits', 'inches');
    set(h, 'PaperPosition', [0 0 10 8]); %
    set(h, 'Visible', 'off');
    ft_multiplotTFR(cfg, tfrs_pl{i});

    saveas(h,sprintf('assr/sub-%s_task-%s_run-%s_tfrpl.pdf', SubjID, 'ASSR', event_names{i}));
    close(h);
end



