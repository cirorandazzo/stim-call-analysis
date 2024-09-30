function [p_vals, stats, distrs] = get_stats_dm_pam(bird_summary, fields)
% get_stats_dm_pam
% 2024.07.19 CDR
% 
% Given bird by bird summary struct, runs Mann-Whitney U-test comparisons on specified 
% fields (MATLAB function `ranksum`).


    [C, ~, ic] = unique({bird_summary.group});

    distrs = struct('group', C);
    stats = struct('group', C);
    p_vals = [];

    for i_f = 1:length(fields)
        f = fields(i_f);
    
        for i_g = 1:length(distrs)
            this_group = bird_summary(i_g==ic);
            distrs(i_g).(f) = [this_group(:).(f)];
            stats(i_g).(f) = make_stat_summary([this_group(:).(f)]);
        end
    
        p_vals.(f) = ranksum(distrs(:).(f));
    end

end