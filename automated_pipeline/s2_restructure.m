function [proc_data] = s2_restructure(unproc_data, deq_br, ...
    labels, radius, insp_dur_max, exp_delay, exp_dur_max, stim_cooldown)
% S2_RESTRUCTURE
% 2024.02.12 CDR from script a_restruct_data
% 
% Given unprocessed data loaded from Intan (see s1_load_raw), restructure
% the data into a struct

%% index data for individual condition
% parameters: unique values for each label in labels
% conditions: all unique combinations of parameters (even unused ones;
%   empty conditions will be deleted soon)

if ~isempty(labels)
    l = labels(~cellfun(@isempty, labels));  % ignore empty cells in labels

    parameters = cellfun(@(x) {unique({unproc_data.(x)})}, l);

    conditions = getUniqueConditionCombos(parameters);
else
    l = [];
    conditions = 1;  % if no labels, assume data is all in 1 row
end

%%
for cond=size(conditions,1):-1:1
    data_i = ones([1 length(unproc_data)], 'logical');  % boolean index for data with this condition (ie, specific set of labels)

    for i=1:length(l) % assign condition info to this struct
        param_name = l{i};
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
                    int_struct.audio, ...
                    ~,... int_struct.latencies, ...
                    ~,... int_struct.exp_amps, ...
                    ~,... int_struct.insp_amps, ...
                    ~]... int_struct.insp_amps_t] ...
                    ...
                    = getCallParamsFromFile(...
                        stim, ...
                        breathing, ...
                        sound, ...
                        deq_br, ...
                        x.fs, ...
                        radius, ...
                        insp_dur_max, ...
                        exp_delay, ...
                        exp_dur_max, ...
                        stim_cooldown);

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

