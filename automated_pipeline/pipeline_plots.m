function saved_figs = pipeline_plots(data, fs, stim_i, bird_name, save_prefix, options)
% pipeline_plots.m
% 2024.04.26 CDR (from dm_pam_checks.m, 2024.04.15)
% 
% This function generates and saves plots based on processed data for a single bird. Current options are:
%     - 'exp':    latency from stimulus to expiration (zero-crossing)
%     - 'aud':    latency from stimulus to audio-segmented call
%     - 'insp':   latency from stimulus to inspiration (derivative 
%                    thresholded)
%     - 'breath_trace':   plot all breath traces of one-call trials
%                               overlaid with average breath trace
%     - 'breath_trace_insp':  as above, but with green dots overlaid on
%                                   each breath trace to show computed 
%                                   inspiration
% 
%  NOTE: not currently implemented for multiple conditions; will throw error
% 
% INPUTS:
%     data:     A struct containing processed data, including 
%               breathing latencies, acoustic features, breath traces. If
%               struct has >1 row, recursively plots rows. 
%     fs:       Sampling frequency of the data.
%     stim_i:   Frame index of the stimulation in each trial (usually exact 
%               halfway point).
%     bird_name:    Name or identifier of the bird.
%     save_prefix:  Prefix (including savefolder) to use for saving the 
%                   generated plots. (eg, './figs/bird10-' for 
%                   './figs/bird10-plot_name.png')
%     options:      Optional arguments to customize the plots. It can have the
%                   following fields:
%           - BinWidthMs:   Width of bins for histograms. Default is 5ms
%           - BreathTraceWindowMs:  Window for plotting breath traces Default 
%                                   is [-100 200] ms, where 0 == stimulation 
%                                   onset.
%              - ImageExtension:    Extension for saving the images. Default is 
%                                   'svg'. No leading period!
%              - ToPlot:    Cell array of strings specifying which plots to 
%                           generate. See description at top for current 
%                           options. Default: all plots.

% OUTPUT:
%     saved_figs: A cell array containing filenames of the saved plots.


    arguments
        data {struct};
        fs {isnumeric};
        stim_i {isnumeric};
        bird_name;
        save_prefix;
        options.BinWidthMs = 5;
        options.BreathTraceWindowMs (2,1) {isnumeric} = [-100 200];
        options.ImageExtension = 'svg';
        options.ToPlot = {'exp', 'aud', 'insp', 'breath_trace', 'breath_trace_insp'};
        options.ConditionFields = {'drug', 'current'};
    end
    
    saved_figs = {};
    
    % With multiple conditions, recursively call pipeline_plots
    if length(data) > 1
        % error('Plotting data struct with multiple conditions is not implemented. As a workaround, you can iterate through each row of data struct and run pipeline_plots on each. Sorry about that!');
        
        for i_d = 1:length(data)
            condition_values = cellfun(@(x) data(i_d).(x), options.ConditionFields);
            condition_string = strjoin(condition_values, '_');

            sub_save_prefix = strcat(save_prefix, condition_string, '-');

            new_figs = pipeline_plots(data(i_d), ...
                fs, ...
                stim_i, ...
                strcat(bird_name, '-', condition_string), ...
                sub_save_prefix, ...
                BinWidthMs=options.BinWidthMs, ...
                BreathTraceWindowMs=options.BreathTraceWindowMs, ...
                ImageExtension=options.ImageExtension, ...
                ToPlot=options.ToPlot ...
             );
            saved_figs = [saved_figs, new_figs];
        end

        return
    end

    bin_width = options.BinWidthMs;
    img_ext = options.ImageExtension;
    to_plot = options.ToPlot;
    

    %% ALL STIM PLOTS

    % BREATH TRACES
    if ismember('breath_trace', to_plot)
        fig = figure;
        hold on;

        title_str = append(...
            bird_name,...
            ' breath traces, all stims (',...
            int2str(size(data.breathing_filt, 1)),...
            ')'...
            );

        title(title_str, 'interpreter', 'none');
        xlabel('Time since stim (ms)')
        ylabel('Pressure')
        
        rows_to_plot = data.breathing_filt;  % formerly data.breathing_filt(trs_one_call, :)
        x = f2ms(1:size(rows_to_plot, 2), fs, stim_i);
        
        plot(x, rows_to_plot', 'Color', '#c3c3c3', 'LineWidth', 0.5);  % transpose is very important, might crash computer otherwise :(
        plot(x, mean(rows_to_plot, 1), 'black', 'LineWidth', 4);

        l = min(rows_to_plot, [], 'all'); 
        h = max(rows_to_plot, [], 'all');
        
        plot([0 0], [l h], 'Color', 'black', 'LineStyle', '--')
        
        xlim(options.BreathTraceWindowMs);

        savefile = strcat(save_prefix, ['breathTraces.' img_ext]);
        saved_figs{end+1} = savefile;
        saveas(fig, savefile);

        hold off;
        close;
    end

    %% ONE CALL PLOTS
    trs_one_call = data.call_seg.one_call;
    
    if isempty(trs_one_call)
        warning('No one-call trials found for this bird/condition.')
        return
    end

    bird_name = convertStringsToChars(bird_name);

    % EXPIRATORY LATENCY
    if ismember('exp', to_plot)
        exp_latencies = [data.breath_seg.latency_exp];
        exp_latencies = exp_latencies(trs_one_call);
        
        fig = histogram(exp_latencies, 'BinWidth', bin_width);
        title([bird_name ' expiratory latency (' int2str(length(exp_latencies)) ')'], 'interpreter', 'none');
        xlabel("Latency to Expiration (ms)");
        ylabel("Count");

        savefile = strcat(save_prefix, ['expHist.' img_ext]);
        saved_figs{end+1} = savefile;
        saveas(fig, savefile);
        close;
    end

    % INSPIRATORY LATENCY
    if ismember('insp', to_plot)

        insp_latencies = [data.breath_seg.latency_insp];
        insp_latencies = insp_latencies(trs_one_call);

        fig = histogram(insp_latencies, 'BinWidth', bin_width);
        title([bird_name ' inspiratory latency (' int2str(length(insp_latencies)) ')'], 'interpreter', 'none');
        xlabel("Latency to Inspiration (ms)");
        ylabel("Count");

        savefile = strcat(save_prefix, ['inspHist.' img_ext]);
        saved_figs{end+1} = savefile;
        saveas(fig, savefile);
        close;
    end

    % AUDIO-SEGMENTED CALL LATENCY
    if ismember('aud', to_plot)
        call_latencies = [data.call_seg.acoustic_features.latencies];

        fig = histogram(call_latencies, 'BinWidth', bin_width);
        title([bird_name ' audio latency (' int2str(length(trs_one_call)) ')'], 'interpreter', 'none');
        xlabel("Latency to Call (ms)");
        ylabel("Count");
        % xlim([40 180]);

        savefile = strcat(save_prefix, ['audHist.' img_ext]);
        saved_figs{end+1} = savefile;
        saveas(fig, savefile);
        close;
    end

    % BREATH TRACES WITH INSPS MARKED
    if ismember('breath_trace_insp', to_plot)
        fig = figure;
        hold on;

        title([bird_name ' breath traces (' int2str(length(trs_one_call)) ')'], 'interpreter', 'none');
        xlabel('Time since stim (ms)')
        ylabel('Pressure')
        
        rows_to_plot = data.breathing_filt(trs_one_call, :);
        x = f2ms(1:size(rows_to_plot, 2), fs, stim_i);
        
        plot(x, rows_to_plot', 'Color', '#c3c3c3', 'LineWidth', 0.5);  % transpose is very important, might crash computer otherwise :(
        plot(x, mean(rows_to_plot, 1), 'black', 'LineWidth', 4);
        
        insp_latencies = [data.breath_seg.latency_insp];
        insp_latencies = insp_latencies(trs_one_call);

        latency_insp_f = [data.breath_seg.latency_insp_f];
        latency_insp_f = latency_insp_f(trs_one_call);

        ys = arrayfun(@(j) rows_to_plot(j, stim_i+latency_insp_f(j)), 1:numel(trs_one_call));

        scatter(insp_latencies, ys, 'green', 'filled');

        l = min(rows_to_plot, [], 'all'); 
        h = max(rows_to_plot, [], 'all');
        
        plot([0 0], [l h], 'Color', 'black', 'LineStyle', '--')
        
        xlim(options.BreathTraceWindowMs);  

        savefile = strcat(save_prefix, ['breathTracesInsp.' img_ext]);
        saved_figs{end+1} = savefile;
        saveas(fig, savefile);

        hold off;
        close;
    end
end

function ms = f2ms(f, fs, stim_i)
    ms = minus(f, stim_i) * 1000 / fs;
end