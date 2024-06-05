function file_list = loadFileList(data_root, folders_to_save)
% loadFileList.m
% 2023.12.05 CDR
% 
% Given a folder data_root, collect all Intan .rhs files across all
% subdirectories. Subfolders should be of the form ./drug/current.
% 
% folders_to_save: cell array containing 
% 
% file_list:
%   - name:     file name (eg, '22uA_230307_202528.rhs')
%   - folder:   parent folder of file (eg, '{ROOT}/gabazine/22uA/22uA_230307_202328')
%   - drug:     drug for this file, parsed from folder name (eg, 'gabazine')
%   - current:  current for this file, parsed from folder name (eg, '22ua')
% 

% get all rhs files in data_root
file_list = dir(fullfile(data_root, ['**' filesep '*.rhs']));

% delete data_root from paths, then split at filesep
cut_folder_names = erase({file_list(:).folder}, fullfile(data_root+filesep));  % fullfile part makes sure filesep is removed
cut_folder_names = split(cut_folder_names, filesep);

% reshape this, 
sz = size(cut_folder_names);
cut_folder_names = reshape(cut_folder_names, sz(2:3));

%%
to_delete = ["date", "bytes", "isdir", "datenum"]';  % struct fields to delete

file_list = rmfield(file_list, to_delete);

assert(size(cutfoldernames,2) == length(folders_to_save));  % make sure to give enough folder labels, including the file name itself! if you don't want to save it, put [] in that location.

for i=1:length(folders_to_save)
    if ~isempty(folders_to_save{i})
        [file_list.(folders_to_save{i})] = cut_folder_names{:,i};
    end
end

end

