function [call_breath_seg_data] = s4_segment_breaths(...
    call_seg_data, fs, stim_i, dur_thresh, exp_thresh, insp_thresh, ...
    stim_window_pre_ms, stim_window_post_ms, smooth_window, insp_dur_max_ms)
% S3_SEGMENT_BREATHS
% 2024.02.13 CDR based on code from ZK
% 
% TODO: s4 documentation
% 
% - return data struct with segmented breaths
% - takes breathing data for every condition in struct (cell of n x fr
% matrices)
% 
% This function segments breaths from 'one call trials' in call_seg_data.
%   - zero-crossing algorithm for insps/exps
%   - derivative algorithm for inspirations
% 
% INPUTS
%   call_seg_data: 
%       See s3 output.
%   fs: 
%       Sampling frequency.
%   stim_i:
%       Frame index of stimulus in trial
%   dur_thresh: 
%       For breath segmentation, minimum amount of time between 2 inspirations or 2 expirations.
%   exp_thresh: 
%       Expiration threshold for breath segmentation.
%   insp_thresh: 
%       Inspiration threshold for breath segmentation.
%   stim_window_pre_ms/stim_window_post_ms:
%       Window around stimulation in ms to consider breath zero-crossings as pre, peri, or post stimulation
%   smooth_window: 
%       Size of the smoothing window to be used in inspiration derivative calculations.
%   insp_dur_max_ms:
%       Maximum time (ms) after stimulation to look for inspiration
%
% OUTPUT
%   call_breath_seg_data:
%       call_seg_data with new additional field, `breath_seg` (struct array). each row is a 'one call trial', and contains subfields
%       - centered:
%           recentered breathing data
%       - {exps/insps}_{pre/post/peri}: 
%           breath zero crossings before/during/after defined stimulation window (see stim_window parameters)
%       - latency_insp:
%           latency to inspiration in ms, computed by derivative algorithm 
%       - latency_insp_f: 
%           latency to inspiration in frames, computed by derivative algorithm (useful for plotting)
%       - error:
%           0 if no error, else stores error with processing this trial.
% 

stim_window_post_fr = stim_window_post_ms * fs / 1000;
stim_window_pre_fr = stim_window_pre_ms * fs / 1000;

breathing = {call_seg_data(:).breathing_filt};

breath_seg_data = cell( size(breathing) );

for i=1:length(breathing) % run for each condition separately (see local helper function segment_each_cond)
    x = breathing{i};
    breath_seg_data{i} = segmentEachCondition(x, stim_i, fs, dur_thresh, ...
        exp_thresh, insp_thresh, stim_window_pre_fr, stim_window_post_fr, smooth_window, insp_dur_max_ms);
end

call_breath_seg_data = call_seg_data;
[call_breath_seg_data.breath_seg] = breath_seg_data{:};

end


%% LOCAL HELPERS

function [breath_seg_data_cond] = segmentEachCondition( ...
    breathing, stim_i, fs, dur_thresh, exp_thresh, insp_thresh, ...
    stim_window_pre_fr, stim_window_post_fr, smooth_window, insp_dur_max_ms)
% LOCAL HELPER FUNCTION    
% for all breathing data in given condition, run segmentation code trial by
% trial
    breath_seg_data_cond = [];

    insp_dur_max_f = insp_dur_max_ms * fs / 1000;


    for tr = size(breathing, 1):-1:1
        
        b = breathing(tr, :);  % data for 1 stim trial
        
        % roughly recenter around 0 so code works
        b = b - median(b);

        % roughly segment breaths
        [insps, exps] = ek_segmentBreaths_current(b, insp_thresh, exp_thresh, dur_thresh);
    
        exps_pre = exps(exps < stim_i);

        % assert(length(exps_pre) > 1);

        % recenter based on these segmented breaths

        try
            centered = ek_centerBreaths(b, exps_pre(1), exps_pre(end));
            % NOTE: if there's only 1 exp found before stim, this statement
            % has no effect
    
            % re-segment based on centered breathing data
            [insps, exps] = ek_segmentBreaths_current(centered, insp_thresh, exp_thresh, dur_thresh);
        
            breath_seg_data_cond(tr).centered = centered;
    
            breath_seg_data_cond(tr).exps_pre = exps(exps < (stim_i - stim_window_pre_fr));
            breath_seg_data_cond(tr).insps_pre = insps(insps < (stim_i - stim_window_pre_fr));
        
            breath_seg_data_cond(tr).exps_post = exps(exps > (stim_i + stim_window_post_fr));
            breath_seg_data_cond(tr).insps_post = insps(insps > (stim_i + stim_window_post_fr));
            
            breath_seg_data_cond(tr).exps_peri = exps(exps >= (stim_i - stim_window_pre_fr) & exps <= (stim_i + stim_window_post_fr));
            breath_seg_data_cond(tr).insps_peri = insps(insps >= (stim_i - stim_window_pre_fr) & insps <= (stim_i + stim_window_post_fr));
    
            % exp
            latency_exp = (breath_seg_data_cond(tr).exps_post(1) - stim_i) * 1000 / fs;
            breath_seg_data_cond(tr).latency_exp = latency_exp;

            breath_seg_data_cond(tr).error = 0;
        catch err
            breath_seg_data_cond(tr).error = err;
        end


        % LATENCIES
        % insp
        breath_seg_data_cond(tr).latency_insp_f = getInspiratoryLatency(breathing(tr, :), stim_i, insp_dur_max_f, smooth_window);
        breath_seg_data_cond(tr).latency_insp = [breath_seg_data_cond(tr).latency_insp_f] / fs * 1000;
        
    end

    breath_seg_data_cond = breath_seg_data_cond';
end 


function i = getInspiratoryLatency(y, stim_i, insp_dur_max_f, smooth_window)
    % get index of minimum second derivative in window after stim
    % pass in filtered breathing data

    yp = ddt(y);
    yp = smoothdata(yp, 'movmean', smooth_window);

    ypp = ddt(yp);  
    ypp = smoothdata(ypp, 'movmean', smooth_window);
    ypp = [0 0 ypp]; % zero padding for consistent indexing

    wind = stim_i+1 : stim_i+insp_dur_max_f;

    [~, i] = min(ypp(wind));
end


function dydt = ddt(y)
    % derivative of a discrete time series
    dydt = minus(y(2:end), y(1:end-1));
end