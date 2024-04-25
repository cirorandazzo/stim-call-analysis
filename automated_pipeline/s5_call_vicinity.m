function [data] = s5_call_vicinity(...
    call_breath_seg_data, ...
    fs, ...
    stim_i, ...
    post_call_ms, ...
    options ...
)
% s5_call_vicinity
% 2024.02.14 CDR
% 
% Given output of s4, computes average pressure of 3 windows: before, 
% during, and after audio-segmented call.
% 
% Some flexibility in pre-call window; see kw argument PreCall
% 
% 
% PARAMETERS
%   call_breath_seg_data: s4_segment_breaths output. needs call_seg (s3) and 
%       breath_seg (s4) sub-structs
%   fs: sample rate
%   stim_i:
%       - assert that last insp in insps_pre comes before this point
%       - if options.PreCall = [], precall breath window is stim_i:call_onset
%   post_call_ms: length (ms) of post-call window
%   
%   KEYWORD ARGUMENTS
%       - PreCall: length (ms) of pre-window before call onset. if [],
%           prewindow indices are (stim_i : onset). Default: [].
% 
% OUTPUT
%   data: call_breath_seg with new substruct vicinity, size = (1 x trs w/ exactly 1 call)
% 
%   data.vicinity fields:
%       - pre_call_breath_mean 
%       - call_breath_mean
%       - post_call_breath_mean

%       - issue: 0 if no error on this trial, else saves thrown error;
% 
% MAJOR CHANGES
% 2024.04.24 - added kw arg "PreCall" for defined precall window length
%   (instead of stim:call_onset)
% 


    arguments
       call_breath_seg_data struct
       fs (1,1) {mustBeNumeric}
       stim_i (1,1) {mustBeNumeric}
       post_call_ms (1,1) {mustBeNumeric}
       options.PreCall {mustBeNumeric} = []
    end

    post_call_f = post_call_ms * fs / 1000;

    for c=1:size(call_breath_seg_data,1)  % for each condition (row in struct)
        trials = call_breath_seg_data(c).call_seg.one_call;

        for i=length(trials):-1:1  % for all trials with one call
            tr = trials(i);

            % get pre-stim expirations/inspirations
            exps_pre = call_breath_seg_data(c).breath_seg(tr).exps_pre;
            insps_pre = call_breath_seg_data(c).breath_seg(tr).insps_pre;

            try
                % get last insp before stim
                last_insp = insps_pre(end);
                assert(stim_i > last_insp);

                % get exp right before last insp
                possible_exps = exps_pre(exps_pre < last_insp);
                last_exp = max(possible_exps);
    
                % normalize all breathing to mean value of n-1 expiration
                nMin1_exp = call_breath_seg_data(c).breath_seg(tr).centered(last_exp:last_insp);
                nMin1_exp_mean = mean(nMin1_exp);
                breathing_norm = call_breath_seg_data(c).breathing_filt(tr, :) / nMin1_exp_mean;
    
                % load audio-segmented call onset/offset
                onset = call_breath_seg_data(c).call_seg.onsets{tr};
                offset = call_breath_seg_data(c).call_seg.offsets{tr};
    
                % get windows & save mean
                %  - stim -> call onset
                if ~isempty(options.PreCall)  % if pre-call window length defined, start is (call - pre-call window length)
                    pre_win_st = onset - (options.PreCall * fs / 1000);
                else  % take stim : call_onset
                    pre_win_st = stim_i;
                end

                pre_call_br = breathing_norm(pre_win_st:onset);
                call_breath_seg_data(c).vicinity(i).pre_call_breath_mean = mean(pre_call_br);
    
                %  - call (onset:offset, from audio segmentation)
                call_br = breathing_norm(onset:offset);
                call_breath_seg_data(c).vicinity(i).call_breath_mean = mean(call_br);
    
                %  - post call (call offset : offset + post_window)
                post_window_br = breathing_norm(offset:offset+post_call_f);
                call_breath_seg_data(c).vicinity(i).post_call_breath_mean = mean(post_window_br);

                % mark as success & save norm'd breathing
                call_breath_seg_data(c).vicinity(i).issue = false;
                call_breath_seg_data(c).vicinity(i).normd = breathing_norm;

            catch err
                call_breath_seg_data(c).vicinity(i).issue = err;
            end

        end
    end

    data = call_breath_seg_data;
end