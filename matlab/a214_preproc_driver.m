function a214_preproc_driver(SubjID, task)
addpath(getenv('FIELDTRIP_PATH'));
ft_defaults;
%mff_setup

addpath(genpath(getenv('A214_SCRIPT_PATH')));
fprintf('a214_preproc version %s\n', getenv('SCRIPT_VERSION'));

if strcmp(task, 'ASSR')
    assr_proc(SubjID, getenv('DATA_PATH'));
else
    av_proc(SubjID, getenv('DATA_PATH'), task);
end

