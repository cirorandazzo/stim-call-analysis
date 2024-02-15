% main_call_vicinity_pipeline.m
% 2024.02.14 CDR
% 
% Batch run vicinity analysis

clear;

param_file_folder = "ek_spectral_analysis/automated_pipeline/parameter_files/dm_stim/*.m";
parameter_files = dir(param_file_folder);

% parameter_files = parameter_files(~strcmp({parameter_files.name}, "bird_080720.m"));  % this bird has weird stimData (float, not binary)

%%
for i = 1:length(parameter_files)

        [~, f, ~] = fileparts(parameter_files(i).name);
        
        eval(f);  % make parameter struct from .m file
    
        assert(~isempty(strfind(p.files.raw_data, p.files.bird_name)));  % ensure birdname is in raw data filename
    
        mkdir(p.files.save_folder);
    
    try
        disp(['%=====Running ' f '...'])
        tic
    
        verbose = 0; % suppress output
        call_vicinity_pipeline;  % and run 
        
        disp('Success! Saved files:');
        fields = fieldnames(p.files.save);
        for j=1:length(fields)
            disp(['  - ' fields{j} ': ' p.files.save.(fields{j})]);
        end

        toc
    
    catch err
        log_file = [p.files.save_folder '/' p.files.bird_name '_ERROR_LOG.txt'];
        disp(['Error. See log: ' log_file])

        fid = fopen(log_file, 'w');

        % print error to file
        fprintf(fid, '%s', err.getReport('extended', 'hyperlinks','off'));

        % close file
        fclose(fid);

    end

    disp('  ');  % newline between birds

    clearvars -except a i parameter_files;

end