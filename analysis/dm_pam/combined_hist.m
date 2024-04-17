
% plots combined group latency historgram given struct 'files' from dm_pam_checks

conds = unique({files.cond});
savefile = '/Users/cirorandazzo/code/stim-call-analysis/data/figures/combined_hist.png';

lat_data = [];

%%
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

        latencies_c = [latencies_c data.call_seg.acoustic_features.latencies{:}];
    end

    lat_data(i).latencies = latencies_c;
end

%%

fig = figure;
xlabel('Latency to call (ms)');
ylabel('Probability');
title('Audio segmented call latency');

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


