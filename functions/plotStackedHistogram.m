function f = plotStackedHistogram(summary_all_stims, field_to_plot, trial_type, options)
% plotStackedHistogram
% Given struct summary_all_stims, plots a stacked histograms for a series
% of birds, for a specified field & trial type (eg, "one_call").
% 
% Inputs:
%   summary_all_stims - A structure array where each element contains
%                       summary data for a bird, including the number
%                       of stimulations, trial types, and other related fields.
%   field_to_plot     - A string specifying the field to plot. This field
%                       should exist within each bird's summary structure.
%   trial_type        - A string specifying the trial type. This could be
%                       "all_stims" to include all stimulations or any 
%                       specific trial type defined in the structure.
% 
% Outputs:
%   f                 - A handle to the figure containing the stacked histograms.

    arguments
        summary_all_stims;
        field_to_plot;
        trial_type;
        options.BinWidth = 2;
    end

    % Get the number of birds (i.e., number of summary entries)
    n_birds = length(summary_all_stims);
    
    % Initialize axes array for each subplot
    axs = zeros([1, n_birds]);
    
    f = figure;

    % Loop through each bird to generate individual histograms
    for i_b = 1:n_birds
        % Create a subplot for each bird
        axs(i_b) = subplot(n_birds, 1, i_b);
        
        % Extract relevant information for the current bird
        bird = summary_all_stims(i_b).bird;
        group = summary_all_stims(i_b).group;
        
        % Get the color for this group (using a predefined function)
        c = defaultDMPAMColors(group);
        
        % Determine which trials to include based on the 'trial_type'
        if strcmp(trial_type, "all_stims")
            % If 'trial_type' is "all_stims", include all stimulations
            ii_trial = 1 : summary_all_stims(i_b).n_stims;
        else
            % Otherwise, select trials based on the specific trial type
            ii_trial = summary_all_stims(i_b).(trial_type);
        end
        
        % Calculate the number of selected trials and the total number of stimulations
        n_calls = length(ii_trial);
        n_stims = summary_all_stims(i_b).n_stims;
        
        % Generate the title for the current subplot
        t = sprintf('%s (%s | %d / %d stim trials)', bird, group, n_calls, n_stims);
        
        % Extract the data to plot for the specified field
        distr = summary_all_stims(i_b).(field_to_plot)(ii_trial);
        
        % Plot the histogram for the current bird's data
        histogram( ...
            distr, ...            % Data to plot
            'BinWidth', options.BinWidth, ...    % Set the bin width for the histogram
            'FaceColor', c ...    % Set the face color for the histogram
            );
        
        % Set the title and label for the y-axis
        title(t);
        ylabel("Count");
    end
    
    % Link the x-axes of all subplots to synchronize their zooming/panning
    linkaxes(axs, 'x');
    
    % Add a super title for the entire figure indicating the field and trial type
    sgtitle(append(field_to_plot, " - ", trial_type), 'Interpreter', 'None');
end
