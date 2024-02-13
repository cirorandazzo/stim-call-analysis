function [call_seg_data] = s3_segment_calls( ...
    proc_data, save_file, fs, f_low, f_high, sm_window, filter_type, ...
    min_int, min_dur, q, stim_i, post_stim_call_window)
% S3_SEGMENT_CALLS
% 2024.02.12 CDR from b_segment_calls
% 
% - filter, rectify, smooth audio data
% - segment calls
% - get spectral features of processed data

tic;

for c=length(proc_data):-1:1  % for each condition
    a = proc_data(c).audio;
    
    audio_filt = filt_rec_smooth(a, fs, f_low, f_high, sm_window, filter_type);

    [proc_data(c).noise_thresholds, ...
        onsets, ...
        offsets ...
        ] = segment_calls(audio_filt, fs, min_int, min_dur, q, stim_i);

    %--only take calls within desired window
    
    % check onsets/onsets individually
    i_on = cellfun(@(x) x >=post_stim_call_window(1) & x<=post_stim_call_window(2), onsets, 'UniformOutput',false);
    i_off = cellfun(@(x) x >=post_stim_call_window(1) & x<=post_stim_call_window(2), offsets, 'UniformOutput',false);

    % ensure both onset/offset are within that window
    i_good = arrayfun(@(i) {i_on{i} & i_off{i}}, 1:size(i_on,1));

    % delete remainder & save
    onsets = arrayfun(@(i)  onsets{i}(i_good{i}), 1:size(i_on,1), 'UniformOutput',false)';
    offsets = arrayfun(@(i) offsets{i}(i_good{i}), 1:size(i_on,1), 'UniformOutput',false)';

    proc_data(c).audio_filt = audio_filt;

    proc_data(c).call_seg.onsets = onsets;
    proc_data(c).call_seg.offsets = offsets;

    %--count # of calls in each trial
    % Helps determine if audio segmentation was successful
    proc_data(c).call_seg.no_calls = find(cellfun(@isempty, onsets));  % NO CALLS FOUND
    proc_data(c).call_seg.one_call = find(cellfun(@(x) length(x)==1, onsets)); % EXACTLY 1 CALL
    proc_data(c).call_seg.multi_calls = find(cellfun(@(x) length(x)>1, onsets));  % >1 CALL

    % For trials with EXACTLY ONE call, cut call audio & save 
    if ~isempty(proc_data(c).call_seg.one_call)
        proc_data(c).call_seg.audio_filt_call = arrayfun( ...
            @(tr) audio_filt(tr, proc_data(c).call_seg.onsets{tr}:proc_data(c).call_seg.offsets{tr}), ...
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

toc;
%% SAVE

save(save_file, 'call_seg_data')


end

