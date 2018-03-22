%calculate ITPC
function itc=itcanalysis(freq)
itc = [];
itc.label     = freq.label;
itc.freq      = freq.freq;
itc.time      = freq.time;
itc.dimord    = 'chan_freq_time';
F = freq.fourierspctrm;   % copy the Fourier spectrum
N = size(F,1);           % number of trials
% compute inter-trial phase coherence (itpc)
itc.itpc      = sum(F,1) ./ sum(abs(F),1);
itc.itpc      = abs(itc.itpc);     % take the absolute value, i.e. ignore phase
itc.itpc      = squeeze(itc.itpc); % remove the first singleton dimension
% compute inter-trial linear coherence (itlc)
itc.itlc      = sum(F) ./ (sqrt(N*sum(abs(F).^2)));
itc.itlc      = abs(itc.itlc);     % take the absolute value, i.e. ignore phase
itc.itlc      = squeeze(itc.itlc); % remove the first singleton dimension
