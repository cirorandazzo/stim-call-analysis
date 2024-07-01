%% run_pharamcology_analyses.m
% 2024.06.18 CDR
% 
% Plot histograms to compare conditions given "comparison direction" file.
% 

%% General
% save_root = "C:\Users\ciro\Documents\code\stim-call-analysis\data\figures\comparisons-svg";
save_root = "C:\Users\ciro\Desktop\temp";
fig_ext = ".svg";

% Load Comparison Directions

param_file_folder = "C:\Users\ciro\Documents\code\stim-call-analysis\pharmacology_analyses\comparison_directions";
parameter_files = dir( fullfile( param_file_folder, ['**' filesep '*.m']) );

current_dir = cd;

set(groot, 'DefaultFigureVisible', 'off')
distributions = [];
for pfile_i = length(parameter_files):-1:1

    [~, f, ~] = fileparts(parameter_files(pfile_i).name);  % param filename without extension
    disp(append( '%===========', f))

    cd(parameter_files(pfile_i).folder);
    eval(f);  % make parameter struct from .m file
    cd(current_dir);
    
    load(data_path)
    % save to 'comparisons' subfolder; useful if this is same dir as initial plots
    % save_prefix = fullfile(save_root, bird_name, 'comparisons');

    % save to bird_name folder; useful if folder only contains comparisons
    save_prefix = fullfile(save_root, bird_name);

    bird_distributions = run_comparisons(data_path, bird_name, comparisons, save_prefix, fig_ext);
    
    [bird_distributions.surgery_state] = deal(surgery_state);
    distributions = [distributions bird_distributions];

    clearvars -except save_root fig_ext parameter_files current_dir pfile_i distributions
end

distributions = orderfields(distributions, [7 9 8 1:6]);
save(fullfile(save_root, 'distributions.mat'), "distributions");

set(groot, 'DefaultFigureVisible', 'on');

%%

% drop abnormal comparisons
comparison_pattern = pattern("gabazine"|"muscimol");  % exact match for these
distributions = distributions(matches({distributions.comparison}, comparison_pattern));

% bird_cond = arrayfun(@(x) [string(x.bird_name); string(x.comparison)], distributions, UniformOutput=false);

bird_cond = string({distributions.bird_name; distributions.comparison});

[C, ~, ic] = unique(bird_cond', 'rows', 'stable');  % indices for unique conditions


%%
drug_pattern = comparison_pattern + wildcardPattern;  % looks for comparison pattern string with stuff after
bl_pattern = pattern("washout"|"baseline") + wildcardPattern;

%% Plot pre/post
% combines 

close all
normalize = false;

fields_to_plot = {
    'exp_latency'
    'insp_latency'
    'call_latency'
    'insp_amplitude'
    'audio_amplitude'
};

ylabels = {
    'Expiratory latency (s)'
    'Inspiratory latency (s)'
    'Audio-segmented call latency (s)'
    'Inspiratory amplitude'
    'Audio amplitude'
};

for i_ftp = 1:length(fields_to_plot)
    field_to_plot = fields_to_plot{i_ftp};

    fig = figure;
    hold on;
    
    in_legend = {};
    
    for cond = 1:size(C,1)
        this_bird = distributions(ic==cond);
    
        if length(this_bird) ~= 2
            error('Too many rows in this condition. Requires 2.')
        end
        
        comparison = this_bird(1).comparison;
        color = defaultPharmacologyColors(comparison);
        marker = getSurgeryStateMarker(this_bird(1).surgery_state);
        legend_name = append(comparison, '-', this_bird(1).surgery_state);
        
        i_bl = matches([this_bird.condition], bl_pattern, IgnoreCase=true);
        i_drug = matches([this_bird.condition], drug_pattern, IgnoreCase=true);
        
        data = {this_bird(i_bl).(field_to_plot) this_bird(i_drug).(field_to_plot)};
        data = cellfun(@median, data);

        if normalize
            data = (data - data(1)) / data(1);
        end

        line = plot(data, DisplayName=legend_name, Color=color, Marker=marker);
    
        if sum(strcmp(legend_name, in_legend)) > 0  
            set(line, 'HandleVisibility', 'off')
        else % first time seeing this
            in_legend = [in_legend legend_name];
        end
    end
    
    title(field_to_plot, Interpreter='None');

    xlim([.75 2.25])
    xticks([1 2])
    xticklabels(["baseline", "drug"])

    if normalize
        ylabel('Normalized change');
    else
        ylabel(ylabels{i_ftp});
    end

    legend(Location='northwest');
    hold off;

    fig_fname = fullfile(save_root, append(field_to_plot, '-pre_post_normd-', fig_ext));

    % saveas(fig, fig_fname)
end
%%

function distributions = run_comparisons(data_path, bird_name, comparisons, save_prefix, fig_ext)

    % load processed data
    load(data_path, 'data')
    
    % run each comparison
    figs = {};
    distributions = [];

    for i_comp = 1:length(comparisons)
        comparison = comparisons(i_comp).comparison;
        cut_data = data( comparisons(i_comp).ii_data );

        if ~isfield(comparisons(i_comp), 'colors') | isempty(comparisons(i_comp).colors)
            colors = arrayfun(@(x) defaultPharmacologyColors(x.drug), cut_data, UniformOutput=false);
        end

        [new_figs, new_distributions] = pharmacology_plot_pipeline(cut_data, bird_name, comparison, colors, SkipPlots=true, Verbose=true);
        figs = [figs new_figs];

        [new_distributions.bird_name] = deal(bird_name);
        [new_distributions.comparison] = deal(comparison);
        distributions = [distributions new_distributions];
    end
    
    % save all figures
    disp(append("Saving to: ", save_prefix))
    mkdir(save_prefix)
    for i_f = 1:length(figs)
        fig = figs{i_f};
        fname = append(fig.Name, fig_ext);
        savefile = fullfile(save_prefix, fname);
    
        disp(append("  - ", fname));
        saveas(fig, savefile);
    end
end


function [marker] = getSurgeryStateMarker(surgery_state)

    switch surgery_state

        case 'awake'
            marker = 'o';
        case 'anesthetized'
            marker = '+';
        otherwise
            warning(append('Unexpected surgery state, using marker x. (', surgery_state, ')'));
            marker = 'x';

    end

end