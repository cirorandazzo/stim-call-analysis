function [call_breath_seg_data] = s4_segment_breaths(...
    call_seg_data, fs, stim_i, dur_thresh, exp_thresh, insp_thresh, ...
    pre_delay, post_delay)
% S3_SEGMENT_BREATHS
% 2024.02.13 CDR based on code from ZK
% 
% - return data struct with segmented breaths
% - takes breathing data for every condition in struct (cell of n x fr
% matrices)

f_post = post_delay * fs / 1000;
f_pre = pre_delay * fs / 1000;

breathing = {call_seg_data(:).breathing_filt};

for i=1:size(breathing,1)  % for each condition stored in call_seg_data
    breath_seg_data = cellfun( ...  % run for each condition separately (see local helper function segment_each_cond)
        @(x) segment_each_cond(x, stim_i, fs, dur_thresh, exp_thresh, insp_thresh, pre_delay, post_delay), ...
        breathing, ...
        'UniformOutput', 0);
end

call_breath_seg_data = call_seg_data;
[call_breath_seg_data.breath_seg] = breath_seg_data{:};

end


%%

function [breath_seg_data_cond] = segment_each_cond( ...
    breathing_mat, stim_i, fs, dur_thresh, exp_thresh, insp_thresh, ...
    f_pre, f_post)
% LOCAL HELPER FUNCTION    
% for all breathing data in given condition, run segmentation code trial by
% trial
    breath_seg_data_cond = [];

    for tr = size(breathing_mat, 1):-1:1
        a = breathing_mat(tr, :);  % data for 1 stim trial
        
        % roughly recenter around 0 so code works
        a = a - median(a);

        % roughly segment breaths
        [insps, exps] = ek_segmentBreaths_current(a, insp_thresh, exp_thresh, dur_thresh);
    
        exps_pre = exps(exps < stim_i);

        % assert(length(exps_pre) > 1);

        % recenter based on these segmented breaths
        centered = ek_centerBreaths(a, exps_pre(1), exps_pre(end));
            % NOTE: if there's only 1 exp found before stim, this statement
            % has no effect

        % re-segment based on centered breathing data
        [insps, exps] = ek_segmentBreaths_current(centered, insp_thresh, exp_thresh, dur_thresh);
    
        breath_seg_data_cond(tr).centered = centered;

        breath_seg_data_cond(tr).exps_pre = exps(exps < stim_i - f_pre);
        breath_seg_data_cond(tr).insps_pre = insps(insps < stim_i - f_pre);
    
        breath_seg_data_cond(tr).exps_post = exps(exps > stim_i + f_post);
        breath_seg_data_cond(tr).insps_post = insps(insps > stim_i + f_post);

        breath_seg_data_cond(tr).latency_exp = (breath_seg_data_cond(tr).exps_post(1) - stim_i) * 1000 / fs;
    end

    breath_seg_data_cond = breath_seg_data_cond';
end 