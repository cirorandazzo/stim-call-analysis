function [call_seg_data] = s3_segment_calls( ...
    proc_data, fs, f_low, f_high, smoothing_window, filter_type, ...
    min_int, min_dur, q, stim_i, post_stim_call_window_ii, options)
% S3_SEGMENT_CALLS
% 2024.02.12 CDR from b_segment_calls
% 
%   TODO: s3 documentation
% 
% PARAMETERS
%   TODO
%   post_stim_call_window_ii: 2x1 integer array containing start and end of
%       window in which to look for call.
% 
% - filter, rectify, smooth audio data (turn filter off with varargin keyword 'nofilt'
% - segment calls
% - get spectral features of processed data

arguments
    proc_data
    fs
    f_low
    f_high
    smoothing_window
    filter_type
    min_int
    min_dur
    q
    stim_i
    post_stim_call_window_ii (2,1) {mustBeInteger}
    options.NoAudioProcessing = 0
end

for c=length(proc_data):-1:1  % for each condition
    if options.NoAudioProcessing
        audio = proc_data(c).audio;
    else
        a = proc_data(c).audio;
        
        audio = filterRectifySmooth(a, fs, f_low, f_high, smoothing_window, filter_type);
        proc_data(c).audio_filt = audio;
    end

    [proc_data(c).call_seg.noise_thresholds, ...
        call_onsets, ...
        call_offsets ...
        ] = segmentCalls(audio, fs, min_int, min_dur, q, stim_i);

    %--only take calls within desired window
    
    % check onsets/offsets individually
    i_on = cellfun(@(x) x >=post_stim_call_window_ii(1) & x<=post_stim_call_window_ii(2), call_onsets, 'UniformOutput',false);
    i_off = cellfun(@(x) x >=post_stim_call_window_ii(1) & x<=post_stim_call_window_ii(2), call_offsets, 'UniformOutput',false);

    % ensure both onset/offset are within that window
    i_good = arrayfun(@(i) {i_on{i} & i_off{i}}, 1:size(i_on,1));

    % delete remainder & save
    call_onsets = arrayfun(@(i)  call_onsets{i}(i_good{i}), 1:size(i_on,1), 'UniformOutput',false)';
    call_offsets = arrayfun(@(i) call_offsets{i}(i_good{i}), 1:size(i_on,1), 'UniformOutput',false)';

    
    proc_data(c).call_seg.onsets = call_onsets;
    proc_data(c).call_seg.offsets = call_offsets;

    %--count # of calls in each trial
    % Helps determine if audio segmentation was successful
    proc_data(c).call_seg.no_calls = find(cellfun(@isempty, call_onsets));  % NO CALLS FOUND
    proc_data(c).call_seg.one_call = find(cellfun(@(x) length(x)==1, call_onsets)); % EXACTLY 1 CALL
    proc_data(c).call_seg.multi_calls = find(cellfun(@(x) length(x)>1, call_onsets));  % >1 CALL

    % For trials with EXACTLY ONE call, cut call audio & save 
    if ~isempty(proc_data(c).call_seg.one_call)
        proc_data(c).call_seg.audio_filt_call = arrayfun( ...
            @(tr) audio(tr, proc_data(c).call_seg.onsets{tr}:proc_data(c).call_seg.offsets{tr}), ...
            proc_data(c).call_seg.one_call, ...
            'UniformOutput',false);

        proc_data(c).call_seg.acoustic_features = getAcousticFeatures( ...
            proc_data(c).call_seg.audio_filt_call, fs);

        proc_data(c).call_seg.acoustic_features.latencies = arrayfun( ...
            @(tr) (call_onsets{tr} - stim_i) * 1000 / fs, ...
            proc_data(c).call_seg.one_call, ...
            'UniformOutput',false);
    end

    % Save processing parameters
    proc_data(c).call_seg.q = q;
    proc_data(c).call_seg.min_int = min_int;
    proc_data(c).call_seg.min_dur = min_dur;
end

% rename struct
call_seg_data = proc_data;

end


%% LOCAL HELPERS

% filterRectifySmooth
function [smooth, params] = filterRectifySmooth(unfilt, fs, f_low, f_high, sm_win, filter_type)
% filt_rec_smooth
% 2024.02.12 CDR
% 
% Filters, rectifies, and smooths audio data using evsmooth from
% evsonganaly.

    for i=size(unfilt,1):-1:1
        smooth{i} = evsmooth(unfilt(i, :), fs, sm_win, f_low, f_high, filter_type);
    end
    
    smooth = cell2mat(smooth');
    
    params.filter_type = filter_type;
    params.f_low = f_low;
    params.f_high = f_high;
    params.sm_win = sm_win;


end

% fma
function [f_maxes, amp_maxes] = fma(audio_calls, fs)
% fma.m
% 2023.01.08 CDR
% 
% Given cell array where each cell contains audio data, return frequency of
% maximum amplitude for every cell.
    
    f_maxes = zeros([length(audio_calls) 1]);
    amp_maxes = zeros([length(audio_calls) 1]);
    
    for tr=1:length(audio_calls)
        Y=fft(audio_calls{tr});
        L = length(audio_calls{tr});
    
        [amp_max, i_max] = max(abs(Y));
    
        f_max = fs/L * i_max;
    
        f_maxes(tr) = f_max;
        amp_maxes(tr) = amp_max;
    end
    
end


% getAcousticFeatures
function features = getAcousticFeatures(audio_calls, fs)
%% getAcousticFeatures
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


% segmentCalls
function [noise_thresholds, onsets, offsets] =...
    segmentCalls(smooth_audio, fs, min_int, min_dur, q, stim_i)
% segment_calls
% 2024.02.12 CDR
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

    % preallocate
    d = [size(smooth_audio, 1), 1];
    
    noise_thresholds = zeros(d);
    onsets = cell(d);
    offsets = cell(d);
    
    % get onsets/offsets
    for i=1:size(smooth_audio,1)  % for each trial in this condition
        noise_thresholds(i) = q * median(smooth_audio(i, 1:stim_i));  % use data from before stim; changed from entire trial. 20230108CDR
    
        [onset, offset] = SegmentNotesJC( ...
            smooth_audio(i,:), fs, min_int, min_dur, noise_thresholds(i));
    
        onsets{i} = round(onset*fs); % seconds -> frame. round ensures int.
        offsets{i} = round(offset*fs);
    end

end


