function [unproc_data] = s1_load_raw(data_dir, filename_param_labels)
% S1_LOAD_RAW
% 2024.02.12 CDR from script a1_load_raw_files
% 
% Load all Intan RHS files from a directory.
% 
% PARAMETERS
% - data_dir:   parent folder containing all Intan .rhs files to read
% - filename_param_labels:  cell array to parse parameters from rhs filename    
%                           (split by "_") & save in data_struct. defaults to 
%                           {}, which does not save any parameters with data.
%       
%                           eg, filenames of format
%                           '20uA_100Hz_50ms_230725_143022.rhs'
%                           ('current_frequency_length_unwanted_unwanted.rhs')
%                           
%                           labels={"current", "frequency", "length", [], []} 
% 
%                           particularly useful for folders containing multiple 
%                           parameter combinations.
% 
% RETURNS
%   unproc_data:    struct array where each row contains data from one rhs 
%                   file in data_dir). contains fields:
%       - (label):  for label in filename_param_labels, store char array of 
%                   parsed parameter. (eg, unproc_data(1).current == '10uA' )
%       - fs:       sampling frequency (Hz)
%       - sound:    audio data in each rhs file
%       - stim:     stimulation data in each rhs file. usually digital (1/0),
%                   but sometimes analog. code is robust to both
%       - breathing:breath pressure data in each rhs file
%       - file:     struct containing metadata for this rhs file (from matlab 
%                   `dir` function)
% 
% NOTE: this does not take directory names into account when generating
% struct info , only filenames.

    arguments
        data_dir;
        filename_param_labels = {};
    end
    
    file_list = dir(fullfile(data_dir, ['**' filesep '*.rhs']));  % get all intan rhs files
    
    %% get parameters from file name
    params = split({file_list(:).name}, "_");
    
    sz = size(params);
    params = reshape(params, sz(2:3));
    
    assert(length(filename_param_labels) == sz(3));
    
    for i=1:length(filename_param_labels)
        if ~isempty(filename_param_labels{i})
            [file_list.(filename_param_labels{i})] = params{:,i};
        end
    end
    
    unproc_data = arrayfun(@(f) readIntanWrapper(f, filename_param_labels, SuppressOutput=1), file_list);

end

