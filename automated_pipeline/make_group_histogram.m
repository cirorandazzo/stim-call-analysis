function fig = make_group_histogram(summary_group, field_to_plot, options)
% make_group_histogram.m
% 2024.04.30 CDR
% 
% Given struct containing summary of each group's data (output of
% `make_group_summaries`), this function plots the distribution of the provided
% field for each group (on the same plot). 
% 
% INPUTS:
%     summary_group:    A structure array containing summary data for different
%                       groups. Each element of the array should have the
%                       following fields:
%           - group:    Group name or identifier.
%           - n_calls:  Number of one-call trials associated with 
%                           the group. (ie, exactly 1 call found by audio
%                           segmentation in entire cut trial (stimulus +/- 
%                           window))
%           - n_birds:  Number of birds associated with the group.

%     field_to_plot:    The name of the field within the summary_group structure
%                       that contains the data to plot.

%     options:  Optional arguments to customize the plot
%           - BinWidth: Width of the bins for histogram binning. Default is
%                           2 (units=provided field units).
%           - Normalization: Type of normalization for the histogram (see
%                           options for matlab's histogram functipon). Default
%                           is "probability".
% 
% OUTPUT:
%     fig: Handle to the generated histogram.
% 

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