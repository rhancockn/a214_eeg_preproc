%% FASTER like automated identification and removal of bad epochs
% Nolan et al, J Neurosci Meth 2010
% 
function [data, trial_outliers, trial_info] = faster_remove_epochs(data, z_thresh)
if nargin < 2 || isempty(z_thresh)
    z_thresh = 3;
end
x=cell2mat(data.trial);
chan_mean=mean(x,2);
trial_range = zeros(1,numel(data.trial));
trial_dev = zeros(1,numel(data.trial));
trial_var = zeros(1,numel(data.trial));

for i=1:numel(data.trial)
    trial_range(i) = mean(range(data.trial{i},2));
    trial_dev(i)=mean(mean(data.trial{i},2)-chan_mean);
    trial_var(i)=mean(var(data.trial{i}'));
end

trial_range_outlier = abs(trial_range-mean(trial_range))/std(trial_range) > z_thresh;
trial_dev_outlier = abs(trial_dev-mean(trial_dev))/std(trial_dev) > z_thresh;
trial_var_outlier = abs(trial_var-mean(trial_var))/std(trial_var) > z_thresh;

trial_outliers = trial_range_outlier | trial_dev_outlier | trial_var_outlier;

trial_info=data.trialinfo;
sprintf('Removing %d epochs', sum(trial_outliers))

cfg=[];
cfg.trials = ~trial_outliers;
data = ft_selectdata(cfg, data);

    
    
