%% a_restruct_data.m
% 2023.12.13 CDR
% 
% TODO: rename
% Given "unprocessed data" (data_struct from ek_read_Intan_RHS2000_file), 

clear

%% load data

unproc_data = '/Users/cirorandazzo/ek-spectral-analysis/unproc_data-bk68wh15.mat';
save_file = '/Users/cirorandazzo/ek-spectral-analysis/proc_data-bk68wh15.mat';

load(unproc_data)

labels = {"current", "frequency", "length"};

%% set process options & create filter

radius = 1;
insp_dur_max = 100;
exp_delay = 50;
exp_dur_max = 300;

% Design filter
N = 30;
Fpass = 400;
Fstop = 450;
fs = 30000; 

% Design method defaults to 'equiripple' when omitted

tic;

deq = designfilt('lowpassfir','FilterOrder',N,'PassbandFrequency',Fpass,...
  'StopbandFrequency',Fstop,'SampleRate',fs);


%% index data for individual condition
% parameters: unique values for each label in labels
% conditions: all unique combinations of parameters (even unused ones;
%   empty conditions will be deleted soon)

parameters = cellfun(@(x) {unique({unproc_data.(x)})}, labels);

n_conditions = prod(cellfun(@(x) size(x,1), parameters));

conditions = getUniqueConditionCombos(parameters);

%%
for cond=size(conditions,1):-1:1
    data_i = ones([1 length(unproc_data)]);

    for i=1:length(labels) % assign condition info to this struct
        param_name = labels{i};
        val = conditions(cond,i);

        proc_data(cond).(param_name) = val;  % set parameters in new struct
        data_i = data_i & strcmp({unproc_data.(param_name)}, val);  % make conditional index of unproc_data
    end

    if any(data_i)
            data_cut = unproc_data(data_i);

            proc_struct = arrayfun(@(x) getCallParamWrapper(x, deq, radius, insp_dur_max, ...
            exp_delay, exp_dur_max), data_cut);

            proc_data(cond).breathing=cell2mat({proc_struct.breathing}');
            proc_data(cond).audio=cell2mat({proc_struct.audio}');
            proc_data(cond).latencies=cell2mat({proc_struct.latencies}');
            proc_data(cond).exp_amps=cell2mat({proc_struct.exp_amps}');
            proc_data(cond).insp_amps=cell2mat({proc_struct.insp_amps}');
            proc_data(cond).insp_amps_t=cell2mat({proc_struct.insp_amps_t}');
    end
        
    clear a;

end

%% remove empty rows
% ie, conditions with no trials
empty_cond = cellfun(@(x) isempty(x), {proc_data.breathing});
proc_data = proc_data(~empty_cond);

toc; 
%% save
save(save_file, 'proc_data')
