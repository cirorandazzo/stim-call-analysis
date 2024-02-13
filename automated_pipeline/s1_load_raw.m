function [unproc_data] = s1_load_raw(data_dir,save_path)
% S1_LOAD_RAW
% 2024.02.12 CDR from script a1_load_raw_files
% 
% Load all Intan RHS files from a directory
% 
% NOTE: this does not take file stucture into account when making struct;
% see loadFileList.m.

file_list = dir(fullfile(data_dir, ['**' filesep '*.rhs']));  % get all intan rhs files

%% get parameters from file name
params = split({file_list(:).name}, "_");

sz = size(params);
params = reshape(params, sz(2:3));

labels = {"current", "frequency", "length", [], []};

assert(length(labels) == sz(3));

for i=1:length(labels)
    if ~isempty(labels{i})
        [file_list.(labels{i})] = params{:,i};
    end
end

%%

unproc_data = arrayfun(@(x) readIntanWrapper(x, labels, "SuppressOutput"), file_list);

%%

if ~isempty(save_file)
    save(save_path, "unproc_data");
end

end

