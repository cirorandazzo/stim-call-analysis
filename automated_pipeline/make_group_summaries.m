function summary_group = make_group_summaries(summary_bird)
% make_group_summaries.m
% 2024.04.30 CDR
% 
% given struct summary_bird where each row has information about 1 individual,
% make struct summary_group where each row has information about 1 group 
% 
% INPUT:
%     summary_bird:     A structure containing information about individual
%                       birds. Each row of the structure should represent data 
%                       for one bird and should include the following fields:
%           - group:    Group name or identifier to which the bird belongs.
%           - n_one_call:   Number of calls made by the bird.
%           - insp_latencies:   Array of inspiration latencies for the bird.
%           - audio_latencies:  Array of audio latencies for the bird.
%           - bird: Name or identifier of the bird.
% 
% OUTPUT:
%     summary_group:    A structure array containing summary data for each 
%                       group. Each element of the array corresponds to one 
%                       group and includes the following fields:
%           - group:    Group name or identifier.
%           - n_birds:  Number of birds in the group.
%           - n_calls:  Total number of calls made by all birds in the group.
%           - insp_latencies:   Merged array of inspiration latencies for all 
%                               birds in the group.
%           - audio_latencies:  Merged array of audio latencies for all 
%                               birds in the group.
%           - birds:    Cell array containing names or identifiers of birds in 
%                       the group.


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

        % call success rate
        summary_group(i_group).call_success_rate = [this_group.call_success_rate];

        % assert that everything has the right length
        assert(summary_group(i_group).n_calls == length(summary_group(i_group).insp_latencies));
        assert(summary_group(i_group).n_calls == length(summary_group(i_group).audio_latencies));
    end
end