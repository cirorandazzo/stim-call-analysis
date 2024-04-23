function [data] = s5_call_vicinity(...
    call_breath_seg_data, ...
    fs, ...
    stim_i, ...
    l_post_window ...
)

    f_post = l_post_window * fs / 1000;

    for c=1:size(call_breath_seg_data,1)  % for each condition (row in struct)
        trials = call_breath_seg_data(c).call_seg.one_call;

        for i=length(trials):-1:1  % for all trials with one call
            tr = trials(i);

            % get pre-stim expirations/inspirations
            exps_pre = call_breath_seg_data(c).breath_seg(tr).exps_pre;
            insps_pre = call_breath_seg_data(c).breath_seg(tr).insps_pre;

            % get last insp before stim
            try
                last_insp = insps_pre(end);
                assert(stim_i > last_insp);

                % get exp right before last insp
                possible_exps = exps_pre(exps_pre < last_insp);
                last_exp = max(possible_exps);
    
                % normalize all breathing to mean value of n-1 expiration
    
                nMin1_exp = call_breath_seg_data(c).breath_seg(tr).centered(last_exp:last_insp);
                nMin1_exp_mean = mean(nMin1_exp);
                breathing_norm = call_breath_seg_data(c).breathing_filt(tr, :) / nMin1_exp_mean;
    
                % load call onset/offset
                onset = call_breath_seg_data(c).call_seg.onsets{tr};
                offset = call_breath_seg_data(c).call_seg.offsets{tr};
    
                % get windows & save mean
                %  - stim -> call onset
                pre_call_br = breathing_norm(stim_i:onset);
    
                call_breath_seg_data(c).vicinity(i).pre_call_breath_mean = mean(pre_call_br);
    
                %  - call (onset:offset, from audio segmentation)
    
                call_br = breathing_norm(onset:offset);
    
                call_breath_seg_data(c).vicinity(i).call_breath_mean = mean(call_br);
    
                %  - post call (call offset : offset + post_window)
                post_window_br = breathing_norm(offset:offset+f_post);
    
                call_breath_seg_data(c).vicinity(i).post_call_breath_mean = mean(post_window_br);

                call_breath_seg_data(c).vicinity(i).issue = false;
            catch err
                call_breath_seg_data(c).vicinity(i).issue = err;
            end

            

        end
    end

    data = call_breath_seg_data;
end