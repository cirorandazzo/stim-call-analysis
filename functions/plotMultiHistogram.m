function fig = plotMultiHistogram(data, options)
% plotMultiHistogram.m
% 2024.06.18 CDR
% 
% Plot overlapping histogram from data struct.
% 
% TODO: documentation

    arguments
        data {iscell};
        options.BinWidth = 5;
        options.Colors = [];
        options.LegendLabels = [];
        options.LegendAddNs = true;
    end

    fig = figure;
    
    % set plot colors
    if ~isempty(options.Colors)
        assert(length(options.Colors)==length(data), "Wrong number of colors provided!");
        colororder(fig, options.Colors);
    end

    % plot
    hold on;
    for i_c = 1:length(data)

        histogram(data{i_c}, ...
           BinWidth=options.BinWidth, FaceAlpha=0.5, EdgeAlpha=1, EdgeColor='auto' ...  % plotting options
           ); 
    end
    hold off;

    % make legend
    if ~isempty(options.LegendLabels)
        assert(length(options.LegendLabels) == length(data))

        labels = options.LegendLabels;

        if options.LegendAddNs
            labels = arrayfun(@(i_c) append(labels{i_c}, " (", string(length(data{i_c})), ")"), [1:length(labels)]);
        end

        legend(labels);
    end
end