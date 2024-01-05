function file_list = loadFileList(data_root)
% loadFileList.m
% 2023.12.05 CDR
% 
% Given a folder data_root, collect all Intan .rhs files across all
% subdirectories. Subfolders should be of the form ./drug/current.
% 
% file_list:
%   - name:     file name (eg, '22uA_230307_202528.rhs')
%   - folder:   parent folder of file (eg, '{ROOT}/gabazine/22uA/22uA_230307_202328')
%   - drug:     drug for this file, parsed from folder name (eg, 'gabazine')
%   - current:  current for this file, parsed from folder name (eg, '22ua')
% 

file_list = dir(fullfile(data_root, ['**' filesep '*.rhs']));

cut_folder_names = split(erase({file_list(:).folder}, data_root), filesep);
cut_folder_names = reshape(cut_folder_names, [size(cut_folder_names,2) 3]);

to_delete = ["date", "bytes", "isdir", "datenum"]';  % struct fields to delete

file_list = rmfield(file_list, to_delete);

[file_list.drug] = cut_folder_names{:,1};
[file_list.current] = cut_folder_names{:,2};

end

