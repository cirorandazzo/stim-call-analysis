% pipeline.m
% formerly call_vicinity_pipeline.m
% 2024.02.12 CDR
% 
% pipeline for audio data processing

%% PARAMETERS
% all processing parameters saved in one big struct (`p`) for ease of
% saving/loading parameters
%
% load from a parameter file separately. eg, run `bu69bu75`

set(groot, 'DefaultFigureVisible','off');  % suppress figures

%% STEP 1: load intan data

if verbose 
    disp('Loading raw data...');
    timeS1 = tic;
end

if mat_file
    load(p.files.raw_data, 'dataMat');

    % rename for consistency
    unproc_data = dataMat;
    clear dataMat;

    unproc_data = renameStructField(unproc_data, 'audio', 'sound');
    unproc_data.fs = p.fs;

    parameter_names = [];

    if verbose 
        toc(timeS1);
        disp('Loaded!');
    end

else  % directory of intan files
    if ~isfield(p.files, 'parameter_names')
        % assume format curr_freq_len_sth_sth.rhs -- eg '20uA_100Hz_50ms_230725_143022.rhs'
        p.files.parameter_names = {"current", "frequency", "length", [], []};
    end
       
    parameter_names = p.files.parameter_names;

    unproc_data = s1_load_raw(p.files.raw_data, parameter_names);

    save_path = p.files.save.unproc_save_file;
    save_files_pipeline(save_path, unproc_data, p.files.delete_fields);

    if verbose 
        toc(timeS1);
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
    timeS2 = tic;
end

proc_data = s2_restructure( ...
    unproc_data, ...
    deq_br, ...
    parameter_names, ...
    p.window.radius_seconds, ...
    p.window.stim_cooldown...
);

clear unproc_data;
save_path = p.files.save.proc_save_file; 
save_files_pipeline(save_path, proc_data, p.files.delete_fields);

if verbose 
    toc(timeS2);
    disp(['Restructured! Saved to: ' savepath newline]);
end

%% STEP 3: segment calls.
% filter/smooth happens here too

if verbose 
    disp('Segmenting calls...');
    timeS3 = tic;
end

call_seg_data = s3_segment_calls( ...
    proc_data, ...
    p.fs, ...
    p.audio_filt_smooth.f_low, ...
    p.audio_filt_smooth.f_high, ...
    p.audio_filt_smooth.smooth_window_ms, ...
    p.audio_filt_smooth.filt_type, ...
    p.call_seg.min_interval_ms, ...
    p.call_seg.min_duration_ms, ...
    p.call_seg.q, ...
    p.window.stim_i, ...
    p.call_seg.post_stim_call_window_ii ...
);

clear proc_data;
save_path = p.files.save.call_seg_save_file;
save_files_pipeline(save_path, call_seg_data, p.files.delete_fields);

if verbose
    toc(timeS3);
    disp(['Segmented calls! Saved to: ' save_path newline]);
end

% see b_segment_calls.m for code to plot spectrograms for subset of trials
% (eg, where no call is found)


%% STEP 4: segment breaths

if verbose 
    disp('Segmenting breaths...');
    timeS4 = tic;
end

call_breath_seg_data = s4_segment_breaths( ...
    call_seg_data, ...
    p.fs, ...
    p.window.stim_i, ...
    p.breath_seg.min_duration_fr, ...
    p.breath_seg.exp_thresh, ...
    p.breath_seg.insp_thresh, ...
    p.breath_seg.stim_window.pre_stim_ms, ...
    p.breath_seg.stim_window.post_stim_ms, ...
    p.breath_seg.derivative_smooth_window_ms, ...
    p.breath_seg.stim_induced_insp_window_ms ...
);

clear call_seg_data;
save_path = p.files.save.call_breath_seg_save_file;
save_files_pipeline(save_path, call_breath_seg_data, p.files.delete_fields);

if verbose 
    toc(timeS4);
    disp(['Segmented breaths! Saved to: ' save_path newline]);
end


%% RENAME FINAL STRUCT

data = call_breath_seg_data;
clear call_breath_seg_data;

%% PLOT FIGURES

if verbose 
    disp('Plotting...');
    timePlot = tic;
end

saved_figs = pipeline_plots( ...
    data, ...
    p.fs, ...
    p.window.stim_i, ...
    p.files.bird_name, ...
    p.files.save.figure_prefix, ...
    'BinWidthMs', 5, ...
    'BreathTraceWindowMs', [-100 200], ...
    'ImageExtension', p.files.save.fig_extension, ...
    'ToPlot', p.files.to_plot ...
);

if verbose 
    toc(timePlot);
    disp(['Finished plotting! Saved figures:']);
    for fig_i=1:length(saved_figs)
        disp( "  -"  + string(saved_figs{fig_i}) );
    end
end

set(groot, 'DefaultFigureVisible','on');  % un-suppress figures

%% SAVE BREATHING & AUDIO
if ~isempty(p.files.save.breathing_audio_save_file)
    to_keep = {'breathing', 'breathing_filt', 'audio', 'audio_filt'};
    
    fields = fieldnames(data); 
    to_rm = fields(~ismember(fields, to_keep));

    breathing_audio_data = rmfield(data, to_rm);

    save(p.files.save.breathing_audio_save_file, "breathing_audio_data");
end

%% SAVE PARAMETERS

if ~isempty(p.files.save.parameter_save_file)
    save(p.files.save.parameter_save_file, 'p');

    if verbose 
        disp(['Parameters saved to: ' p.files.save.save_prefix '_parameters.mat' newline]);
    end
end