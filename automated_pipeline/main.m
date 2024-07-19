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
% param_file_folder = 'C:\Users\ciro\Documents\code\stim-call-analysis\parameters\dm_pam';  
parameter_files = dir([param_file_folder filesep '**' filesep '*.m'] );

% whether to plot individual figures
do_plots = true;

% where/how to save group summary figures
do_group_plots = true;
group_figure_save_folder = './data/figures';
group_figure_save_format = 'svg';

% inclusions/exclusions
to_exclude_from_analysis = {... % .m files to exclude from param folder
    'default_params.m', ... ignore default parameter file
    % 'bird_080720.m', 'pu81bk43.m' ... stim noise in audio channel
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
            do_group_plots = false;
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

    clearvars -except a current_dir group_figure_save_folder group_figure_save_format i parameter_files run_dt summary_bird verbose do_group_plots do_plots;

end

disp("Finished processing from " + string(length(parameter_files)) + " param files!")
disp("See var `summary_bird` for quick view of individual summary data.")
disp("Run `./automated_pipeline/batch_plot_spectrograms.m to plot spectrograms with call onsets/offsets.")


%% Group Summaries

to_exclude_from_group_plot = {   % rejects from summary_bird before running group analyses
    '080720', 'pu81bk43' ... stim noise in audio channel
};

if do_group_plots  % note: automatically set to false if any data structs have >1 row

    % GROUP PLOT ALL STIMS
    disp('Plotting amplitude summaries for ALL stims (ie, not just call-evoking stims)')
    if ~isempty(to_exclude_from_group_plot)
        warning('Birds in `to_exclude_from_group_plot` are not excluded from these plots!')
    end

    group_plot_all_stims;

    % CONSTRUCT GROUP STRUCT

    % exclude requested birds
    if ~isempty(to_exclude_from_group_plot)
        ii_exclude = ismember({summary_bird.bird}, to_exclude_from_group_plot);
        
        summary_bird_exclusions = summary_bird(ii_exclude);  % save rejects separately
        summary_bird(ii_exclude) = [];  % then delete
    end
    
    summary_group = make_group_summaries(summary_bird);
    disp("See var `summary_group` for quick view of group summary data.")
    
    % PLOTS
    disp("Plotting group summary figures...")

    % COMBINED HISTOGRAMS    

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

    

    % SCATTER PLOTS: MEDIANS
    
    plot_means = true;  % overlay group means +/- SEM

    % TODO: change fieldnames of summary struct for consistency with
    % run_pharmacology_analyses
    % 
    % fields_to_plot = {
    %     'exp_latency'
    %     'insp_latency'
    %     'call_latency'
    %     'insp_amplitude'
    %     'audio_amplitude'
    % };
    
    fields_to_plot = {
        'exp_latencies'
        'insp_latencies'
        'audio_latencies'
        'insp_amplitude'
        'exp_amplitude'
        'audio_amplitudes'
        'call_success_rate'
    };
    
    ylabels = {
        'Expiratory latency (s)'
        'Inspiratory latency (s)'
        'Audio-segmented call latency (s)'
        'Inspiratory amplitude (norm to pre)'
        'Expiratory amplitude (norm to pre)'
        'Audio amplitude'
        'Evoked call success rate (% of stimulations)'
    };

    ylims = {  % [-inf inf] for auto ylim
        [0 120]% 'exp_latencies'
        [0 90]% 'insp_latencies'
        [0 120]% 'audio_latencies'
        [0 7]% 'insp_amplitude'
        [0 17]% 'exp_amplitude'
        [0 4e-4]% 'audio_amplitudes'
        [0 1]% 'call_success_rate'
    };
    
    groups = {'dm', 'pam'};
    
    for i_ftp = 1:length(fields_to_plot)
        
        field = fields_to_plot{i_ftp};
        
        fig = figure;
        hold on;
        for i_gr = 1:length(groups)
            group = groups{i_gr};
            group_birds = summary_bird( strcmp({summary_bird.group}, group) );
            group_medians = cellfun(@median, {group_birds.(field)});
            
            if plot_means
                avg = mean(group_medians);
                sem = std(group_medians) / sqrt(length(group_medians) );
                errorbar(i_gr, avg, sem, Color='k', Marker='x', HandleVisibility='off');
            end

            scatter(i_gr * ones(size(group_medians)), group_medians, DisplayName=group);
        end

        clear avg sem i_gr group group_birds group_medians
        hold off;

        xlim([0.75 length(groups)+.25])
        xticks(1:length(groups))
        xticklabels(groups)
    
        ylim(ylims{i_ftp})
        ylabel(ylabels{i_ftp});
        title(field, Interpreter='none');
        legend(Location='best');

        fig_fname = fullfile(group_figure_save_folder, append('summary-', field, '.', group_figure_save_format));
        saveas(fig, fig_fname);
    end

    clear i_ftp field fig fig_fname
end

%% group comparison statistics

all_stim_fields = [
    "exp_amplitude"
    "insp_amplitude"
    "latency_exp"
    ];

call_only_fields = [
  "call_success_rate"
  "median_insp_lat"
];

[p_vals_all_stims, stats_all_stims, distrs_all_stims] = get_stats_dm_pam(summary_all_stims, all_stim_fields);
[p_vals_calls, stats_calls, distrs_calls] = get_stats_dm_pam(summary_bird, call_only_fields);

fname=fullfile(group_figure_save_folder, 'dmpam-summaries_stats.mat');
        
save(fname, ...
    ...STAT STRUCTS
    'p_vals_all_stims', 'stats_all_stims', 'distrs_all_stims', ...
    'p_vals_calls', 'stats_calls', 'distrs_calls', ...
    ...AND SUMMARY STRUCTS
    'summary_group', 'summary_all_stims', 'summary_bird', ...
    'summary_bird_exclusions'...
    );
