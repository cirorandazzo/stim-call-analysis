% pipeline.m
% formerly call_vicinity_pipeline.m
% 2024.02.12 CDR
% 
% Main pipeline for data processing of a single bird. See README in parent 
% folder for description of the pipeline.
% 
% For batch processing, `pipeline.m` is called by `main.m`
% 
% Requires external loading of a parameter struct `p`. (see `./parameters`)

%% PARAMETERS
% all processing parameters saved in one big struct (`p`) for ease of
% saving/loading parameters
%
% load from a parameter file separately. eg, run `bu69bu75`

set(groot, 'DefaultFigureVisible','off');  % suppress figures

if ~exist("verbose", "var")
    verbose=true;
end

if ~exist("do_plots", "var")
    do_plots=true;
end

if ~suppress_reprocess
%% STEP 1: load intan data

if verbose 
    disp('Loading raw data...');
    timeS1 = tic;
end

[root, name, ext] = fileparts(p.files.raw_data);

if isempty(ext)  % DIRECTORY, read all .rhs files
    file_list = dir(fullfile(p.files.raw_data, ['**' filesep '*.rhs']));  % get all intan rhs files
    
    if ~isfield(p.files, 'labels')
        % format curr_freq_len_sth_sth.rhs -- eg '20uA_100Hz_50ms_230725_143022.rhs'
        % p.files.labels = {"current", "frequency", "length", [], []};
        p.files.labels = {}; % CDR 2024.06.04 - don't presume labels if not given.
    end

    [unproc_data, parameter_names] = s1_load_raw(file_list, filename_labels=p.files.labels);

elseif strcmpi(ext, '.csv')  % .csv batch specifying parameters & rhs folder names
    opts = detectImportOptions( ...
        p.files.raw_data, ...
        'VariableNamesLine',1, ...
        'Delimiter', {','}...
    );
    opts = setvartype(opts, opts.VariableNames, 'char');  
    opts = setvaropts(opts, 'FillValue', '');

    files = table2struct(readtable(p.files.raw_data, opts));
    assert(~isempty(files));

    [unproc_data, parameter_names] = s1_load_raw(files, file_list_type='csv_batch');

elseif strcmpi(ext, '.mat')  % preprocessed .mat file 
    load(p.files.raw_data, 'dataMat');

    % rename for consistency
    unproc_data = dataMat;
    clear dataMat;

    if isfield(p.files, 'labels')
        parameter_names = p.files.labels;
    else
        parameter_names = {};
    end
    unproc_data = renameStructField(unproc_data, 'audio', 'sound');
    unproc_data.fs = p.fs;

else   % error
    error(['Unknown raw file type: ' ext])
end

save_path = p.files.save.unproc_save_file;
save_files_pipeline(save_path, unproc_data, p.files.delete_fields);

if verbose 
    toc(timeS1);
    disp(['Loaded! Saved to: ' save_path newline]);
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
    p.breath_seg.derivative_smooth_window_f, ...
    p.breath_seg.stim_induced_insp_window_ms, ...
    p.call_seg.post_stim_call_window_ii...
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

%% SAVE BREATHING & AUDIO
if ~isempty(p.files.save.breathing_audio_save_file)
    to_keep = {
        'audio', 'audio_filt'...  % audio stuff
        'breathing', 'breathing_filt', 'breathing_centered'...  % breathing stuff
        'surgery_condition', 'drug'...  % pharmacology parameters
        };
    if ismember('breathing_centered', to_keep)
        centered = arrayfun( ...
            @(x) vertcat(x.breath_seg.centered), ...
            data, ...
            UniformOutput=false ...
            );
    end

    fields = fieldnames(data); 
    to_rm = fields(~ismember(fields, to_keep));

    breathing_audio_data = rmfield(data, to_rm);
    [breathing_audio_data.breathing_centered] = centered{:};

    [breathing_audio_data.stim_i] = deal(p.window.stim_i);
    [breathing_audio_data.fs] = deal(p.fs);
    

    save(p.files.save.breathing_audio_save_file, "breathing_audio_data");
    clear breathing_audio_data centered;
end

%% SAVE PARAMETERS

if ~isempty(p.files.save.parameter_save_file)
    save(p.files.save.parameter_save_file, 'p');

    if verbose 
        disp(['Parameters saved to: ' p.files.save.save_prefix '_parameters.mat' newline]);
    end
end

else % load data instead of reprocessing

    if verbose
        disp('suppress_reprocess==true! Loading already processed files...')
        disp(append('Parameter file: ', p.files.save.parameter_save_file))
    end
    load(p.files.save.parameter_save_file, 'p');  % load original parameter file

    % overwrite original parameter on what to plot
    % p.files.to_plot = {'exp', 'aud', 'insp', 'breath_trace', 'breath_trace_insp'};

    if verbose
        disp(append('Processed data file: ', p.files.save.call_breath_seg_save_file))
    end
    load(p.files.save.call_breath_seg_save_file, 'data');

end
%% PLOT FIGURES

if do_plots

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

end

