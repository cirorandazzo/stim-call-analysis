% main.m
% 2024.02.14 CDR
% 
% Batch run processing pipeline in `pipeline.m` on all parameter files in 
% param_file_folder (excluding files in cell `to_exclude`). Saves 
% individual data and plots as specified by each parameter file.
% 
% Individual data is saved & cleared, but `summary_bird`struct is kept for
% dm/pam experiments; keep `summary_bird` in the workspace to run
% `dmpam_group_comparisons`. This struct is empty for pharmacology experiments.
% 
% If `only_these` is not empty, will exclude all non-matched parameter 
% files.

clear;

%% OPTIONS

% analyze from all parameter files in this folder
param_file_folder = 'C:\Users\ciro\Documents\code\stim-call-analysis\parameters\hvc_pharmacology';  
% param_file_folder = 'C:\Users\ciro\Documents\code\stim-call-analysis\parameters\dm_pam';  
parameter_files = dir([param_file_folder filesep '**' filesep '*.m'] );

% whether to plot individual figures
do_plots = true;

% inclusions/exclusions
to_exclude_from_analysis = {... % .m files to exclude from param folder
    'default_params.m', ... ignore default parameter file
    % 'bird_080720.m', 'pu81bk43.m' ... stim noise in audio channel
    }; 
    
only_these = {};  % only analyze with these parameter files, excluding all others. make sure to include `.m`
% only_these = {'pu65bk36.m', 'bk68wh15.m', 'bu69bu75.m'}; 

% print outputs during run
verbose = true;

% if true, looks for already processed data + parameter file at 
%   p.files.save.(x), where x = call_breath_seg_save_file or
%   parameter_save_file. Errors if datafile not found.
suppress_reprocess = false;

% if true, merges files that have same listed parameters. else, maintains
% filename as a parameter, so s2 doesn't merge RHS files
merge_files = true;

%% RUN

start_all = tic;
current_dir = cd;
run_dt = datetime;

if ~isempty(only_these)
    parameter_files(~ismember({parameter_files.name}, only_these)) = [];
end

parameter_files(ismember({parameter_files.name}, to_exclude_from_analysis)) = [];  % exclude files from to_exclude

summary_bird = [];
summary_bird.bird = [];
summary_bird.data_file = [];
summary_bird.param_file = [];
summary_bird.group = [];
summary_bird.n_stims = [];
summary_bird.n_one_call = [];
summary_bird.n_no_calls = [];
summary_bird.n_multi_calls = [];

%% Main Processing Pipeline
% - works by loading parameter struct `p` & running `pipeline.m`
% - saves data to files listed in p

for pfile_i = length(parameter_files):-1:1

    [~, f, ~] = fileparts(parameter_files(pfile_i).name);  % param filename without extension

    cd(parameter_files(pfile_i).folder);
    eval(f);  % make parameter struct from .m file
    cd(current_dir);

    summary_bird(pfile_i).bird = p.files.bird_name;
    summary_bird(pfile_i).param_file = fullfile(parameter_files(pfile_i).folder, parameter_files(pfile_i).name);
    summary_bird(pfile_i).group = p.files.group;
    
    p.run_dt = run_dt;

    assert(~isempty(strfind(p.files.raw_data, p.files.bird_name)));  % ensure birdname is in raw data filename
    
    mkdir(p.files.save_folder);

    if ~isempty(p.files.to_plot) && do_plots
        mkdir(p.files.figure_folder)
    end
    
    try
        disp(['%=====Running ' f '...'])
        timeTotal = tic;

        pipeline;  % run pipeline for this bird
        
        % print saved files
        disp('Success! Saved files:');
        fields = fieldnames(p.files.save);
        for j=1:length(fields)
            filename = p.files.save.(fields{j});
            if ~isempty(filename)
                disp(['  - ' fields{j} ': ' filename]);
            end
        end

        summary_bird(pfile_i).data_file = p.files.save.call_breath_seg_save_file;


        if length(data) == 1  % not multiple conditions for this bird
            % store summary data
            n_stims = size(data.breath_seg, 1);
            summary_bird(pfile_i).n_stims = n_stims;
    
            % summary data about audio segmentation
            n_one_call = size(data.call_seg.one_call, 1);
            n_multi_call = size(data.call_seg.multi_calls, 1);

            summary_bird(pfile_i).n_one_call = n_one_call;
            summary_bird(pfile_i).n_no_calls = size(data.call_seg.no_calls, 1);
            summary_bird(pfile_i).n_multi_calls = n_multi_call;

            summary_bird(pfile_i).call_success_rate = (n_one_call + n_multi_call) / n_stims;
    
            % summary data about inspiratory latency
            insp_latencies = [data.breath_seg(data.call_seg.one_call).latency_insp];
    
            summary_bird(pfile_i).min_insp_lat = min(insp_latencies);
            summary_bird(pfile_i).max_insp_lat = max(insp_latencies);
            summary_bird(pfile_i).median_insp_lat = median(insp_latencies);

            % save copy of breathing distributions
            summary_bird(pfile_i).insp_latencies = insp_latencies;
            summary_bird(pfile_i).exp_latencies = [data.breath_seg(data.call_seg.one_call).latency_exp];

            summary_bird(pfile_i).insp_amplitude = [data.breath_seg(data.call_seg.one_call).insp_amplitude];
            summary_bird(pfile_i).exp_amplitude = [data.breath_seg(data.call_seg.one_call).exp_amplitude];

            % save copy of audio distributions
            summary_bird(pfile_i).audio_latencies = [data.call_seg.acoustic_features.latencies]';
            summary_bird(pfile_i).audio_amplitudes = [data.call_seg.acoustic_features.max_amp_filt]';

            summary_bird(pfile_i).error = 0;  % everything worked!
        else
            % don't throw error for failure to summarize multiple
            % conditions. not worth the log.
            % TODO: implement summary for bird with multiple conditions
            summary_bird(pfile_i).error = "Summary for bird with multiple conditions is not yet implemented.";
            disp(summary_bird(pfile_i).error);
        end

    catch err
        summary_bird(pfile_i).error = err;  % error :(
        
        log_file = [p.files.save.save_prefix '_ERROR_LOG.txt'];
        disp(['Error. See log: ' log_file])

        fid = fopen(log_file, 'w');

        % print error to file
        fprintf(fid, '%s', err.getReport('extended', 'hyperlinks','off'));

        % close file
        fclose(fid);

    end

    disp('Total time for this bird:')
    toc(timeTotal);
    
    disp(['%=====Finished ' f '!'])
    disp('  ');  % newline between birds

    clearvars -except ...
        a current_dir do_plots i main_save_file merge_files ...
        parameter_files run_dt start_all summary_bird ...
        suppress_reprocess verbose;

end

disp("Finished processing from " + string(length(parameter_files)) + " param files!")
toc(start_all);
disp("- See var `summary_bird` for quick view of individual summary data.")
disp("- To get group plots/stats:")
disp("    - DM/PAm data: run `dmpam_group_comparisons.m` WITHOUT CLEARING var `summary_bird`!")
disp("    - Pharmacology data: run `run_pharmacology_analyses.m`")
disp("- Run `./automated_pipeline/batch_plot_spectrograms.m to plot spectrograms with call onsets/offsets.")

save(main_save_file, "do_plots", "merge_files", "parameter_files", "run_dt", "summary_bird", "suppress_reprocess", '-v7.3');
