function [erps, tfrs_pl, tfrs, itcs] = erp_tfr(data,event_names)
%% ERPs and TFRs for each stim type
erps = cell(1,length(event_names));
tfrs_pl=cell(1,length(event_names));
tfrs=cell(1,length(event_names));
itcs=cell(1,length(event_names));

for ei=unique(data.trialinfo)'
    cfg=[];
    cfg.trials = data.trialinfo == ei;
    data_sel = ft_selectdata(cfg, data);
    
    cfg=[];
    cfg.lpfreq=30;
    cfg.lpfilter='yes';
    cfg.lpfilttype='fir';
    cfg.baselinewindow = [-.2 0];
    cfg.demean='yes';
    data_sel_lp = ft_preprocessing(cfg, data_sel);
    tl = ft_timelockanalysis([], data_sel_lp);
    erps{ei}=tl;
    
    %t-f analysis
    cfg=[];
    cfg.output = 'pow';
    cfg.method = 'wavelet';
    cfg.width=20;
    cfg.foi=2:1:60;
    cfg.toi=min(data.time{1}):.01:max(data.time{1});
    
%     cfg=[];
%     cfg.output = 'pow';
%     cfg.method     = 'mtmconvol';
%     cfg.foi        = 1:.5:70;
%     cfg.toi        = -prestim:.01:poststim;
%     cfg.t_ftimwin    = ones(length(cfg.foi),1)*.5;
%     cfg.taper = 'hanning';
    tl_freq = ft_timelockanalysis([], data_sel);
    tfrs_pl{ei} = ft_freqanalysis(cfg, tl_freq);
    tfrs{ei} = ft_freqanalysis(cfg, data_sel);
    
    cfg.keeptrials='yes';
    cfg.output='fourier';
    ftfr = ft_freqanalysis(cfg, data_sel);
    itcs{ei} = itcanalysis(ftfr);
end
