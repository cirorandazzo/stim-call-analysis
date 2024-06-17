% main.m
% 2024.02.14 CDR
% 
% Batch run processing pipeline in `pipeline.m` on all parameter files in param_file_folder (excluding files in cell `to_exclude`). Saves individual data and plots as specified by each parameter file. Also saves group summary plots if `do_group_plots` is true.
% 
% Individual data is saved & cleared, but summary structs (`summary_bird` by bird, `summary_group` by group) are kept.
% 
% If `only_these` is not empty, will exclude all non-matched parameter files.

clear;

%% OPTIONS

% analyze from all parameter files in this folder
param_file_folder = 'C:\Users\ciro\Documents\code\stim-call-analysis\parameters\hvc_pharmacology';  
parameter_files = dir([param_file_folder filesep '**' filesep '*.m'] );

% where/how to save group summary figures
do_group_plots = false;
group_figure_save_folder = './data/figures';
group_figure_save_format = 'png';

% inclusions/exclusions
to_exclude = {... % .m files to exclude from param folder
    'default_params.m', ... ignore default parameter file
    'bu26bu73.m', ... bu26bu73 has 2 channels which means diff data structure
    'bird_080720.m', 'pu81bk43.m' ... stim noise in audio channel
    }; 
    
only_these = {};  % only analyze with these parameter files, excluding all others. make sure to include `.m`
% only_these = {'bk68wh15.m'};
% only_these = {'pu65bk36.m', 'bk68wh15.m', 'bu69bu75.m'}; 

% print outputs during run
verbose = true;

%% RUN

current_dir = cd;
run_dt = datetime;

if ~isempty(only_these)
    parameter_files(~ismember({parameter_files.name}, only_these)) = [];
end

parameter_files(ismember({parameter_files.name}, to_exclude)) = [];  % exclude files from to_exclude

summary_bird = [];
summary_bird.bird = [];
summary_bird.file = [];
summary_bird.group = [];
summary_bird.n_rows = [];
summary_bird.n_one_call = [];
summary_bird.n_no_calls = [];
summary_bird.n_multi_calls = [];

%% Main Processing Pipeline
% - works by loading parameter struct `p` & running `call_pipeline.m`
% - saves data to files listed in p

for pfile_i = length(parameter_files):-1:1

    [~, f, ~] = fileparts(parameter_files(pfile_i).name);  % param filename without extension

    cd(parameter_files(pfile_i).folder);
    eval(f);  % make parameter struct from .m file
    cd(current_dir);

    summary_bird(pfile_i).bird = p.files.bird_name;
    summary_bird(pfile_i).file = [parameter_files(pfile_i).folder filesep parameter_files(pfile_i).name];
    summary_bird(pfile_i).group = p.files.group;
    
    p.run_dt = run_dt;

    assert(~isempty(strfind(p.files.raw_data, p.files.bird_name)));  % ensure birdname is in raw data filename

    mkdir(p.files.save_folder);

    if ~isempty(p.files.to_plot)
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


        if length(data) == 1
            % store summary data
            summary_bird(pfile_i).n_rows = size(data.breath_seg, 1);
    
            % summary data about audio segmentation
            summary_bird(pfile_i).n_one_call = size(data.call_seg.one_call, 1);
            summary_bird(pfile_i).n_no_calls = size(data.call_seg.no_calls, 1);
            summary_bird(pfile_i).n_multi_calls = size(data.call_seg.multi_calls, 1);
    
            % summary data about inspiratory latency
            insp_latencies = [data.breath_seg.latency_insp];
            insp_latencies = insp_latencies(data.call_seg.one_call);
    
            summary_bird(pfile_i).min_insp_lat = min(insp_latencies);
            summary_bird(pfile_i).max_insp_lat = max(insp_latencies);
            summary_bird(pfile_i).median_insp_lat = median(insp_latencies);
    
            % save copy of insp & audio-seg call latencies
            summary_bird(pfile_i).insp_latencies = insp_latencies;
            summary_bird(pfile_i).audio_latencies = [data.call_seg.acoustic_features.latencies{:}];
    
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

    clearvars -except a current_dir group_figure_save_folder group_figure_save_format i parameter_files run_dt summary_bird verbose do_group_plots;

end

disp("Finished processing from " + string(length(parameter_files)) + " param files!")
disp("See var `summary_bird` for quick view of individual summary data.")
disp("Run `./automated_pipeline/batch_plot_spectrograms.m to plot spectrograms with call onsets/offsets.")


%% Group Summaries

if do_group_plots
    summary_group = make_group_summaries(summary_bird);
    disp("See var `summary_group` for quick view of group summary data.")
    
    disp("Plotting group summary figures...")

    % Inspiratory latencies
    fig_group_insp = make_group_histogram( ...
        summary_group, ...
        'insp_latencies', ...
        BinWidth=2, ...
        Normalization='probability' ...
    );

    title('Stim-induced inspiration latency');
    xlabel('Latency to inspiration (ms)');
    ylabel('Probability');
    saveas(fig_group_insp, [group_figure_save_folder '/group-insp_latency'], group_figure_save_format);


    % Audio-segmented call latencies
    fig_group_audio = make_group_histogram( ...
        summary_group, ...
        'audio_latencies', ...
        BinWidth=2, ...
        Normalization='probability' ...
    );

    title('Audio-thresholded call latency');
    xlabel('Latency to call (ms)');
    ylabel('Probability');
    xlim([0 180]);
    saveas(fig_group_audio, [group_figure_save_folder '/group-audio_latency'], group_figure_save_format);
end
