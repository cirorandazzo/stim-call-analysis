function [unproc_data, varargout] = s1_load_raw(file_list, options)
% S1_LOAD_RAW
% 2024.02.12 CDR from script a1_load_raw_files
% 
% Load Intan RHS files into matlab struct, including experimental parameters
% 
% Two options for loading:
% (1) file_list_type == 'dir' (DEFAULT)
%   Read all rhs files listed in struct output of dir command.
%   Optionally, parse metadata from filename of each rhs with 
%   filename_labels (see arguments below)
% (2) CSV batch file containing at minimum column "folder"
%   specifying direct parent of .rhs's for a given 
%   condition, and optionally 'labels' providing experimental
%   metadata (eg, stimulation parameters). automatically
%   excludes column 'notes' from being parsed
% 
% 
% ARGUMENTS
%   file_list: either (1) output of dir() containing only rhs
%       files. or (2) CSV batch file as struct array (eg, read
%       with readtable() and convert with table2struct(). see
%       description above for more information.
% 
% KEYWORD ARGUMENTS
%       file_list_type (default 'dir'): describe input type of file_list,
%           according to options above. Can be 'dir' or 'csv_batch'
%       filename_labels (default {}): when file_list_type is 'dir', parse
%           elements of rhs filename separated by '_' as metadata with the
%           names in filename_labels. These values will be added as fields 
%           to unproc_data output Values to ignore should be empty
%           array.
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
%           Eg, for '20uA_100Hz_50ms_230725_143022.rhs', input
%           {"current", "frequency", "length", [], []};
% 
% NOTE: this does not take file stucture into account when making struct;
% see loadFileList.m.
% 
    
    arguments
        file_list;
        options.filename_labels {iscell} = {};
        options.file_list_type {isstring} = 'dir';
        options.datetime_from_filename {islogical} = 1;
        options.verbose (1,1) {islogical} = 0;  % TODO: implement verbosity
    end
    
    
    switch options.file_list_type
        % TODO: do check on file extensions to ensure all are .rhs
        % TODO: fix bug where final label value includes the extension .rhs
    
        case 'dir'
            files = file_list;
    
            % get parameters from file name
            if ~isempty(options.filename_labels)
                params = split({files(:).name}, "_");
                
                sz = size(params);
                if length(sz) > 2  % cases with file_list having >1 file    
                    params = reshape(params, sz(2:3));
                elseif length(sz) == 2
                    params = params';  % returns a column for just 1 string. thats not confusing.
                    sz = [1 sz(2) sz(1)];
                else
                    error('What even happened here? Possibly no files were found.')
                end
            
                assert(length(options.filename_labels) == sz(3));
                
                for i=1:length(options.filename_labels)
                    if ~isempty(options.filename_labels{i})
                        [files.(options.filename_labels{i})] = params{:,i};
                    end
                end
            end
    
            labels = options.filename_labels;
    
    
        case 'csv_batch'
            mergestructs = @(x,y) cell2struct([struct2cell(x);struct2cell(y)],[fieldnames(x);fieldnames(y)]);  % thank you internet stranger
            files = [];
    
            for i_f = 1:length(file_list)
                new_files = dir(fullfile(file_list(i_f).folder, '**', '*.rhs'));
            
                to_remove = {'folder', 'notes'};  % todo: make this a general option?
                this_labels = file_list(i_f);
                for i_tr = 1:length(to_remove)
                    try
                        this_labels = rmfield(this_labels, to_remove{i_tr});
                    catch error
                    end
                end

                n = length(new_files);
            
                this_labels = repmat(this_labels, [n 1]);
            
                new_files = mergestructs(this_labels, new_files);
                files = [files; new_files];
            end
    
            labels = fieldnames(this_labels);
    
        otherwise
            error(['Unrecognized file_list input type: ' options.file_list_type])
    end
    %%

    unproc_data = arrayfun(@(x) readIntanWrapper(x, labels), files);
    
    filename = arrayfun(@(row) row.file.name, unproc_data, UniformOutput=false);
    [unproc_data.filename] = filename{:}; 

    %% add datetimes to unproc_data

    if options.datetime_from_filename
        datestrs = string(regexp(filename, '([0-9]{6})_([0-9]{6})', 'match'));
        dates = datetime(datestrs, InputFormat='yyMMdd_HHmmss');
        
        for i = 1:length(unproc_data)
            unproc_data(i).datetime = dates(i);
        end
        
        % and sort
        [~,index] = sortrows([unproc_data.datetime].');
        unproc_data = unproc_data(index);
        clear index
    end

    %%
    nout = max(nargout, 1) - 1;
    if nout==0
        return;
    elseif nout==1
        varargout{1} = labels;
    else
        error('Too many outputs requested.')
    end
        
end
    
    