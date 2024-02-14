%% main.m
% 2024.02.12 CDR
% 
% pipeline for audio data processing

clear;

%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters
%
% load from a parameter file separately. eg, run `bu69bu75`
% 


%% STEP 1: load intan data

if verbose 
    disp('Loading raw data...');
    tic
end

if mat_file
    load(p.files.raw_data, 'dataMat');

    % rename for consistency
    unproc_data = dataMat;
    clear dataMat;

    unproc_data = renameStructField(unproc_data, 'audio', 'sound');
    unproc_data.fs = p.fs;

    if verbose 
        toc
        disp('Loaded!');
    end

else  % directory of intan files
    unproc_data = s1_load_raw(p.files.raw_data, unproc_save_file);

    if verbose 
        toc
        disp(['Loaded! Saved to: ' unproc_save_file newline]);
    end

end

%% create breathing filter

deq_br = designfilt(...
    p.filt_breath.type,...
    'FilterOrder', p.filt_breath.FilterOrder,...
    'PassbandFrequency', p.filt_breath.PassbandFrequency,...
    'StopbandFrequency', p.filt_breath.StopbandFrequency,...
    'SampleRate', p.fs ...
);

%% STEP 2: restructure data, filter breathing

if verbose 
    disp('Restructuring data...');
    tic
end

proc_data = s2_restructure( ...
    unproc_data, ...
    proc_save_file, ...
    deq_br, ...
    p.files.labels, ...
    p.window.radius, ...
    p.breath_time.insp_dur_max, ...
    p.breath_time.exp_delay, ...
    p.breath_time.exp_dur_max ...
);

if verbose 
    toc
    disp(['Restructured! Saved to: ' proc_save_file newline]);
end

%% STEP 3: segment calls.
% filter/smooth happens here too

if verbose 
    disp('Segmenting calls...');
end

call_seg_data = s3_segment_calls( ...
    proc_data, ...
    call_seg_save_file,...
    p.fs, ...
    p.filt_smooth.f_low, ...
    p.filt_smooth.f_high, ...
    p.filt_smooth.sm_window, ...
    p.filt_smooth.filt_type, ...
    p.call_seg.min_int, ...
    p.call_seg.min_dur, ...
    p.call_seg.q, ...
    p.window.stim_i, ...
    p.breath_time.post_stim_call_window ...
);

if verbose 
    disp(['Segmented calls! Saved to: ' call_seg_save_file newline]);
end

% see b_segment_calls.m for code to plot spectrograms for subset of trials
% (eg, where no call is found)


%% STEP 4: segment breaths

if verbose 
    disp('Segmenting breaths...');
end

call_breath_seg_data = s4_segment_breaths( ...
    call_seg_data, ...
    call_breath_seg_save_file, ...
    p.fs, ...
    p.window.stim_i, ...
    p.breath_seg.dur_thresh, ...
    p.breath_seg.exp_thresh, ...
    p.breath_seg.insp_thresh, ...
    p.breath_seg.pre_delay, ...
    p.breath_seg.post_delay ...
);

if verbose 
    disp(['Segmented breaths! Saved to: ' call_breath_seg_save_file newline]);
end


%% STEP 5: call vicinity analysis
% TODO: what do breaths look like directly before/after call?

if verbose 
    disp('Computing breaths around calls...');
end

call_vicinity_data = s5_call_vicinity( ...
    call_breath_seg_data, ...
    vicinity_save_file, ...
    p.fs, ...
    p.window.stim_i, ...
    p.call_vicinity.post_window ...
);

if verbose 
    disp(['Vicinity analysis complete! Saved to: ' vicinity_save_file newline]);
end

%% SAVE PARAMETERS

save([save_prefix '_parameters.mat'], 'p');

if verbose 
    disp(['Parameters saved to: ' save_prefix '_parameters.mat' newline]);
end
