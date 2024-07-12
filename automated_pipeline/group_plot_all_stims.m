%% group_plot_all_stims.m
% 2024.07.10 CDR
% 
% Plots summaries of insp/exp amplitude for ALL stims (rather than just
% call-evoking).
% 
% Needs struct `summary_bird` from `main.m`. Reloads saved data files 
% (call_breath_seg), so also requires that those datafiles are saved.
% 

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

%% get medians

for i_bird=1:length(summary_bird)
    load(summary_all_stims(i_bird).data_file)  % loads 'data' struct
    
    summary_all_stims(i_bird).exp_amplitude = median([data.breath_seg.exp_amplitude]);
    summary_all_stims(i_bird).insp_amplitude = median([data.breath_seg.insp_amplitude]);
    summary_all_stims(i_bird).latency_exp = median([data.breath_seg.latency_exp]);
end
clear i_bird bs

%% plot

plot_means = true;

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

ylims = {  % [-inf inf] for auto ylim
    [0 8]% 'insp_amplitude'
    [0 30]% 'exp_amplitude'
    [0 180]
};
    
    groups = {'dm', 'pam'};
    
    for i_ftp = 1:length(fields_to_plot)
        
        field = fields_to_plot{i_ftp};
        
        fig = figure;
        hold on;
        for i_gr = 1:length(groups)
            group = groups{i_gr};
            group_birds = summary_all_stims( strcmp({summary_all_stims.group}, group) );
            group_medians = [group_birds.(field)];
            
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
        title(append(field, " - all stims"), Interpreter='none');
        legend(Location='best');

        fig_fname = fullfile(group_figure_save_folder, append('summary-ALL_STIM-', field, '.', group_figure_save_format));
        saveas(fig, fig_fname);
    end

clear i_ftp field fig fig_fname

