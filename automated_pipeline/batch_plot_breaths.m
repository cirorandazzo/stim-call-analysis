% batch_plot_spectrograms.m
% 2024.06.7
% 
% Batch plot the spectrograms from multiple processed data files.
% 
% NOTE: the parfor (parallel for) loop has some memory leak. If you get a memory error, just re-run the code with `skip_existing=True`, or replace parfor with for (will take a lot longer.)

% for stim data
fs = 30000;
stim_i = 45001;  % stimulation onset frame index

data_files = {
    "C:\Users\ciro\Documents\code\stim-call-analysis\data\processed\bu69bu75\bu69bu75-data.mat"
    "C:\Users\ciro\Documents\code\stim-call-analysis\data\processed\pk15\pk15-data.mat"
    "C:\Users\ciro\Documents\code\stim-call-analysis\data\processed\pk30gr9\pk30gr9-data.mat"
    "C:\Users\ciro\Documents\code\stim-call-analysis\data\processed\pk48br83\pk48br83-data.mat"
    "C:\Users\ciro\Documents\code\stim-call-analysis\data\processed\pu65bk36\pu65bk36-data.mat"
};

save_root = "C:\Users\ciro\Documents\code\stim-call-analysis\data\figures\breaths";

ext = '.jpeg';
skip_existing = false;
save_wav = true;
xl = [200 2000];  % ms. not zeroed on stimulus.

call_count_cats = {'one_call', 'no_calls', 'multi_calls'};

% PARAMETERS
amp_window_fr = ([10 350] * fs/1000) + stim_i;  % default_params
pre_stim_amp_normalize_window = [-1 0] * fs + stim_i;  % hard coded in s4

% insp_window_length_f = 100 * fs / 1000;  % default 35; p.breath_seg.stim_induced_insp_window_ms * fs / 1000
insp_window_length_f = 35 * fs / 1000;  % p.breath_seg.stim_induced_insp_window_ms * fs / 1000

smooth_window = 50;  %  default_params derivative_smooth_window_f

crosscheck = true;  % requires that computed parameters == computed parameters of datastruct

errors = struct('name', {}, 'error', {});
%%
close all
mkdir(save_root)

set(groot, 'DefaultFigureVisible','off');  % suppress figures

start = tic;
for i_df = 1:length(data_files)
    data = load(data_files{i_df}, 'data').data;
    bird_name = data(1).bird;
    x = [1 : length(data(1).audio(1,:))] / fs * 1000;  % ms values for plotting
    
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

            folder = fullfile(save_root, bird_name, cond_string, call_count_cats{i_ccc});
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
    
                    hold on
    
                    % audio
                    centered = data_ic.breath_seg(tr).centered;
                    y_min = min(centered, [], 'all');
                    y_max = max(centered, [], 'all');
                    plot(x, centered)
    
                    % call lines
                    onsets = data_ic.call_seg.onsets{tr} * 1000/fs;
                    offsets = data_ic.call_seg.offsets{tr} * 1000/fs;
                    
                    addCallLinesToPlot(onsets, offsets, [y_min y_max])
    
                    % stimulus
                    plot([stim_i stim_i] * 1000/fs, [y_min y_max], Color='k', LineStyle='--', LineWidth=1);
                    
                    % AMPLITUDES
                    % inspiratory amplitude
                    pre_window = centered(pre_stim_amp_normalize_window(1) : pre_stim_amp_normalize_window(2) );
                    post_window = centered(amp_window_fr(1): amp_window_fr(2));
        
                    [pre_stim_min, i_min_pre] = min(pre_window);
                    [post_stim_min, i_min_post] = min(post_window);
                    
                    if crosscheck
                        assert(data_ic.breath_seg(tr).insp_amplitude == post_stim_min / pre_stim_min);
                    end

                    % expiratory amplitude
                    [pre_stim_max, i_max_pre] = max(pre_window);
                    [post_stim_max, i_max_post] = max(post_window);
                    
                    if crosscheck
                        assert(data_ic.breath_seg(tr).exp_amplitude == post_stim_max / pre_stim_max);
                    end

                    % insp latency
                    % LATENCIES
                    
                    latency_insp_f = getInspiratoryLatency(data_ic.breathing(tr, :), stim_i, insp_window_length_f, smooth_window);
                    
                    if crosscheck
                        assert(latency_insp_f == data_ic.breath_seg(tr).latency_insp_f)
                    end

                    % scatter plot
                    ms_maxes = [i_max_pre + pre_stim_amp_normalize_window(1), i_max_post + amp_window_fr(1)] * 1000 / fs;
                    ms_mins = [i_min_pre + pre_stim_amp_normalize_window(1), i_min_post + stim_i] * 1000 / fs;
                    ms_latency = (latency_insp_f + stim_i) * 1000 / fs;

                    scatter(ms_maxes, [pre_stim_max, post_stim_max], [], 'r')  % EXPS
                    scatter(ms_mins, [pre_stim_min, post_stim_min], [], 'b') % INSPS
                    
                    scatter(ms_latency, centered(stim_i+latency_insp_f), [], 'g')  % INSP LATENCY

                    hold off
    
                    %% plot a second thing
                    % ax2 = subplot(2,1,2);
                    % hold on;
                    % hold off;
    
                    %% link xaxes & save figure
                    % linkaxes([ax2 ax1], 'x')
                    xlim(xl);
                    
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