%% pharmacology_plot_pipeline.m
% 2024.06.18 CDR
% 
% Analyses for pharmacology data
% 

function [figs, distributions] = pharmacology_plot_pipeline(cut_data, bird_name, comparison, colors, options)
    
    arguments
        cut_data;
        bird_name;
        comparison;
        colors;
        options.SkipPlots (1,1) {islogical} = false;  % skip plotting, just want distributions
        options.Verbose (1,1) {islogical} = false;
    end

    figs = {};
    
    conditions = arrayfun(@(x) strcat(x.drug, '-', x.current, 'uA'), cut_data, UniformOutput=false);
    ii_trs = arrayfun(@(x) x.call_seg.one_call, cut_data, UniformOutput=false);
    
    %% TODO
    % overlaid resp waveforms?
    
    %%
    if options.Verbose 
        disp('Getting distributions...') 
    end

    all_stims = arrayfun( ...
        @make_all_stims_struct,...
        cut_data, ...
        UniformOutput=false ...
        );

    % prep call counts
    n_calls = arrayfun( ...
        @(i_c) size(cut_data(i_c).audio,1), ...
        [1:length(cut_data)] ...
        ,UniformOutput=false ...
        );

    n_no_calls = arrayfun( ...
        @(i_c) size(cut_data(i_c).call_seg.no_calls,1), ...
        [1:length(cut_data)] ...
        ,UniformOutput=false ...
        );

    n_one_call = arrayfun( ...
        @(i_c) size(cut_data(i_c).call_seg.one_call,1), ...
        [1:length(cut_data)] ...
        ,UniformOutput=false ...
        );

    n_multi_calls = arrayfun( ...
        @(i_c) size(cut_data(i_c).call_seg.multi_calls,1), ...
        [1:length(cut_data)] ...
        ,UniformOutput=false ...
        );

    call_success_rate = arrayfun( ...
        @(i_c) (n_one_call{i_c} + n_multi_calls{i_c}) / n_calls{i_c}, ...
        [1:length(cut_data)] ...
        ,UniformOutput=false ...
        );

    % prep latency structs 
    exp_latencies = arrayfun( ...
        @(i_c) index([cut_data(i_c).breath_seg.latency_exp], ii_trs{i_c}), ...
        [1:length(cut_data)], ...
        UniformOutput=false ...
        );

    insp_latencies = arrayfun( ...
        @(i_c) [cut_data(i_c).breath_seg.latency_insp], ...
        [1:length(cut_data)], ...
        UniformOutput=false ...
        );

    call_latencies = arrayfun( ...
        @(i_c) [cut_data(i_c).call_seg.acoustic_features.latencies],...
        [1:length(cut_data)], ...
        UniformOutput=false ...
        );

    
    % prep amplitude structs

    % absolute value of inspiratory amplitude based on centered breath waveform
    insp_amplitudes = arrayfun( ...
        @(i_c) abs([cut_data(i_c).breath_seg.insp_amplitude]),...
        [1:length(cut_data)], ...
        UniformOutput=false ...
        );

    % expiratory amplitude based on centered breath waveform
    exp_amplitudes = arrayfun( ...
        @(i_c) abs([cut_data(i_c).breath_seg.exp_amplitude]),...
        [1:length(cut_data)], ...
        UniformOutput=false ...
        );

    % maximum amplitude of audio_filt
    audio_amplitudes = arrayfun( ...
        @(i_c) abs([cut_data(i_c).call_seg.acoustic_features.max_amp_filt]),...
        [1:length(cut_data)], ...
        UniformOutput=false ...
        );

    %% make & return struct with these distributions

    distributions = struct( ...
        'call_success_rate', call_success_rate,...
        'n_calls', n_calls,...
        'n_no_calls', n_no_calls,...
        'n_one_call', n_one_call,...
        'n_multi_calls', n_multi_calls,...
        'condition', conditions, ...
        'exp_latency', exp_latencies, ...
        'insp_latency', insp_latencies,...
        'call_latency', call_latencies, ...
        'insp_amplitude', insp_amplitudes,...
        'exp_amplitude', exp_amplitudes,...
        'audio_amplitude', audio_amplitudes,...
        'all_stims', all_stims...
        );

    if options.SkipPlots
        disp('SkipPlots option enabled, not plotting distributions.')
        return
    end

    if options.Verbose 
        disp('Plotting...') 
    end

    %% insp vs exp amplitude

    xs = cellfun(@(row) row.insp_amplitude, all_stims, UniformOutput=false);
    ys = cellfun(@(row) row.exp_amplitude, all_stims, UniformOutput=false);
    
    fig = figure;
    colororder(fig, colors);

    hold on;
    for i=1:length(xs)
        scatter(xs{i}, ys{i});
    end
    hold off

    legend(...  % with n's per condition
        arrayfun(@(i_c) append(conditions{i_c}, " (", string(length(xs{i_c})), ")"), [1:length(conditions)])...
        , location='best' ...
        , interpreter='none')

    title([bird_name ' insp vs exp amplitude'], 'interpreter', 'none');
    xlabel('Insp amplitude (normalized)')
    ylabel('Exp amplitude (normalized)')

    fig.Name = append(bird_name, "-", comparison, "-insp_vs_exp");
    figs{end+1} = fig;


    %% exp latency
    fig = plotMultiHistogram(exp_latencies, BinWidth=5, Colors=colors, LegendLabels=conditions);
    
    title([bird_name ' expiratory latency'], 'interpreter', 'none');    
    xlabel("Latency to Expiration (ms)");
    ylabel("Count");
    
    % xlim([0 80])
    
    fig.Name = append(bird_name, "-", comparison, "-exp_latency");
    figs{end+1} = fig;
    
    %% insp latency
    fig = plotMultiHistogram(insp_latencies, BinWidth=1, Colors=colors, LegendLabels=conditions);
    
    title([bird_name ' inspiration latency'], 'interpreter', 'none');    
    xlabel("Latency to Inspiration (ms)");
    ylabel("Count");
    
    fig.Name = append(bird_name, "-", comparison, "-insp_latency");
    figs{end+1} = fig;
    
    %% auditory latency        
    fig = plotMultiHistogram(call_latencies, BinWidth=5, Colors=colors, LegendLabels=conditions);
    
    title([bird_name ' call latency (audio segmented)'], 'interpreter', 'none');    
    xlabel("Latency to Call (ms)");
    ylabel("Count");
    
    % xlim([0 80])
    
    fig.Name = append(bird_name, "-", comparison, "-aud_latency");
    figs{end+1} = fig;
    
    
    %% insp amplitude
    fig = plotMultiHistogram(insp_amplitudes, BinWidth=.04, Colors=colors, LegendLabels=conditions);
    
    title([bird_name ' inspiratory amplitude'], 'interpreter', 'none');    
    xlabel("Inspiratory Amplitude");
    ylabel("Count");
    
    fig.Name = append(bird_name, "-", comparison, "-insp_amp");
    figs{end+1} = fig;

    
    %% exp amplitude
    fig = plotMultiHistogram(exp_amplitudes, BinWidth=.04, Colors=colors, LegendLabels=conditions);
    
    title([bird_name ' expiratory amplitude'], 'interpreter', 'none');    
    xlabel("Expiratory Amplitude");
    ylabel("Count");
    
    fig.Name = append(bird_name, "-", comparison, "-exp_amp");
    figs{end+1} = fig;
    
    
    %% audio amplitude
    
    fig = plotMultiHistogram(audio_amplitudes, BinWidth=1e-4, Colors=colors, LegendLabels=conditions);
    
    title([bird_name ' audio amplitude'], 'interpreter', 'none');    
    xlabel("Audio Amplitude");
    ylabel("Count");
    
    fig.Name = append(bird_name, "-", comparison, "-aud_amp");
    figs{end+1} = fig;


    %% respiratory rate

    respiratory_rate = cellfun(@(row) row.respiratory_rate, all_stims, UniformOutput=false);

    fig = plotMultiHistogram(respiratory_rate, BinWidth=.1, Colors=colors, LegendLabels=conditions);
    
    title([bird_name ' pre-stim respiratory rate (all trials)'], 'interpreter', 'none');    
    xlabel("Respiratory rate (Hz)");
    ylabel("Count");
    % 
    % hold on;
    % for i=1:length(respiratory_rate)
    %     plot()
    % end

    fig.Name = append(bird_name, "-", comparison, "-respiratory_rate");
    figs{end+1} = fig;


    %% respiratory rate - timeseries
    fig=figure;
    hold on
    for i=1:length(conditions)
        plot(respiratory_rate{i}, Color=colors{i}, DisplayName=conditions{i});
    end
    
    ylabel('Respiratory Rate (Hz)')
    xlabel('Stim #')
    title([bird_name ' pre-stim respiratory rate by trial'], 'interpreter', 'none')
    
    legend;
    hold off;

    fig.Name = append(bird_name, "-", comparison, "-TIME-respiratory_rate");
    figs{end+1} = fig;

    %% insp ampltiude - timeseries
    fig=figure;
    hold on
    for i=1:length(conditions)
        plot(insp_amplitudes{i}, Color=colors{i}, DisplayName=conditions{i});
    end
    
    ylabel('Inspiratory amplitude')
    xlabel('Stim #')
    title([bird_name ' inspiratory amplitude by trial'], 'interpreter', 'none')
    
    legend;
    hold off;
    
    fig.Name = append(bird_name, "-", comparison, "-TIME-insp_amp");
    figs{end+1} = fig;
    
    %% exp ampltiude - timeseries
    fig=figure;
    hold on
    for i=1:length(conditions)
        plot(exp_amplitudes{i}, Color=colors{i}, DisplayName=conditions{i});
    end
    
    ylabel('Expiratory amplitude')
    xlabel('Stim #')
    title([bird_name ' expiratory amplitude by trial'], 'interpreter', 'none')
    
    legend;
    hold off;
    
    fig.Name = append(bird_name, "-", comparison, "-TIME-exp_amp");
    figs{end+1} = fig;
    

    %% inspiratory amplitude success rate

    % for each condition: parallel arrays where first column is
    % insp_amplitude for every trial, second column is whether that stim
    % evoked a call

    insp_amp_success = arrayfun( ...
        @(i_c) ...
        {all_stims{i_c}.insp_amplitude' ...
         ~cellfun(@isempty, cut_data(i_c).call_seg.onsets) ...
        } ...
        , ...
        [1:length(cut_data)], ...
        UniformOutput=false ...
    );

    fig = figure;
    fig.Name = append(bird_name, "-", comparison, "-insp_call_success");
    fig.Position(4) = fig.Position(4)*2;

    for i_c = 1:length(cut_data)

        ias = insp_amp_success{i_c};
        [counts, edges, ii] = histcounts(ias{1}, BinWidth=.5);
    
        success_all = ias{2};
    
        success = zeros(size(counts));
        
        for i_bar=1:length(success)
            these_trials = success_all(ii==i_bar);
    
            if isempty(these_trials)
                success(i_bar) = 0;
            else
                success(i_bar) = sum(these_trials) / length(these_trials);
            end
        end

        fa = 0.5;
        ea = 1;
        c = colors{i_c};

        subplot(2,1,1);
        hold on;
        histogram(BinCounts=success, BinEdges=edges, FaceAlpha=fa, EdgeAlpha=ea, EdgeColor=c, FaceColor=c);
        hold off;

        subplot(2,1,2);
        hold on;
        histogram(BinCounts=counts,  BinEdges=edges, FaceAlpha=fa, EdgeAlpha=ea, EdgeColor=c, FaceColor=c);
        hold off;

    end

    ax1 = subplot(2,1,1);
    title('Call success by inspiratory amplitude (all stims)');
    ylabel('Call success rate')

    ax2 = subplot(2,1,2);
    xlabel('Inspiratory amplitude (normalized)')
    ylabel('Count');

    labels = conditions;
    labels = arrayfun( ...
        @(i_c) append(conditions{i_c}, " (", string(size(insp_amp_success{i_c}{1}, 1)), ")"), ...
        [1:length(labels)] ...
        );

    legend(labels);

    linkaxes([ax1,ax2], 'x');


    figs{end+1} = fig;
    
end

%%

function all_stims = make_all_stims_struct(data)
    all_stims.exp_amplitude = [data.breath_seg.exp_amplitude];
    all_stims.insp_amplitude = [data.breath_seg.insp_amplitude];
    all_stims.latency_exp = [data.breath_seg.latency_exp];
    all_stims.respiratory_rate = [data.breath_seg.respiratory_rate];
end

function indexed = index(a, inds)
% dummy function to enable array creation & indexing in one line
    indexed = a(inds);
end