%% dm_pam_checks.m
% 2024.04.15 CDR
% 
% some quick summary statistics from processed data in a given folder.

proc_folder = '/Users/cirorandazzo/code/stim-call-analysis/data/processed/20240419';
files = dir([proc_folder filesep '**' filesep '*_data.mat'] );

%%

to_plot = {'insp'};
% to_plot = {'exp', 'aud', 'insp', 'breath_trace'};
savefolder = '/Users/cirorandazzo/code/stim-call-analysis/data/figures';

for d=1:length(to_plot)
    mkdir(strcat(savefolder, filesep, to_plot{d}));
end

exp_tout = 10;  % time (ms) after stim in which to ignore expiration (for latency)

stim_i = 45001;
fs = 30000;

xl = [0 200];
bin_width = 5;

summary = [];
summary.bird = [];
summary.cond = [];
summary.n_rows = [];
summary.n_one_call = [];
summary.n_no_calls = [];
summary.n_multi_calls = [];

for i = length(files):-1:1
    f = files(i);
    fpath = [f.folder filesep f.name];
    disp(fpath);

    load(fpath);  % loads var `data`
    
    bird = replace(f.name, '_data.mat', '');
    pth = split(f.folder, filesep);
    summary(i).cond = pth{length(pth)};

    summary(i).bird = bird;
    summary(i).n_rows = size(data.breath_seg, 1);
    summary(i).n_one_call = size(data.call_seg.one_call, 1);
    summary(i).n_no_calls = size(data.call_seg.no_calls, 1);
    summary(i).n_multi_calls = size(data.call_seg.multi_calls, 1);

    i_one_call = data.call_seg.one_call;

    if ismember('exp', to_plot)
        % EXPIRATORY LATENCY
        exp_latencies = [data.breath_seg.latency_exp];
        exp_latencies = exp_latencies(i_one_call);
        
        fig = histogram(exp_latencies, 'BinWidth', bin_width);
        title([bird ' exp latency (' int2str(length(exp_latencies)) ')']);
        xlabel("Latency to Expiration (ms)");
        ylabel("Count");
        % xlim(xl);
    
        saveas(fig, [savefolder filesep 'exp' filesep bird '_expHist.png']);
        close;
    end

    if ismember('insp', to_plot)
        % INSPIRATORY LATENCY
        % insp_latencies = arrayfun(@(tr) data.breath_seg(tr).insps_post(1) - stim_i, i_one_call);  % first insp after call
        % insp_latencies = insp_latencies*1000/fs;

        insp_latencies = [data.breath_seg.latency_insp];
        insp_latencies = insp_latencies(i_one_call);

        summary(i).min_insp_lat = min(insp_latencies);
        summary(i).max_insp_lat = max(insp_latencies);

        fig = histogram(insp_latencies, 'BinWidth', bin_width);
        title([bird ' insp latency (' int2str(length(insp_latencies)) ')']);
        xlabel("Latency to Inspiration (ms)");
        ylabel("Count");

        % xlim([0,40])
        % xlim(xl);
    
        saveas(fig, [savefolder filesep 'insp' filesep bird '_inspHist.png']);
        close;
    end
    
    if ismember('aud', to_plot)
        % CALL LATENCY
        call_latencies = [data.call_seg.acoustic_features.latencies{:}];
    
        fig = histogram(call_latencies, 'BinWidth', bin_width);
        title([bird ' audio latency (' int2str(length(i_one_call)) ')']);
        xlabel("Latency to Call (ms)");
        ylabel("Count");
        % xlim(xl);
    
        saveas(fig, [savefolder filesep 'aud' filesep bird '_audHist.png']);
        close;
    end

    if ismember('breath_trace', to_plot)
        % BREATH TRACES
        fig = figure;
        hold on;

        title([bird ' breath traces (' int2str(length(i_one_call)) ')']);
        xlabel('Time since stim (ms)')
        ylabel('Pressure')
        
        trs_one_call = data.call_seg.one_call;
        rows_to_plot = data.breathing_filt(trs_one_call, :);
        x = f2ms(1:size(rows_to_plot, 2), fs, stim_i);
        
        plot(x, rows_to_plot', 'Color', '#c3c3c3', 'LineWidth', 0.5);  % transpose is very important, might crash computer otherwise :(
        plot(x, mean(rows_to_plot, 1), 'black', 'LineWidth', 4);
        
        insp_latencies = [data.breath_seg.latency_insp];
        insp_latencies = insp_latencies(trs_one_call);

        latency_insp_f = [data.breath_seg.latency_insp_f];
        latency_insp_f = latency_insp_f(trs_one_call);

        ys = arrayfun(@(j) rows_to_plot(j, stim_i+latency_insp_f(j)), 1:numel(trs_one_call));

        scatter(insp_latencies, ys, 'green', 'filled');

        l = min(rows_to_plot, [], 'all'); 
        h = max(rows_to_plot, [], 'all');
        
        plot([0 0], [l h], 'Color', 'black', 'LineStyle', '--')
        
        xlim([-100 200]);

        saveas(fig, [savefolder filesep 'breath_trace' filesep bird '_breathTraces.png']);

        hold off;
        close;
    end
end

%%

function ms = f2ms(f, fs, stim_i)
    ms = minus(f, stim_i) * 1000 / fs;
end

%%

% i=4;
% f=files(i);
% load([f.folder filesep f.name]);  % loads var `data`
% 
% i_one_call = data.call_seg.one_call;
% 
% for q=1:length(i_one_call)
% 
%     j=i_one_call(q);
% 
%     y = data.audio_filt(j, :);
% 
%     figure;
%     plot(y)
% 
% end

%%

























