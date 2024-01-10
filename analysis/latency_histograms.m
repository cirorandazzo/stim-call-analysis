
clear;
close all;

%%

bird_file = {
    ["bk68wh15", "PAm", "/Users/cirorandazzo/ek-spectral-analysis/processed_data/bk68wh15/fda271e/spectral_features-bk68wh15.mat"];
    ["pu65bk36", "DM", "/Users/cirorandazzo/ek-spectral-analysis/processed_data/pu65bk36/7d605cb/spectral_features-pu65bk36.mat"];
};

fs = 30000;
stim_i = 30001;

figs = [];

%%
for i=1:length(bird_file)
    bird = bird_file{i}(1);
    region = bird_file{i}(2);
    file = bird_file{i}(3);
    title_str = region + " Stim (" + bird + ")";
    
    load(file);

    if strcmp(bird, "pu65bk36")
        spectral_features = spectral_features(1);  % just baseline
    end

    i_one_call = spectral_features.one_call;
    
    latencies = spectral_features.onsets;
    latencies = [latencies{i_one_call}];
    latencies = (latencies - stim_i) *1000/fs;

    figs = [figs figure()];
    histogram(latencies);
    title(title_str);
    xlabel("Latency (ms)")
    ylabel("Count")
    xlim([25 165]);

    %%

    max_to_plot = 3;
    rows=3; cols=1;


    n = 1024;
    overlap = 1020;
    sigma = 3;
    f_low = 500;
    f_high = 10000;
    spec_threshold = .04;

    select_trials = spectral_features.one_call;
    if length(select_trials) > max_to_plot  % take subset of trials if there are too many
        % select_trials = select_trials(1:max_to_plot);  % from start
        select_trials = select_trials(randi(length(select_trials), max_to_plot));  % random subset 
    end


    a = spectral_features.audio(select_trials, :);
    onsets = spectral_features.onsets;
    offsets = spectral_features.offsets;

    figs = [figs figure()];
    % f.WindowState = 'maximized';
    % set(f,'Position',[-1079 -295 1080 869]);
    
    rows = ceil(length(select_trials)/cols);
    
    for tr=1:length(select_trials)
        orig_i = select_trials(tr);
    
        filtsong=pj_bandpass(a(tr,:), fs, f_low, f_high, 'butterworth');
        % noise_threshold = q * median(abs(filtsong));
    
        subplot(rows,cols,tr);
    
        ms_off = offsets{orig_i} * 1000 / fs;
        ms_on = onsets{orig_i} * 1000 / fs;
    
        plot_spectr_callLines(filtsong, ms_on, ms_off, fs, spec_threshold, n , overlap, f_low, f_high);

        if tr==1
            title(title_str);
        end
        subtitle("tr"+string(select_trials(tr)));
        
        hold on;
        plot([stim_i*1000/fs stim_i*1000/fs], [0, 16000]);
        xlim([stim_i-10000 stim_i+10000]*1000 / fs);
        
        hold off;
    end

    clear spectral_features;
end

for f = 1:length(figs)
    set(figs(f).Children, 'TickDir', 'out', 'FontSize', 30);
end