%% group_plot_all_stims.m
% 2024.07.10 CDR
% 
% Plots summaries of insp/exp amplitude for ALL stims (rather than just
% call-evoking).
% 
% Needs struct `summary_bird` from `main.m`. Reloads saved data files 
% (call_breath_seg), so also requires that those datafiles are saved.
% 

set(groot, 'DefaultFigureVisible','off');  % suppress figures

if ~exist('group_figure_save_folder', 'var')
    group_figure_save_folder = '.';
    group_figure_save_format = 'svg';
end

%% new struct with only `keep_fields`
keep_fields = {'bird', 'data_file', 'group', 'n_stims'};
to_rm = fieldnames(summary_bird);
to_rm = to_rm(~ismember(to_rm, keep_fields));

summary_all_stims = rmfield(summary_bird, to_rm);
clear keep_fields to_rm

%% get distributions

for i_bird=1:length(summary_bird)
    load(summary_all_stims(i_bird).data_file)  % loads 'data' struct
    
    summary_all_stims(i_bird).no_calls = data.call_seg.no_calls;
    summary_all_stims(i_bird).one_call = data.call_seg.one_call;

    summary_all_stims(i_bird).exp_amplitude = [data.breath_seg.exp_amplitude];
    summary_all_stims(i_bird).insp_amplitude = [data.breath_seg.insp_amplitude];
    summary_all_stims(i_bird).latency_exp = [data.breath_seg.latency_exp];
    summary_all_stims(i_bird).latency_insp = [data.breath_seg.latency_insp];
end
clear i_bird bs

%% fields to plot & labels

fields_to_plot = {
    'insp_amplitude'
    'exp_amplitude'
    'latency_exp'
};

ylabels = {
    'Inspiratory amplitude (norm to pre)'
    'Expiratory amplitude (norm to pre)'
    'Latency to Expiration (ms)'
};


%% plot overlaid histograms AND group scatters (medians)

groups = {'dm', 'pam'};

plot_means = true;

ylims = {  % [-inf inf] for auto ylim
    [0 8]% 'insp_amplitude'
    [0 30]% 'exp_amplitude'
    [0 180]
};

for i_ftp = 1:length(fields_to_plot)
    
    field = fields_to_plot{i_ftp};
    
    hist_data = cell(size(groups));
    legend_labels = cell(size(groups));

    fig = figure;
    hold on;
    
    for i_gr = 1:length(groups)
        group = groups{i_gr};
        group_birds = summary_all_stims( strcmp({summary_all_stims.group}, group) );
        group_medians = cellfun(@median, {group_birds.(field)});
        
        % prep distrs for histogram
        hist_data{i_gr} = [group_birds.(field)]; 
        n_birds = length(group_birds);
        n_stims = length(hist_data{i_gr});
        legend_labels{i_gr} = append(group, ' (', string(n_stims), ' stims/', string(n_birds), ' birds)');

        if plot_means
            avg = mean(group_medians);
            sem = std(group_medians) / sqrt(length(group_medians) );
            errorbar(i_gr, avg, sem, Color='k', Marker='x', HandleVisibility='off');
        end

        scatter(i_gr * ones(size(group_medians)), group_medians, DisplayName=legend_labels{i_gr});
    end

    clear avg sem i_gr group group_birds group_medians
    hold off;

    xlim([0.75 length(groups)+.25])
    xticks(1:length(groups))
    xticklabels(groups)

    ylim(ylims{i_ftp})
    ylabel(ylabels{i_ftp});
    title(append(field, " - all stims"), Interpreter='none');
    legend(Location='best');

    fig_fname = fullfile(group_figure_save_folder, append('summary-ALL_STIM-', field, '.', group_figure_save_format));
    saveas(fig, fig_fname);

    % plot histogram
    fig = plotMultiHistogram(hist_data, LegendLabels=legend_labels, BinWidth=2, LegendAddNs=false);

    title(append(field, " - all stims"), Interpreter='none');
    xlabel(ylabels{i_ftp}); % i know, i know
    ylabel('Count')

    fig_fname = fullfile(group_figure_save_folder, append('hist-ALL_STIM-', field, '.', group_figure_save_format));
    saveas(fig, fig_fname);
end

clear i_ftp field fig fig_fname

%% Plot stacked histograms for all, 1call, no call.

n_calls_options = {"all_stims", "one_call", "no_calls"};

bin_widths = [
    0.5% 'insp_amplitude'
    0.5% 'exp_amplitude'
    2% 'latency_exp'
];

stacked_hist_save_folder = fullfile(group_figure_save_folder, "stacked_histograms");

for i_ftp = 1:length(fields_to_plot)
    field = fields_to_plot{i_ftp};
    
    this_folder = fullfile(stacked_hist_save_folder, field);
    mkdir(this_folder);

    for i_n_call = 1:length(n_calls_options)
        n_calls = n_calls_options{i_n_call};

        fig_fname = fullfile( ...
            this_folder, ...
            append('stacked_hist-', field, '-', n_calls, '.', group_figure_save_format) ...
            );

        fig = plotStackedHistogram(summary_all_stims, field, n_calls, BinWidth=bin_widths(i_ftp));
        fig.set("Position", [1 1 2560 1336]);  % make big
        saveas(fig, fig_fname);
        close(fig);
    end
end

clear i_ftp field fig fig_fname

set(groot, 'DefaultFigureVisible','on');  % suppress figures
