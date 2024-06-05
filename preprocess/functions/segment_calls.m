function [noise_thresholds, onsets, offsets] =...
    segment_calls(smooth_audio, fs, min_int, min_dur, q, stim_i)
% segment_calls.m
% 2024.02.12 CDR
% supercedes filter_segment; also see function filt_rec_smooth
% 
% Segment calls from stim-aligned audio data. Should be
% pre-filtered/smoothed.
% 
% PARAMETERS
%   - filt: n trials of filtered/smoothed audio data ([n_trials x n_frames] matrix)
%   - fs: sample freq (Hz)
%   - min_int: minimum interval (in ms) to consider calls separate (& not merge them) (scalar)
%   - min_dur: minimum call duration (in ms) of calls (else ignore) (scalar)
%   - q: q*trial_median = noise_threshold. (scalar)
%   - stim_i: index (in frames) of stimulation. (scalar)
% 
% OUTPUTS
%   - noise_thresholds: noise threshold for each trial ([n_trials x 1] vec)
%   - onsets/offsets: cell array containing call onset(s)/offset(s) in
%       frames for each trial ([n_trials x 1] cell of double arrays)

%% preallocate
d = [size(smooth_audio, 1), 1];

noise_thresholds = zeros(d);
onsets = cell(d);
offsets = cell(d);

%% get onsets/offsets
for i=1:size(smooth_audio,1)  % for each trial in this condition
    noise_thresholds(i) = q * median(smooth_audio(i, 1:stim_i));  % use data from before stim; changed from entire trial. 20230108CDR

    [onset, offset] = SegmentNotesJC( ...
        smooth_audio(i,:), fs, min_int, min_dur, noise_thresholds(i));

    onsets{i} = round(onset*fs); % seconds -> frame. round ensures int.
    offsets{i} = round(offset*fs);
end


end

