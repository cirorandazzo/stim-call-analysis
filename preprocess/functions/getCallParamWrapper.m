function proc_struct = getCallParamWrapper(data_struct, deq_br, radius, ...
    insp_dur_max, exp_delay, exp_dur_max)
% getCallParamWrapper.m
% 2023.12.13 CDR
% 
% Given a single row of struct with 1 x frames breathing, audio, stim data,
% process & return as another struct.
% 
% PARAMETERS:
%   See getCallParamsFromFile.m for full parameter descriptions.
% 
%   data_struct: should have fields
%       - stim
%       - breathing
%       - sound
%       - fs


[proc_struct.breathing, ...
    proc_struct.breathing_filt,...
    proc_struct.audio, ...
    proc_struct.latencies, ...
    proc_struct.exp_amps, ...
    proc_struct.insp_amps, ...
    proc_struct.insp_amps_t] ...
    ...
    = getCallParamsFromFile(...
        data_struct.stim, ...
        data_struct.breathing, ...
        data_struct.sound, ...
        deq_br, ...
        data_struct.fs, ...
        radius, ...
        insp_dur_max, ...
        exp_delay, ...
        exp_dur_max);

end

