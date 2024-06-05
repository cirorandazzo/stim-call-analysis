function [proc_data] = s2_restructure(unproc_data, deq_br, param_labels, trial_radius_s, stim_cooldown_fr)
% S2_RESTRUCTURE
% 2024.02.12 CDR from script a_restruct_data
% 
% Given unprocessed data loaded from Intan (see s1_load_raw), create a data struct where each row of struct contains 1 'condition' (eg, stimulation parameters, drug, lesion, etc)
% 
% For each struct row: 
%       - Cut trials around stimulation onsets (+/- trial_radius_s seconds),
%           storing breathing & audio
%       - Filter breathing & store
% 
% PARAMETERS
% - unproc_data:    loaded from Intan .rhs file
% - deq_br:         digitalFilter object with which to filter breathing (see 
%                   `pipeline.m`)
% - param_labels:       parameter names from which conditions are separated;
%                       see filename_param_labels in s1
% - trial_radius_s:     for each window, time in seconds before and after
%                       stimulation to include in each cut trial
% - stim_cooldown_fr:   ignore stims which occur within this many frames after
%                       another stimulation
% 
% RETURNS
% - proc_data:  

%% index data for individual condition
% parameters: unique values for each label in labels
% conditions: all unique combinations of parameters (even unused ones;
%   empty conditions will be deleted afterward)

if ~isempty(param_labels)
    % CDR 2024.06.04, labels should not contain empty cells.
    % param_labels = param_labels(~cellfun(@isesmpty, param_labels));  % ignore empty cells in labels (not parsed by s1)

    parameters = cellfun(@(x) {unique({unproc_data.(x)})}, param_labels);

    conditions = getUniqueConditionCombos(parameters);
else
    param_labels = [];
    conditions = 1;  % if no labels, assume data is all in 1 row
end

%%
for cond=size(conditions,1):-1:1
    data_i = ones([1 length(unproc_data)], 'logical');  % boolean index for data with this condition (ie, specific set of labels)

    for i=1:length(param_labels) % assign condition info to this struct
        param_name = param_labels{i};
        val = conditions(cond,i);

        proc_data(cond).(param_name) = val;  % set parameters in new struct
        data_i = data_i & strcmp({unproc_data.(param_name)}, val);  % make conditional index of unproc_data
    end

    if any(data_i)
            data_cut = unproc_data(data_i);

            proc_struct = [];

            for struct_row=1:size(data_cut, 1)  % row in unproc data; may contain >1 stim
                x = data_cut(struct_row);
                for data_row=1:size(data_cut(struct_row).breathing, 1)
                    
                    stim = x.stim(data_row, :);
                    breathing = x.breathing(data_row, :);
                    sound = x.sound(data_row, :);

                    int_struct = [];

                   [int_struct.breathing, ...
                    int_struct.breathing_filt,...
                    int_struct.audio] = ...
                    getCallParamsFromFile(...
                        stim, ...
                        breathing, ...
                        sound, ...
                        deq_br, ...
                        x.fs, ...
                        trial_radius_s, ...
                        stim_cooldown_fr);

                    proc_struct = [proc_struct int_struct];
                end

            end


            % proc_struct = arrayfun(@(x) getCallParamWrapper(x, deq_br, radius, insp_dur_max, ...
            %     exp_delay, exp_dur_max), data_cut);

            % merges ALL rows (1 row/file) for this condition into 1 row in
            % new struct
            proc_data(cond).breathing=cell2mat({proc_struct.breathing}');
            proc_data(cond).breathing_filt=cell2mat({proc_struct.breathing_filt}');
            proc_data(cond).audio=cell2mat({proc_struct.audio}');
            % proc_data(cond).latencies=cell2mat({proc_struct.latencies}');
            % proc_data(cond).exp_amps=cell2mat({proc_struct.exp_amps}');
            % proc_data(cond).insp_amps=cell2mat({proc_struct.insp_amps}');
            % proc_data(cond).insp_amps_t=cell2mat({proc_struct.insp_amps_t}');
    end
        
    clear a;

end

%% remove empty rows
% ie, conditions with no trials
empty_cond = cellfun(@(x) isempty(x), {proc_data.breathing});
proc_data = proc_data(~empty_cond);

end


%% LOCAL HELPERS


function [breathing, breathing_filt, audio] ...
    = getCallParamsFromFile( ...
        data_stim, data_breathing, data_sound, deq_breath, fs, trial_radius_s, stim_cooldown_fr)
% LOCAL HELPER: getCallParamsFromFile
% 2023.12.05 CDR
% 
% Return cut trials for every valid stimulation in a previously read Intan file.
% 
% PARAMETERS
%   data_stim, data_breathing, data_sound: one or more rows of data from Intan
%   deq_breath: digitalFilter object with which to filter breathing
%   fs: sample rate (Hz)
%   trial_radius_s: for each window, time (s) before and after stimulation to include in each cut trial
% 

    data_stim_dig = data_stim>=1;  % some birds have analog stim_ii data
    
    % == get stim_ii onsets (frame in data_stim) ==
    stim_ii = find(data_stim_dig == 1);  % indices where stim_ii is occuring.
    stim_ii(stim_ii==1) = [];  % ignore stim_ii at very start of data. breaks next statement

    stim_t = stim_ii(~any(data_stim_dig(max(1, stim_ii-stim_cooldown_fr):stim_ii-1) == 1) );  % ensure another stim_ii does not occur in 'stim_cooldown_fr' frames before

    r_fr = trial_radius_s * fs;  % num of frames to take before/after stim
    l_window = 2*r_fr+1;

    stim_t = getGoodStims(stim_t, r_fr, length(data_breathing));
   
    % == preallocate for speed ==
    z = zeros([length(stim_t) l_window]);  % vector length l_window per trial
    breathing = z;
    breathing_filt = z;
    audio = z;

    for j = length(stim_t):-1:1  % for each stimulation
        % start and end frames of windows in data_stim
        s = stim_t(j) - r_fr;
        e = stim_t(j) + r_fr;

        % cut & filter data
        breathing(j,:) = data_breathing(s:e);
        breathing_filt(j,:) = filtfilt(deq_breath, data_breathing(s:e));  
        audio(j,:) = data_sound(s:e);
    end

end


function stim_t_good = getGoodStims(stim_t, r_fr, data_len)
    % only take trials where all data within trial_radius_s exists

    stim_t_good = [];

    for i = 1:length(stim_t)
        % window start and end for this stimulation
        s = stim_t(i) - r_fr;
        e = stim_t(i) + r_fr;

        if e > data_len ...  %  not enough data at end of trial window 
                || s < 1  % not enough data at beginning of trial window
            continue;
        else
            stim_t_good = [stim_t_good stim_t(i)]; %#ok<AGROW>  % ignore preallocate warning, this is a small array
        end
    end

end


function combos = getUniqueConditionCombos(conditions)
% getUniqueConditionCombos.m
% 2023.01.10
% 
% Given cell array where each cell is a string list of conditions, get
% every possible combination of conditions.
% 
% ie, cartesian product
% 
% Thanks stackexchange stranger :) https://stackoverflow.com/a/4169488/23017760

    
    c = cell(1, numel(conditions));
    [c{:}] = ndgrid( conditions{:} );
    combos = cellfun(@(v) v(:)', c, 'UniformOutput',false);
    
    combos = string(vertcat(combos{:}))';  % convert to string so @unique works
    combos = unique(combos, 'rows');  % remove any duplicate conditions
end


