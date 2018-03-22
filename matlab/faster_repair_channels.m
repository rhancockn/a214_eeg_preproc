%% FASTER like automated identification of bad channels
% with spline channel repair
% Nolan et al, J Neurosci Meth 2010
% 
function [data, channel_outliers] = faster_repair_channels(data, z_thresh)
if nargin < 2 || isempty(z_thresh)
    z_thresh = 3;
end

% cut
cfg=[];
cfg.length = 2;
datatrl = ft_redefinetrial(cfg,data);

cfg = [];
cfg.detrend='yes';
cfg.demean='yes';
datatrl = ft_preprocessing(cfg,datatrl);

X=cell2mat(datatrl.trial);

c = mean(abs((corr(X'))));
corr_outliers = abs(c-mean(c))/std(c) > z_thresh;
v = var(X');
var_outliers = (abs(v-mean(v))/std(v)) > z_thresh;
hurst = zeros(1, length(data.label));
hurst_outliers = zeros(1, length(data.label));
if ~isempty(ver('wavelet'))
    for i=1:length(data.label)
        h = wfbmesti(X(i,:));
        hurst(i)=h(1);
    end
    hurst_outliers = abs(hurst-mean(hurst))/std(hurst) > z_thresh;
else
    warning('Wavelet toolbox not found-not using Hurst exponent to find bad channels');
end

channel_outliers = var_outliers | corr_outliers | hurst_outliers;


%% repair bad channels 
sprintf('Repairing %d channels', sum(channel_outliers))

cfg = [];
cfg.method = 'spline';
cfg.badchannel = data.label(channel_outliers);
data = ft_channelrepair(cfg, data);

