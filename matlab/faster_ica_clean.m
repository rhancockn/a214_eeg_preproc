%% FASTER like automated identification and removal of bad ICs
% Nolan et al, J Neurosci Meth 2010
% 
function [data, comp_outliers,comp] = faster_ica_clean(data, z_thresh)
if nargin < 2 || isempty(z_thresh)
    z_thresh = 3;
end

elec = data.elec;
%select the number of components based on the suggested number of samples
%and data rank (to account for referencing and inteprolated channels)
Cpca = floor(min(sqrt(numel(data.trial)*length(data.trial{1})/25), rank(data.trial{1})));

%channels approximately corresponding to V/HEOG on the EGI128 net
eog_channels =  {'E127'  'E126'  'E21'  'E14'  'E128'  'E125'};
if length(data.label) > 200
    eog_channels =  {'E238'  'E234'  'E10'  'E44'  'E241'  'E244'};
end

%high pass filter for ICA

cfg=[];
cfg.hpfilter='yes';
cfg.hpfreq=1;
cfg.hpfilttype='fir';
cfg.baselinewindow=[-.2 0];
cfg.demean='yes';
data_lp=ft_preprocessing(cfg, data);

cfg=[];
cfg.method = 'runica';
%cfg.method='fastica'; %faster but poor results
%cfg.fastica.lastEig = Cpca; % this actually controls the dimension reduction
cfg.numcomponent = Cpca;
comp = ft_componentanalysis(cfg, data_lp);
%comp.elec=data.elec;


%apply weights to original data
cfg=[];
cfg.unmixing=comp.unmixing;
cfg.topolabel=comp.topolabel;
cfg.numcomponent = Cpca;
comp = ft_componentanalysis(cfg, data);
%comp.elec=data.elec;

%% find artifactual components
x_comp=cell2mat(comp.trial);



% eog
cfg=[];
cfg.channel = eog_channels;
data_eog=ft_selectdata(cfg, data);
x_eog=cell2mat(data_eog.trial);
c=corr( x_comp',x_eog');
r_eog = max(abs(c),[],2);
%eog_outliers = abs(r_eog-mean(r_eog))/std(r_eog) > z_thresh;
eog_outliers = r_eog > .3;
% kurtosis
k=kurtosis(x_comp');
kurtosis_outliers = abs(k-mean(k))/std(k) > z_thresh;


% slope
med_diff_comp=median(diff(x_comp'));
slope_outliers = abs(med_diff_comp-mean(med_diff_comp))/std(med_diff_comp) > z_thresh;

% hurst
hurst = zeros(1, length(comp.label));
hurst_outliers = zeros(1, length(comp.label));
if ~isempty(ver('wavelet'))
    for i=1:length(comp.label)
        h = wfbmesti(comp.trial{1}(i,:));
        hurst(i)=h(1);
    end
    hurst_outliers = abs(hurst-mean(hurst))/std(hurst) > z_thresh;
else
    warning('Wavelet toolbox not found-not using Hurst exponent to find bad components');
end


comp_outliers = eog_outliers' | kurtosis_outliers | slope_outliers | hurst_outliers;
sprintf('Rejecting %d components', sum(comp_outliers))

%% reconstruct
cfg=[];
cfg.component = find(comp_outliers);
data = ft_rejectcomponent(cfg, comp);


cfg=[];
cfg.reref = 'yes';
cfg.refchannel = 'all';
cfg.implicitref='E129';
if length(data.label) > 200
	cfg.implicitref = 'E259'
end

data=ft_preprocessing(cfg, data);
data.elec = elec;
