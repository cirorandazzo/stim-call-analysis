% main_call_vicinity_pipeline.m
% 2024.02.14 CDR
% 
% Batch run vicinity analysis

clear;

param_file_folder = '/Users/cirorandazzo/code/stim-call-analysis/data/parameters';
parameter_files = dir([param_file_folder filesep '**' filesep '*.m'] );
to_exclude = {... % .m files to exclude from param folder
    'default_params.m', ... ignore default parameter file
    'bu26bu73.m', ... bu26bu73 has 2 channels which means diff structure
    'bird_080720.m', 'pu81bk43.m' ... stim noise in audio channel
    }; 
    
only_these = {'bu69bu75.m'};  % parameter files. make sure to include `.m`

verbose = 1;

current_dir = cd;
run_dt = datetime;

if ~isempty(only_these)
    parameter_files(~ismember({parameter_files.name}, only_these)) = [];
end

parameter_files(ismember({parameter_files.name}, to_exclude)) = [];  % exclude files from to_exclude

%%
for i = 1:length(parameter_files)

        [~, f, ~] = fileparts(parameter_files(i).name);  % param filename w/o extension

        cd(parameter_files(i).folder);
        eval(f);  % make parameter struct from .m file
        cd(current_dir);

        p.run_dt = run_dt;

        assert(~isempty(strfind(p.files.raw_data, p.files.bird_name)));  % ensure birdname is in raw data filename
    
        mkdir(p.files.save_folder);
    
    try
        disp(['%=====Running ' f '...'])
        tic

        call_vicinity_pipeline;  % and run 
        
        disp('Success! Saved files:');
        fields = fieldnames(p.files.save);
        for j=1:length(fields)
            disp(['  - ' fields{j} ': ' p.files.save.(fields{j})]);
        end

        
    
    catch err
        log_file = [p.files.save_folder '/' p.files.bird_name '_ERROR_LOG.txt'];
        disp(['Error. See log: ' log_file])

        fid = fopen(log_file, 'w');

        % print error to file
        fprintf(fid, '%s', err.getReport('extended', 'hyperlinks','off'));

        % close file
        fclose(fid);

    end

    disp(['Total time for this bird:'])
    toc
    
    disp('  ');  % newline between birds

    clearvars -except a i parameter_files verbose current_dir run_dt;

end