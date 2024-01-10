function [breathing, breathing_filt, audio, latencies, exp_amps, insp_amps, insp_amps_t] ...
    = getCallParamsFromFile(data_stim, data_breathing, data_sound, deq, fs, radius, insp_dur_max, exp_delay, exp_dur_max)
% getCallParamsFromFile.m
% 2023.12.05 CDR
% 
% TODO: recenter data better. currently adding 0.2, which is not a good way.
% TODO: documentation
% 
%   radius: for each window, time before and after stim (seconds). usually 1s, for total window length of 2s 
%   insp_dur_max: how long after stimulation to check for inspiration (milliseconds). usually 100ms
%   exp_delay: how long to wait after stimulation before checking for expiration (milliseconds). usually 50ms
%   exp_dur_max: window after call onset in which to check expiratory amplitude. usually 300ms 
% 
% Return cut stim trials & some call parameters for every valid stimulation
%   in a previously read Intan file.

    
    % == get stim onsets (frame in data_stim) ==
    stim = find(data_stim == 1);  % indices where stim is occuring

    stim(stim==1) = [];  % ignore stim at very start of data. breaks next statement
    % TODO: do nicer error checking

    stim_t = stim(data_stim(stim - 1) ~=1 );  % stim does not occur prev trial

    r_fr = radius * fs;  % num of frames to take before/after stim
    l_window = 2*r_fr+1;

    stim_t = getGoodStims(stim_t, r_fr, length(data_breathing));

    % == preallocate for speed ==
    z = zeros([length(stim_t) l_window]);  % vector length l_window per trial
    breathing = z;
    breathing_filt = z;
    audio = z;

    z = zeros([length(stim_t) 1]);  % 1 value per trial
    latencies = z;
    exp_amps = z;
    insp_amps = z;
    insp_amps_t = z;

    % == get time parameters in frames ==
    insp_dur_max_f = insp_dur_max * fs / 1000;  % how long to wait after stim to check exp
    exp_delay_f = exp_delay * fs / 1000;  % how long to wait after stim to check exp
    exp_dur_max_f = exp_dur_max * fs / 1000;  % length of window after expiration onset in which to check for expiratory amplitude

    for j = 1 : length(stim_t)  % for each stimulation

        % start and end frames of windows in data_stim
        s = stim_t(j) - r_fr;
        e = stim_t(j) + r_fr;

        % == cut & filter data ==
        if s<1 || e<1
            disp('here')
        end

        f = filtfilt(deq, data_breathing(s:e));
        
        breathing(j,:) = data_breathing(s:e);
        breathing_filt(j,:) = f;  
        audio(j,:) = data_sound(s:e);

        stim_i = r_fr + 1;  % frame index of stim in cut data

        % == re-center data ==
        f = f + 0.2;
        % f = recenterData(f);  % TODO: recenter data in a better way

        
        % == get call index ==
        call_i = find(f > 0);  % index for all expiratory activity in window
        call_i = call_i(call_i > stim_i + exp_delay_f);  % only get expirations after stim & exp_delay
        
        % == cut segments of window ==
        % for computing call parameters
        stim_insp = f(stim_i : stim_i + insp_dur_max_f);
        call_exp = f(call_i(1) : call_i(1) + exp_dur_max_f );
        pre_stim = f(1:stim_i-1);  % TODO: get 2-3 segmented breaths before instead of entire pre-stim window

        % == compute parameters ==
        latencies(j) = (call_i(1) - stim_i) * 1000 / fs;

        % exp amp of call. normalized to max exp amp in window before stim
        exp_amps(j) = max(call_exp) / max(pre_stim);
        
        [stim_insp_max, idx] = min(stim_insp);  % inspirations are negative
        insp_amps(j) = abs(stim_insp_max)/ min(pre_stim);  % abs keeps inspirations negative
        insp_amps_t(j) = idx * 1000/fs;
    end

end

function stim_t_good = getGoodStims(stim_t, r_fr, data_len)
    % only take trials where all data within radius exists

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

