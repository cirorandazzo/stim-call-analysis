function save_files_pipeline(save_path, data, delete_fields)
%% save_files_pipeline.m
% 
% save var `data` to `savepath`, ignoring any fields in `delete_fields`
% need to specify v7.3 mat file, otherwise files with size >2gb arent saved

if ~isempty(delete_fields)
    for f = delete_fields
        if isfield(data, f)
            data = rmfield(data, f);
        end
    end
end

if ~isempty(save_path)
   save(save_path, 'data',  '-v7.3');
end

end

