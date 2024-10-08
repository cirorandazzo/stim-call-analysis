function [call_breath_seg_data] = s4_segment_breaths(...
    call_seg_data, ...
    fs, stim_i, ...
    dur_thresh, exp_thresh, insp_thresh, ...
    stim_window_pre_ms, stim_window_post_ms, ... 
    smooth_window, stim_induced_insp_window_ms, ...
    exp_amp_window_ms, insp_amp_window_ms)
% S4_SEGMENT_BREATHS
% 2024.02.13 CDR based on code from ZK
% 
% - return data struct with segmented breaths
% - takes breathing data for every condition in struct (cell of n x fr
% matrices)
% 
% This function segments breaths from all trials in call_seg_data.
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
%   stim_induced_insp_window:
%       Window (wrt stim onset) to check for inspiration onset (milliseconds)
%   exp_amp_window_fr:
%       Start & end of window to look for expiratory amplitude (in frames; 1==trial start)
%   insp_amp_window_fr:
%       Start & end of window to look for inspiratory amplitude (in frames; 1==trial start)
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

breathing = {call_seg_data(:).breathing_filt};
breath_seg_data = cell( size(breathing) );  % preallocate

warn_pre_breaths = false;

stim_window_post_fr = stim_window_post_ms * fs / 1000;
stim_window_pre_fr = stim_window_pre_ms * fs / 1000;

exp_amp_window_fr = msToFrames(exp_amp_window_ms, fs, stim_i);
insp_amp_window_fr = msToFrames(insp_amp_window_ms, fs, stim_i);

stim_induced_insp_window_f = msToFrames(stim_induced_insp_window_ms, fs, stim_i);

for i=1:length(breathing) % run for each condition separately (see local helper function segmentEachCondition)
    x = breathing{i};
    breath_seg_data{i} = segmentEachCondition( ...
        x, ...
        stim_i, fs, ...
        dur_thresh, exp_thresh, insp_thresh, ...
        stim_window_pre_fr, stim_window_post_fr, ...
        smooth_window, stim_induced_insp_window_f, ...
        exp_amp_window_fr, insp_amp_window_fr ...
        );

    if any([breath_seg_data{i}.n_pre_stim_breath_cycles] < 2)
        warn_pre_breaths = true;
    end

end

if warn_pre_breaths
    warning('Less than 2 full insp-to-insp pre-stim breath cycles found, respiratory rate may be unreliable!')
end

call_breath_seg_data = call_seg_data;
[call_breath_seg_data.breath_seg] = breath_seg_data{:};

end


%% LOCAL HELPERS

function [breath_seg_data_cond] = segmentEachCondition( ...
    breathing, ...
    stim_i, fs, ...
    dur_thresh, exp_thresh, insp_thresh, ...
    stim_window_pre_fr, stim_window_post_fr, ...
    smooth_window, stim_induced_insp_window_f, ...
    exp_amp_window_fr, insp_amp_window_fr)
% LOCAL HELPER FUNCTION    
% for all breathing data in given condition, run segmentation code trial by
% trial
    breath_seg_data_cond = [];

    pre_stim_amp_normalize_window = msToFrames([-1000 0], fs, stim_i);


    for tr = size(breathing, 1):-1:1
        
        b = breathing(tr, :);  % data for 1 stim trial
        
        % roughly recenter around 0 so code works
        b = b - median(b);

        % roughly segment breaths
        [~, exps] = ek_segmentBreaths_current(b, insp_thresh, exp_thresh, dur_thresh);
    
        exps_pre = exps(exps < stim_i);

        try % recenter based on these segmented breaths
            centered = b - mean(b(exps_pre(1) : exps_pre(end)));
            % NOTE: if there's only 1 exp found before stim, this statement
            % has no effect

            % re-segment based on centered breathing data
            [insps, exps] = ek_segmentBreaths_current(centered, insp_thresh, exp_thresh, dur_thresh);
        
            breath_seg_data_cond(tr).centered = centered;
    
            breath_seg_data_cond(tr).exps_pre = exps(exps < (stim_i - stim_window_pre_fr));
            breath_seg_data_cond(tr).insps_pre = insps(insps < (stim_i - stim_window_pre_fr));
        
            % post & peri should probably not be separated...
            breath_seg_data_cond(tr).exps_post = exps(exps > (stim_i + stim_window_post_fr));
            breath_seg_data_cond(tr).insps_post = insps(insps > (stim_i + stim_window_post_fr));
            
            breath_seg_data_cond(tr).exps_peri = exps(exps >= (stim_i - stim_window_pre_fr) & exps <= (stim_i + stim_window_post_fr));
            breath_seg_data_cond(tr).insps_peri = insps(insps >= (stim_i - stim_window_pre_fr) & insps <= (stim_i + stim_window_post_fr));
    

            % respiratory rate: from first to final insp in pre-window
            insps_pre = breath_seg_data_cond(tr).insps_pre;
            n_breaths = length(insps_pre) - 1;
            duration = range(insps_pre) / fs;
            
            if n_breaths >= 1
                breath_seg_data_cond(tr).respiratory_rate = n_breaths / duration;
                breath_seg_data_cond(tr).n_pre_stim_breath_cycles = n_breaths;
            else
                breath_seg_data_cond(tr).respiratory_rate = NaN;
                breath_seg_data_cond(tr).n_pre_stim_breath_cycles = 0;
            end
            
            % inspiratory amplitude
            pre_window = centered(pre_stim_amp_normalize_window(1) : pre_stim_amp_normalize_window(2) );

            pre_stim_min = min(pre_window);
            post_stim_min = min( centered(insp_amp_window_fr(1): insp_amp_window_fr(2)) );
            breath_seg_data_cond(tr).insp_amplitude = post_stim_min / pre_stim_min;


            % expiratory amplitude
            pre_stim_max = max(pre_window);
            post_stim_max = max( centered(exp_amp_window_fr(1): exp_amp_window_fr(2)) );
            breath_seg_data_cond(tr).exp_amplitude = post_stim_max / pre_stim_max;


            % expiratory latency 
            latency_exp = (breath_seg_data_cond(tr).exps_post(1) - stim_i) * 1000 / fs;
            breath_seg_data_cond(tr).latency_exp = latency_exp;

            breath_seg_data_cond(tr).error = 0;

        catch err
            breath_seg_data_cond(tr).error = err;

        end


        % LATENCIES
        % insp
        breath_seg_data_cond(tr).latency_insp_f = getInspiratoryLatency(breathing(tr, :), stim_induced_insp_window_f, smooth_window);
        breath_seg_data_cond(tr).latency_insp = [breath_seg_data_cond(tr).latency_insp_f] / fs * 1000;
        
    end

    breath_seg_data_cond = breath_seg_data_cond';
end 


function i = getInspiratoryLatency(y, window, smooth_window)
    % get index of minimum second derivative in window after stim
    % pass in filtered breathing data

    yp = ddt(y);
    yp = smoothdata(yp, 'movmean', smooth_window);

    ypp = ddt(yp);  
    ypp = smoothdata(ypp, 'movmean', smooth_window);
    ypp = [0 0 ypp]; % zero padding for consistent indexing

    [~, i] = min(ypp( window(1) : window(2) ));
end


function dydt = ddt(y)
    % derivative of a discrete time series
    dydt = minus(y(2:end), y(1:end-1));
end

function t_fr = msToFrames(t_ms, fs, stim_i)
% convert stim-centered times in ms to trial-centered frames
% 
% maybe makes code more readable? idk
% 

    t_fr =  (t_ms * fs / 1000) + stim_i;
end