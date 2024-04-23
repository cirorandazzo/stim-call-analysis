
% plots combined group latency historgram given struct 'files' from dm_pam_checks

% to_plot = 'insp_latency';
to_plot = 'audio_latency';

savefile = '/Users/cirorandazzo/code/stim-call-analysis/data/figures/aud_combined_hist.png';

%%
% add condition info from last folder in filepath

conds = cellfun(@(x) split(x,filesep), {files.folder}, 'UniformOutput', 0);
conds = cellfun(@(x) x{end}, conds, 'UniformOutput', 0);
[files.cond] = conds{:};


conds = unique({files.cond});

%%
lat_data = [];

for i=length(conds):-1:1
    c = conds{i};
    lat_data(i).cond = c;

    files_c = files(strcmp({files.cond}, c));
    n_birds = length(files_c);

    lat_data(i).n_birds = n_birds;

    latencies_c = [];

    for j=1:n_birds
        f = files_c(j);

        load([f.folder filesep f.name]);  % loads var `data`

        i_one_call = [data.call_seg.one_call];

        if strcmp(to_plot, 'audio_latency')
            to_add = [data.call_seg.acoustic_features.latencies{:}];
        elseif strcmp(to_plot, 'insp_latency')
            to_add = [data.breath_seg.latency_insp];
            to_add = to_add(i_one_call);
        else
            error('not a valid plot type');
        end

        latencies_c = [latencies_c to_add];
    end

    lat_data(i).latencies = latencies_c;
end

%%

fig = figure;
if strcmp(to_plot, 'audio_latency')
    xlabel('Latency to call (ms)');
    title('Audio segmented call latency');

elseif strcmp(to_plot, 'insp_latency')
    xlabel('Latency to insp (ms)');
    title('Stim-induced inspiration latency');

else
    error('not a valid plot type');

end


ylabel('Probability');

hold on;

leg = [];
for i=1:length(lat_data)

    % construct legend label
    cond = lat_data(i).cond;
    n_calls = length([lat_data(i).latencies]);
    n_birds = lat_data(i).n_birds;

    lbl = cond + " (" + n_calls + " calls / " + n_birds + " birds)";
    leg = [leg lbl];

    % plot
    histogram([lat_data(i).latencies], ...
        'BinWidth', 2 ...
        , 'Normalization', 'probability' ...
        );
end

legend(leg);
hold off;

%%

saveas(fig, savefile);


