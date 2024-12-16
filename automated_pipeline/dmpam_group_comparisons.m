%% dmpam_group_comparisons.m
% 2024.08.06 CDR
% 
% Group plots and statistics for dm/pam stim experiments without
% pharmacology.
% 
% Requires summary struct output of main processing pipeline (in `main.m`)

% where/how to save group summary figures
group_figure_save_folder = './data/figures/summary';
group_figure_save_format = 'svg';

plot_scatter_means = true;  % for scatter plots of medians, overlay group means +/- SEM

to_exclude_from_group_plot = {   % rejects from summary_bird before running group analyses
    % stim noise in audio channel - RESOLVED WITH MANUAL LABELS 2024.12
    ...% 'pu81bk43'
    ...% '080720'
};

mkdir(group_figure_save_folder)

%% GROUP PLOT ALL STIMS
disp('Plotting amplitude summaries for ALL stims (ie, not just call-evoking stims)')
if ~isempty(to_exclude_from_group_plot)
    warning('Birds in `to_exclude_from_group_plot` are not excluded from these plots!')
end

group_plot_all_stims;

%% CONSTRUCT GROUP STRUCT

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

%% COMBINED HISTOGRAMS    

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

% Expiratory latencies
fig_group_exp = make_group_histogram( ...
    summary_group, ...
    'exp_latencies', ...
    BinWidth=2, ...
    Normalization='probability' ...
);

title('Stim-induced expiration latency');
xlabel('Latency to expiration (ms)');
ylabel('Probability');
saveas(fig_group_exp, [group_figure_save_folder '/group-exp_latency'], group_figure_save_format);


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
% xlim([0 180]);
saveas(fig_group_audio, [group_figure_save_folder '/group-audio_latency'], group_figure_save_format);

%% SCATTER PLOTS: MEDIANS

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
        
        if plot_scatter_means
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