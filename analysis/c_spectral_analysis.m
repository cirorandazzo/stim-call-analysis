%% c_spectral_analysis.m
% 2023.01.05 CDR
% 
% spectral features of calls.
% saved in spectral_features field (nested struct) of call_seg_data
% 
% NOTE: this script only considers trials which have EXACTLY 1 call

clear;
close all;

%% load file

file_path = '/Users/cirorandazzo/ek-spectral-analysis/call_seg_data-bk68wh15.mat';
save_file = '/Users/cirorandazzo/ek-spectral-analysis/spectral_features-bk68wh15.mat';

load(file_path);

%% constants

fs = 30000; 
stim_i = 30001;

%%

for c = length(call_seg_data):-1:1
    % call_seg_data(c).stimBreathPhase = getBreathPhaseStim(call_seg_data(c).breathing, stim_i);
    % TODO: stimBreathPhase

    if ~isempty(call_seg_data(c).audio_filt_call)

        audio_calls = call_seg_data(c).audio_filt_call;

        % call duration in ms
        call_seg_data(c).spectral_features.duration = cellfun(@(tr) length(tr)*1000/fs, audio_calls);

        call_seg_data(c).spectral_features.max_amp_filt = cellfun(@(tr) max(abs(tr)), audio_calls);

        % frequency of maximum amplitude
        [f_max, amp_max] = fma(audio_calls, fs);
        call_seg_data(c).spectral_features.freq_max_amp = f_max;
        call_seg_data(c).spectral_features.max_amp_fft = amp_max;

        % spectral entropy:
        call_seg_data(c).spectral_features.spectral_entropy = cellfun(@(tr) pentropy(tr,fs,Instantaneous=false), audio_calls);
    end
end

% rename struct
spectral_features = call_seg_data;
clear call_seg_data

%% SAVE

save(save_file, 'spectral_features')