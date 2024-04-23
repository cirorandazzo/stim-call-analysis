% call_vicinity_pipeline.m
% (formerly main.m)
% 2024.02.12 CDR
% 
% pipeline for audio data processing

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

    labels = [];

    if verbose 
        toc
        disp('Loaded!');
    end

else  % directory of intan files
    if ~isfield(p.files, 'labels')
        % format curr_freq_len_sth_sth.rhs -- eg '20uA_100Hz_50ms_230725_143022.rhs'
        p.files.labels = {"current", "frequency", "length", [], []};
    end
       
    labels = p.files.labels;

    unproc_data = s1_load_raw(p.files.raw_data, labels);

    save_path = p.files.save.unproc_save_file;
    save_files_pipeline(save_path, unproc_data, p.files.delete_fields);

    if verbose 
        toc;
        disp(['Loaded! Saved to: ' save_path newline]);
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

%% STEP 2: restructure data, filter  breathing

if verbose 
    disp('Restructuring data...');
    tic
end

proc_data = s2_restructure( ...
    unproc_data, ...
    deq_br, ...
    labels, ...
    p.window.radius, ...
    p.breath_time.insp_dur_max, ...
    p.breath_time.exp_delay, ...
    p.breath_time.exp_dur_max, ...
    p.window.stim_cooldown...
);


save_path = p.files.save.proc_save_file; 
save_files_pipeline(save_path, proc_data, p.files.delete_fields);

if verbose 
    toc
    disp(['Restructured! Saved to: ' savepath newline]);
end

%% STEP 3: segment calls.
% filter/smooth happens here too

if verbose 
    disp('Segmenting calls...');
    tic
end

call_seg_data = s3_segment_calls( ...
    proc_data, ...
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

save_path = p.files.save.call_seg_save_file;
save_files_pipeline(save_path, call_seg_data, p.files.delete_fields);

if verbose
    toc
    disp(['Segmented calls! Saved to: ' save_path newline]);
end

% see b_segment_calls.m for code to plot spectrograms for subset of trials
% (eg, where no call is found)


%% STEP 4: segment breaths

if verbose 
    disp('Segmenting breaths...');
    tic
end

call_breath_seg_data = s4_segment_breaths( ...
    call_seg_data, ...
    p.fs, ...
    p.window.stim_i, ...
    p.breath_seg.dur_thresh, ...
    p.breath_seg.exp_thresh, ...
    p.breath_seg.insp_thresh, ...
    p.breath_seg.pre_delay, ...
    p.breath_seg.post_delay, ...
    p.breath_seg.der_smooth_window, ...
    p.breath_seg.insp_window ...
);

save_path = p.files.save.call_breath_seg_save_file;
save_files_pipeline(save_path, call_breath_seg_data, p.files.delete_fields);


if verbose 
    toc
    disp(['Segmented breaths! Saved to: ' save_path newline]);
end


%% STEP 5: call vicinity analysis

if verbose 
    disp('Computing breaths around calls...');
    tic
end

call_vicinity_data = s5_call_vicinity( ...
    call_breath_seg_data, ...
    p.fs, ...
    p.window.stim_i, ...
    p.call_vicinity.post_window ...
);

save_path = p.files.save.vicinity_save_file;
save_files_pipeline(save_path, call_vicinity_data, p.files.delete_fields);


if verbose 
    toc
    disp(['Vicinity analysis complete! Saved to: ' p.files.save.vicinity_save_file newline]);
end


%% SAVE BREATHING & AUDIO
if ~isempty(p.files.save.breathing_audio_save_file)


    to_keep = {'breathing', 'breathing_filt', 'audio', 'audio_filt', 'noise_thresholds'};
    
    f = fieldnames(call_vicinity_data); 
    to_rm = f(~ismember(f, to_keep));

    data = rmfield(call_vicinity_data, to_rm);

    save(p.files.save.breathing_audio_save_file, "data");
end

%% SAVE PARAMETERS

if ~isempty(p.files.save.parameter_save_file)
    save(p.files.save.parameter_save_file, 'p');

    if verbose 
        disp(['Parameters saved to: ' p.files.save.save_prefix '_parameters.mat' newline]);
    end
end