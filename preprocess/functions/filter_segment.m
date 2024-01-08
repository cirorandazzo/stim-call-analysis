function [filtsongs, noise_thresholds, onsets, offsets] = filter_segment(unfilt, fs, f_low, f_high, min_int, min_dur, q, stim_i)
% filter_segment.m
% 2023.01.05 CDR
% 
% Given stim-aligned audio data, filter it & segment out calls.
% 
% PARAMETERS
%   - unfilt: n trials of unfiltered audio data ([n_trials x n_frames] matrix)
%   - fs: sample freq (Hz)
%   - f_low/f_high: bandpass limits in Hz (scalar)
%   - min_int: minimum interval (in ms) to consider calls separate (& not merge them) (scalar)
%   - min_dur: minimum call duration (in ms) of calls (else ignore) (scalar)
%   - q: q*trial_median = noise_threshold. (scalar)
%   - stim_i: index (in frames) of stimulation. (scalar)
% 
% OUTPUTS
%   - filtsongs: bandpass filtered songs ([n_trials x n_frames] matrix)
%   - noise_thresholds: noise threshold for each trial ([n_trials x 1] vec)
%   - onsets/offsets: cell array containing call onset(s)/offset(s) in
%       frames for each trial ([n_trials x 1] cell of double arrays)

%% preallocate
d = [size(unfilt,1) 1];

filtsongs = cell(d);
noise_thresholds = zeros(d);
onsets = cell(d);
offsets = cell(d);

%% filter every trial in this condition & get noise thresholds
for i=1:size(unfilt,1)  
    filtsongs{i}=pj_bandpass(unfilt(i,:), fs, f_low, f_high, 'butterworth');
    noise_thresholds(i) = q * median(abs(filtsongs{i}(1:stim_i)));  % use data from before stim; changed from entire trial. 20230108CDR
    % noise_thresholds(i) = q * median(abs(filtsongs{i}));  % entire thing
end
filtsongs = cell2mat(filtsongs);

%% get onsets/offsets
for i=1:size(unfilt,1)  % for each trial in this condition
    [onset, offset] = SegmentNotesJC(abs(filtsongs(i,:)), fs, min_int, min_dur, noise_thresholds(i));

    onsets{i} = round(onset*fs); % seconds -> frame. round ensures int.
    offsets{i} = round(offset*fs);
end

end

