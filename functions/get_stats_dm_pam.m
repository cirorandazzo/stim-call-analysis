function [p_vals] = get_stats_dm_pam(summary_bird, fields)
% get_stats_dm_pam
% 2024.07.19 CDR
% 
% Given bird by bird summary struct, runs Mann-Whitney U-test comparisons 
% on specified fields (MATLAB function `ranksum`). If this field is a
% scalar for each bird, computes ranksum directly. If this field is itself
% a distribution, computes ranksum on the median for each bird.
% 

    % preallocate struct where each row is a group (eg, dm/pam)
    [C, ~, ic] = unique({summary_bird.group});
    distrs = struct('group', C);
    p_vals = struct();

    for i_f = 1:length(fields)
        f = fields(i_f);
        for i_g = 1:length(C)
            distrs(i_g).(f) = [summary_bird(ic == i_g).(f)];        
        end
        p_vals.(f) = ranksum(distrs(:).(f));
    end

end