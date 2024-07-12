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
    fig = plotMultiHistogram(insp_amplitudes, BinWidth=.04, Colors=colors, LegendLabels=conditions);
    
    title([bird_name ' expiratory amplitude'], 'interpreter', 'none');    
    xlabel("Inspiratory Amplitude");
    ylabel("Count");
    
    fig.Name = append(bird_name, "-", comparison, "-insp_amp");
    figs{end+1} = fig;
    
    
    %% audio amplitude
    
    fig = plotMultiHistogram(audio_amplitudes, BinWidth=1e-4, Colors=colors, LegendLabels=conditions);
    
    title([bird_name ' audio amplitude'], 'interpreter', 'none');    
    xlabel("Audio Amplitude");
    ylabel("Count");
    
    fig.Name = append(bird_name, "-", comparison, "-aud_amp");
    figs{end+1} = fig;

    
end

%%

function all_stims = make_all_stims_struct(data)
    all_stims.exp_amplitude = [data.breath_seg.exp_amplitude];
    all_stims.insp_amplitude = [data.breath_seg.insp_amplitude];
    all_stims.latency_exp = [data.breath_seg.latency_exp];
end

function indexed = index(a, inds)
% dummy function to enable array creation & indexing in one line
    indexed = a(inds);
end