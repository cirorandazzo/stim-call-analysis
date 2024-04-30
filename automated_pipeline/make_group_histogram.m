function fig = make_group_histogram(summary_group, field_to_plot, options)
% make_group_histogram.m
% 2024.04.30 CDR
% 
% TODO: make_group_histogram documentation

    arguments
        summary_group {struct};
        field_to_plot {string};
        options.BinWidth {isnumeric} = [];
        options.Normalization {string} = "probability";
    end

    fig = figure;
    hold on;
    
    legend_labels = {[1 length(summary_group)]};

    for i=1:length(summary_group)
        group = summary_group(i).group;
        n_calls = summary_group(i).n_calls;
        n_birds = summary_group(i).n_birds;
    
        legend_labels{i} = group + " (" + n_calls + " calls / " + n_birds + " birds)";
        
        % plot
        histogram( ...
            summary_group(i).(field_to_plot), ...
            'BinWidth', options.BinWidth, ...
            'Normalization', options.Normalization ...
        );
    end

    legend(legend_labels);

    hold off;
end