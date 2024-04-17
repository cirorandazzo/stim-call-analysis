function save_files_pipeline(save_path, data, delete_fields)
%% save_files_pipeline.m
% 
% save var `data` to `savepath`, ignoring any fields in `delete_fields`

if ~isempty(delete_fields)
    for f = delete_fields
        if isfield(data, f)
            data = rmfield(data, f);
        end
    end
end

if ~isempty(save_path)
   save(save_path, 'data');
end

end

