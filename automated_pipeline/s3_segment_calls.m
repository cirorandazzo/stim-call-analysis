function [call_seg_data] = s3_segment_calls( ...
    proc_data, ...
    fs, stim_i, ...
    f_low, f_high, audio_smoothing_window, filter_type, ...
    min_int, min_dur, q, ...
    post_stim_call_window_ms, ...
    options)
% S3_SEGMENT_CALLS.m
% 2024.02.12 CDR from b_segment_calls
% 
% PARAMETERS
%   TODO
% 
% - filter, rectify, smooth audio data
% - segment calls
% - get spectral features of processed data
% 
% Note: kwarg NoAudioProcessing removed.
% 
% DESCRIPTION
% Segments calls from cut trials of raw audio data in `proc_struct` (see s2).
%   - filtering, rectification, and smoothing on the audio data
%   - audio-thresholded segmentation of calls (thres = parameter q * median(pre-stimulus period))
%   - compute spectral features of cut calls
% 
% INPUTS
%   proc_data:  
%       Struct array containing processed audio data.
%   fs:         
%       Sampling frequency of the audio data.
%   f_low:      
%       Low cutoff frequency for filtering.
%   f_high:     
%       High cutoff frequency for filtering.
%   audio_smoothing_window:
%       Size (in frames) of smoothing window for audio.
%   filter_type:    
%       Type of filter to apply. 'hanningfir' or 'butterworth' (see pj_bandpass)
%   min_int:    
%       minimum interval (in ms) to consider calls separate (& not merge them) (scalar)
%   min_dur:
%       minimum call duration (in ms) of calls (else ignore) (scalar)
%   q:
%       noise_threshold = q * median(trial before stimulus). (scalar)
%   stim_i:
%       index (in frames) of stimulation. (scalar)
%   post_stim_call_window_ms:
%       2x1 numeric array containing the window in which to look for calls (milliseconds wrt stim onset).
%   options: Optional args.
%       ManualCallSegFilePath: 
%           path to .mat file containing onsets/offsets.
%           Will skip segmentation if this arg is not empty.
%
% OUTPUT
%   call_seg_data: 
%       Struct array containing segmented call data. New fields added to
%       proc data:
%        - audio_filt: 
%               filtered, smoothed, rectified audio
%        - audio_filt_only:
%               filtered audio (not smoothed + not rectified)
%        - call_seg: 
%               struct with fields
%                   - noise_thresholds:
%                       computed noise thresholds for each cut trial (double, n_trials x 1)
%                   - onsets:
%                       cell of doubles. for each trial, contains double array with onset frame for all detected calls
%                   - offsets:
%                       cell of doubles. for each trial, contains double array with offset frame for all detected calls
%                   - no_calls:
%                       indices of trials where no call was detected
%                   - one_call:
%                       indices of trials where exactly one call was detected (ie, "one call trials")
%                   - multi_calls:
%                       indices of trials where more than one call was detected
%                   - audio_call/audio_filt_call:
%                       for one call trials, store raw or filtRecSmoothed audio (respectively) from onset:offset
%                   - acoustic_features:
%                       acoustic features computed from audio_call
%                   - q/min_int/dur:
%                       store an extra copy of parameters
% 

arguments
    proc_data
    fs
    stim_i
    f_low
    f_high
    audio_smoothing_window
    filter_type
    min_int
    min_dur
    q
    post_stim_call_window_ms (2,1) {isnumeric}
    options.ManualCallSegFilePath = [];  % Note: keyword argument was removed.
end

post_stim_call_window_fr = (post_stim_call_window_ms * fs / 1000) + stim_i;

if ~isempty(options.ManualCallSegFilePath)
    warning("Using manual file labels from: " + options.ManualCallSegFilePath);
    manual_labels = load(options.ManualCallSegFilePath);

    assert( length(proc_data) == 1, "Manual labels for >1 condition not implemented.");
end

for c=length(proc_data):-1:1  % for each condition
    audio = proc_data(c).audio;
    
    % the names are not good, sorry.

    % audio_filt: filtered/rectified/smoothed audio
    audio_filt = filterRectifySmooth(audio, fs, f_low, f_high, audio_smoothing_window, filter_type);
    proc_data(c).audio_filt = audio_filt;

    % audio_filt_only: filtered audio
    audio_filt_only = arrayfun( ...
        @(i) pj_bandpass(audio(i,:),fs,f_low,f_high,filter_type), ...
        1:size(audio, 1), ...
        UniformOutput=false ...
        );
    audio_filt_only = cell2mat(audio_filt_only');
    proc_data(c).audio_filt_only = audio_filt_only;

    if ~isempty(options.ManualCallSegFilePath)
        call_onsets = manual_labels.onsets;
        call_offsets = manual_labels.offsets;
        proc_data(c).call_seg.noise_thresholds = inf * ones(size(call_onsets));
    else
        [proc_data(c).call_seg.noise_thresholds, ...
            call_onsets, ...
            call_offsets ...
            ] = segmentCalls(audio_filt, fs, min_int, min_dur, q, stim_i);
    end

    %--only take calls within desired window
    
    % check onsets/offsets individually
    i_on = cellfun(@(x) x >=post_stim_call_window_fr(1) & x<=post_stim_call_window_fr(2), call_onsets, 'UniformOutput',false);
    i_off = cellfun(@(x) x >=post_stim_call_window_fr(1) & x<=post_stim_call_window_fr(2), call_offsets, 'UniformOutput',false);

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
            @(tr) audio_filt(tr, proc_data(c).call_seg.onsets{tr}:proc_data(c).call_seg.offsets{tr}), ...
            proc_data(c).call_seg.one_call, ...
            'UniformOutput',false);

        proc_data(c).call_seg.audio_call = arrayfun( ...
            @(tr) audio(tr, proc_data(c).call_seg.onsets{tr}:proc_data(c).call_seg.offsets{tr}), ...
            proc_data(c).call_seg.one_call, ...
            'UniformOutput',false);

        proc_data(c).call_seg.acoustic_features = getAcousticFeatures( ...
            proc_data(c).call_seg.audio_call, fs);

        proc_data(c).call_seg.acoustic_features.latencies = arrayfun( ...
            @(tr) (call_onsets{tr} - stim_i) * 1000 / fs, ...
            proc_data(c).call_seg.one_call);
    else  % save empty so other code works
        proc_data(c).call_seg.acoustic_features = getAcousticFeatures( ...
            {}, fs);
        proc_data(c).call_seg.acoustic_features.latencies = [];
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
%   - q: noise_threshold = q * median(trial before stimulus). (scalar)
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


