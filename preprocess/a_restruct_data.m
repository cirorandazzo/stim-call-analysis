%% a_restruct_data.m
% 2023.12.13 CDR
% 
% Given "unprocessed data" (data_struct from ek_read_Intan_RHS2000_file), 

clear

%% load data

unproc_data = '/Users/cirorandazzo/ek-spectral-analysis/unproc_data.mat';
save_file = '/Users/cirorandazzo/ek-spectral-analysis/proc_data.mat';

load(unproc_data)

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
deq = designfilt('lowpassfir','FilterOrder',N,'PassbandFrequency',Fpass,...
  'StopbandFrequency',Fstop,'SampleRate',fs);


%% index data for individual condition

% get all conditions. or, specify these manually
drugs = unique({data.drug});
currents = unique({data.current});

conditions = length(drugs)*length(currents);

pr = cell(1,conditions);
proc_data = struct(...
    'drug', pr, ...
    'current', pr, ...
    'breathing', pr, ...
    'audio', pr, ...
    'latencies', pr, ...
    'exp_amps', pr, ...
    'insp_amps', pr, ...
    'insp_amps_t', pr ...
    );  % preallocate struct array length

%%
n_currents = length(currents);

for i = 1:length(drugs)
    d = drugs{i};
    i_drug = strcmp({data.drug}, d);

    for j = 1:n_currents
        c = currents{j};
        i_curr = strcmp({data.current}, c);
        
        data_cut = data(i_drug & i_curr);
        
        k = n_currents*(i-1)+j;  % row of proc_data (flattened index for i/j)

        % process & flatten
        if ~isempty(data_cut)
            proc_struct = arrayfun(@(x) getCallParamWrapper(x, deq, radius, insp_dur_max, ...
            exp_delay, exp_dur_max), data_cut);

            a.drug = d;
            a.current = c;
            a.breathing=cell2mat({proc_struct.breathing}');
            a.audio=cell2mat({proc_struct.audio}');
            a.latencies=cell2mat({proc_struct.latencies}');
            a.exp_amps=cell2mat({proc_struct.exp_amps}');
            a.insp_amps=cell2mat({proc_struct.insp_amps}');
            a.insp_amps_t=cell2mat({proc_struct.insp_amps_t}');
    
            proc_data(k)=a;
        else
            proc_data(k).drug = d;
            proc_data(k).current = c;
        end
        % save to struct
        
        clear a;
    end
end

%% remove empty rows
% ie, conditions with no trials
empty_cond = cellfun(@(x) isempty(x), {proc_data.breathing});
proc_data = proc_data(~empty_cond);

%% save
save(save_file, 'proc_data')
