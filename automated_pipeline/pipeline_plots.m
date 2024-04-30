function saved_figs = pipeline_plots(data, fs, stim_i, bird_name, save_prefix, options)
% 2024.04.26 CDR from dm_pam_checks.m (2024.04.15)
% 
% TODO update pipeline_plots readme
% given processed data structure for a single bird, plot stuff.

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
    end

    saved_figs = {};

    bin_width = options.BinWidthMs;
    img_ext = options.ImageExtension;
    to_plot = options.ToPlot;
    
    trs_one_call = data.call_seg.one_call;

    % EXPIRATORY LATENCY
    if ismember('exp', to_plot)
        exp_latencies = [data.breath_seg.latency_exp];
        exp_latencies = exp_latencies(trs_one_call);
        
        fig = histogram(exp_latencies, 'BinWidth', bin_width);
        title([bird_name ' expiratory latency (' int2str(length(exp_latencies)) ' calls)']);
        xlabel("Latency to Expiration (ms)");
        ylabel("Count");

        savefile = [save_prefix 'expHist.' img_ext];
        saved_figs{end+1} = savefile;
        saveas(fig, savefile);
        close;
    end

    % INSPIRATORY LATENCY
    if ismember('insp', to_plot)

        insp_latencies = [data.breath_seg.latency_insp];
        insp_latencies = insp_latencies(trs_one_call);

        fig = histogram(insp_latencies, 'BinWidth', bin_width);
        title([bird_name ' inspiratory latency (' int2str(length(insp_latencies)) ' calls)']);
        xlabel("Latency to Inspiration (ms)");
        ylabel("Count");

        savefile = [save_prefix 'inspHist.' img_ext];
        saved_figs{end+1} = savefile;
        saveas(fig, savefile);
        close;
    end

    % AUDIO-SEGMENTED CALL LATENCY
    if ismember('aud', to_plot)
        call_latencies = [data.call_seg.acoustic_features.latencies{:}];

        fig = histogram(call_latencies, 'BinWidth', bin_width);
        title([bird_name ' audio latency (' int2str(length(trs_one_call)) ')']);
        xlabel("Latency to Call (ms)");
        ylabel("Count");
        % xlim([40 180]);

        savefile = [save_prefix 'audHist.' img_ext];
        saved_figs{end+1} = savefile;
        saveas(fig, savefile);
        close;
    end

    % BREATH TRACES
    if ismember('breath_trace', to_plot)
        fig = figure;
        hold on;

        title([bird_name ' breath traces (' int2str(length(trs_one_call)) ')']);
        xlabel('Time since stim (ms)')
        ylabel('Pressure')
        
        rows_to_plot = data.breathing_filt(trs_one_call, :);
        x = f2ms(1:size(rows_to_plot, 2), fs, stim_i);
        
        plot(x, rows_to_plot', 'Color', '#c3c3c3', 'LineWidth', 0.5);  % transpose is very important, might crash computer otherwise :(
        plot(x, mean(rows_to_plot, 1), 'black', 'LineWidth', 4);

        l = min(rows_to_plot, [], 'all'); 
        h = max(rows_to_plot, [], 'all');
        
        plot([0 0], [l h], 'Color', 'black', 'LineStyle', '--')
        
        xlim(options.BreathTraceWindowMs);

        savefile = [save_prefix 'breathTraces.' img_ext];
        saved_figs{end+1} = savefile;
        saveas(fig, savefile);

        hold off;
        close;
    end

    % BREATH TRACES WITH INSPS MARKED
    if ismember('breath_trace_insp', to_plot)
        fig = figure;
        hold on;

        title([bird_name ' breath traces (' int2str(length(trs_one_call)) ')']);
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

        savefile = [save_prefix 'breathTracesInsp.' img_ext];
        saved_figs{end+1} = savefile;
        saveas(fig, savefile);

        hold off;
        close;
    end
end

function ms = f2ms(f, fs, stim_i)
    ms = minus(f, stim_i) * 1000 / fs;
end