% batch_plot_breaths.m
% 2024.06.7
% 
% Batch plot the breaths from multiple processed data files.
% 
% NOTE: removed parfor from this one, it's decently fast.

p = default_params([], fs=30000);  % get default parameters

fs = p.fs;
stim_i = p.window.stim_i;  % stimulation onset frame index

% focus roughly on stim window 
xl = [stim_i-fs stim_i+(fs/2)] * 1000 / fs;  % ms. not zeroed on stimulus.
save_root = "./data/figures/breaths";

% xl = [0 stim_i+fs] * 1000 / fs;
% save_root = "C:\Users\ciro\Documents\code\stim-call-analysis\data\figures\breaths-prestim";

data_files = dir("./data/processed/**/*data.mat");
data_files = arrayfun(@(x) fullfile(x.folder, x.name), data_files, UniformOutput=false);

ext = '.jpeg';
skip_existing = false;
save_wav = true;

call_count_cats = {'one_call', 'no_calls', 'multi_calls'};

crosscheck = true;  % requires that computed parameters == computed parameters of datastruct

errors = struct('name', {}, 'error', {});

%% PARAMETERS
exp_amp_window_fr = stim_i + (fs / 1000 * p.call_seg.post_stim_call_window_ms);
insp_amp_window_fr = stim_i + (fs / 1000 * p.breath_seg.insp_amp_window_ms);

pre_stim_amp_normalize_window = [-1 0] * fs + stim_i;  % hard coded in s4

insp_window_length_f = p.breath_seg.stim_induced_insp_window_ms * fs / 1000;  % default 35ms

smooth_window = p.breath_seg.derivative_smooth_window_f;

%% plot options

exp_color = 'r';
insp_color = 'b';
lw = 0.5;

%%
close all
mkdir(save_root)

set(groot, 'DefaultFigureVisible','off');  % suppress figures

start = tic;
for i_df = 1:length(data_files)
    data = load(data_files{i_df}, 'data').data;
    
    if isfield(data(1), 'bird')
        bird_name = data(1).bird;

    else  % bird name not stored in dmpam
        [~,bird_name,~] = fileparts(data_files{i_df});
        bird_name = split(bird_name, '-data');
        bird_name = bird_name{1};
    end
    
    x = [1 : length(data(1).audio(1,:))] / fs * 1000;  % ms values for plotting
    
    % normalize all traces across all conditions to same y_min/y_max
    y_min = min(arrayfun(@(x) min(vertcat(x.breath_seg.centered), [], "all"), data));
    y_max = max(arrayfun(@(x) max(vertcat(x.breath_seg.centered), [], "all"), data));

    % make 1 figure that's recycled (prevent memory leak)
    fig = figure;
    set(fig, "Position", [2   356   894   680]);

    for i_c=1:length(data)
    
        if length(data)>1
            cond_string = strcat(bird_name, '-', data(i_c).drug, '_', data(i_c).current);
        else
            cond_string = bird_name;
        end
        
        for i_ccc = 1:length(call_count_cats)
        % parfor i_ccc = 1:length(call_count_cats)  % replace top-level parfor with this one if only plotting for 1 bird
            disp(append('Plotting: ', cond_string, ', ', call_count_cats{i_ccc}))
            tic
            trs = data(i_c).call_seg.(call_count_cats{i_ccc});
    
            % don't make folder if condition + call count is empty
            if isempty(trs)
                trs = [];
                continue
            end

            folder = fullfile(save_root, cond_string, call_count_cats{i_ccc});
            mkdir(folder);
    
            data_ic = data(i_c);

            
            for i_tr=1:length(trs)
                tr = trs(i_tr);
                figname = strcat(cond_string, "-tr", string(tr), ext);
                figpath = fullfile(folder, figname);

                if skip_existing & isfile(figpath)
                    continue
                end                

                %% plot centered waveform
                try
                    % ax1 = subplot(2,1,1);
                    clf(fig)
                    
                    subtitle("tr " + string(tr));
                    title(cond_string, 'Interpreter','none');
    
                    bs_tr = data_ic.breath_seg(tr);

                    hold on;
    
                    % BREATHING
                    centered = bs_tr.centered;

                    % old: normalize each trace to its own min/max
                    % y_min = min(centered, [], 'all');
                    % y_max = max(centered, [], 'all');
                    plot(x, centered)
    
                    % CALL LINES (audio segmented)
                    onsets = data_ic.call_seg.onsets{tr} * 1000/fs;
                    offsets = data_ic.call_seg.offsets{tr} * 1000/fs;
                    
                    addCallLinesToPlot(onsets, offsets, [y_min y_max], LineWidth=lw);

                    % stimulus
                    plot([stim_i stim_i] * 1000/fs, [y_min y_max], Color='k', LineStyle='--', LineWidth=lw);
                    
                    % AMPLITUDES
                    % inspiratory amplitude
                    pre_window = centered(pre_stim_amp_normalize_window(1) : pre_stim_amp_normalize_window(2) );
                    insp_window = centered(insp_amp_window_fr(1): insp_amp_window_fr(2));
                    exp_window = centered(exp_amp_window_fr(1): exp_amp_window_fr(2));

                    [pre_stim_min, i_min_pre] = min(pre_window);
                    [post_stim_min, i_min_post] = min(insp_window);
                    
                    if crosscheck
                        assert(bs_tr.insp_amplitude == post_stim_min / pre_stim_min);
                    end

                    % expiratory amplitude
                    [pre_stim_max, i_max_pre] = max(pre_window);
                    [post_stim_max, i_max_post] = max(exp_window);
                    
                    if crosscheck
                        assert(bs_tr.exp_amplitude == post_stim_max / pre_stim_max);
                    end

                    % LATENCIES
                    % insp latency
                    latency_insp_f = bs_tr.latency_insp_f;

                    % scatter plot
                    ms_maxes = [i_max_pre + pre_stim_amp_normalize_window(1), i_max_post + exp_amp_window_fr(1)] * 1000 / fs;
                    ms_mins = [i_min_pre + pre_stim_amp_normalize_window(1), i_min_post + insp_amp_window_fr(1)] * 1000 / fs;
                    ms_latency = (latency_insp_f + stim_i) * 1000 / fs;

                    scatter(ms_maxes, [pre_stim_max, post_stim_max], [], exp_color)  % EXPS
                    scatter(ms_mins, [pre_stim_min, post_stim_min], [], insp_color) % INSPS
                    
                    scatter(ms_latency, centered(stim_i+latency_insp_f), [], 'g')  % INSP LATENCY

                    % BREATH ZERO CROSSINGS

                    % exclude first post-stim exp, used for latency &
                    % plotted with diff marker
                    insps = [bs_tr.insps_pre bs_tr.insps_peri bs_tr.insps_post];
                    exps = [bs_tr.exps_pre bs_tr.exps_peri bs_tr.exps_post(2:end)];

                    scatter(insps * 1000/fs, centered(insps), insp_color, Marker='+');
                    scatter(exps  * 1000/fs, centered(exps),  exp_color,  Marker='+');

                    % EXP-LATENCY point: diff marker
                    scatter(bs_tr.exps_post(1)  * 1000/fs, centered(bs_tr.exps_post(1)),  exp_color,  Marker='x');

                    % 
                    ylim([y_min, y_max]);
                    hold off;
                    %% plot a second thing
                    % ax2 = subplot(2,1,2);
                    % hold on;
                    % hold off;
    
                    %% link xaxes & save figure
                    % linkaxes([ax2 ax1], 'x')
                    xlim(xl);
                    xlabel('Time since trial onset (ms)')
                    
                    saveas( fig, figpath );
                catch e
                   errors(end+1) = struct('name', figname, 'error', e);
                end
            end

            toc  % time elapsed for this condition + call_count
        end

        % get(groot, 'Children')  % prints number of figures currently
        % open, helpful for debugging memory leak
    end

    close all hidden;
end

% delete(gcp('nocreate'));

disp('Finished plotting! Total time:')
toc(start);
set(groot, 'DefaultFigureVisible','on');  % un-suppress figures


%%

function i = getInspiratoryLatency(y, stim_i, insp_dur_max_f, smooth_window)
    % get index of minimum second derivative in window after stim
    % pass in filtered breathing data

    yp = ddt(y);
    yp = smoothdata(yp, 'movmean', smooth_window);

    ypp = ddt(yp);  
    ypp = smoothdata(ypp, 'movmean', smooth_window);
    ypp = [0 0 ypp]; % zero padding for consistent indexing

    wind = stim_i+1 : stim_i+insp_dur_max_f;

    [~, i] = min(ypp(wind));
end


function dydt = ddt(y)
    % derivative of a discrete time series
    dydt = minus(y(2:end), y(1:end-1));
end