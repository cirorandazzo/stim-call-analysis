function summary_group = make_group_summaries(summary_bird)
% make_group_summaries.m
% 2024.04.30 CDR
% 
% given struct summary_bird where each row has information about 1 individual,
% make struct summary_group where each row has information about 1 group 

    groups = unique({summary_bird.group});

    summary_group = [];

    for i_group = length(groups):-1:1
        % group name
        group = groups{i_group};
        summary_group(i_group).group = group;

        % slice records from this group
        this_group = summary_bird(strcmp({summary_bird.group}, group));

        % merged 
        summary_group(i_group).n_birds = length(this_group);
        summary_group(i_group).n_calls = sum([this_group.n_one_call]);

        % merged latency arrays
        summary_group(i_group).insp_latencies = [this_group.insp_latencies];
        summary_group(i_group).audio_latencies = [this_group.audio_latencies];
        
        summary_group(i_group).birds = {this_group.bird};

        % assert that everything has the right length
        assert(summary_group(i_group).n_calls == length(summary_group(i_group).insp_latencies));
        assert(summary_group(i_group).n_calls == length(summary_group(i_group).audio_latencies));
    end
end