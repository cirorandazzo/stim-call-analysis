%% a1_load_raw_files.m
% 2023.01.09 CDR
% 
% Load all Intan RHS files from a directory
% 
% NOTE: this does not take file stucture into account when making struct;
% see loadFileList.m.

clear

%%
data_root = "/Users/cirorandazzo/ek-spectral-analysis/PAm stim/052222_bk68wh15"; 

file_list = dir(fullfile(data_root, ['**' filesep '*.rhs']));  % get all intan rhs files

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

tic
unproc_data = arrayfun(@(x) readIntanWrapper(x, labels, "SuppressOutput"), file_list);
toc

%%

save("/Users/cirorandazzo/ek-spectral-analysis/unproc_data-bk68wh15.mat", "unproc_data");