function features = get_acoustic_features(audio_calls, fs)
%% get_acoustic_features.m
% 2024.04.14 CDR
% 
% given a cell array of audio snippets, return some basic acoustic features
% for each audio snippet as a struct
% 
% - duration
% - max amplitude
% - fma
% - amplitude of fma
% - spectral entropy

features = [];

% call duration in ms
features.duration = cellfun(@(tr) length(tr)*1000/fs, audio_calls);

features.max_amp_filt = cellfun(@(tr) max(abs(tr)), audio_calls);

% frequency of maximum amplitude
[features.freq_max_amp, ...
 features.max_amp_fft]...
    = fma(audio_calls, fs);

% spectral entropy:
features.spectral_entropy = cellfun(@(tr) pentropy(tr,fs,Instantaneous=false), audio_calls);

end