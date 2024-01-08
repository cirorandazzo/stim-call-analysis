%% d_summary.m
% 2023.01.08 CDR
% 
% Summary measures/statistics on spectral features

%% TODO: load file
% just carrying over struct in workspace right now, since i dont want to
% save it until it's more complete

% clear;
% close all;

% file_path = '/Users/cirorandazzo/ek-spectral-analysis/';
% load(file_path);

%% boxplots for frequency, amplitude, duration
% in each condition with >=1 trial with exactly 1 call

close all;

rows = 2;  % TODO: count # of non-empty conditions before plotting & pick rows/cols
columns = 4;

fig(1) = figure('Name', 'f_max', 'Position', [1 708 1280 629]);
sp_f = arrayfun(@(i) subplot(rows,columns,i), 1:rows*columns);

fig(2) = figure('Name', 'max_amp', 'Position', [1281 708 1280 629]);
sp_amp = arrayfun(@(i) subplot(rows,columns,i), 1:rows*columns);

fig(3) = figure('Name', 'call duration', 'Position', [1 1 1280 629]);
sp_dur = arrayfun(@(i) subplot(rows,columns,i), 1:rows*columns);

i=1;

for c = 1:length(call_seg_data)
    if ~isempty(call_seg_data(c).audio_filt_call)

        duration = call_seg_data(c).spectral_features.duration;
        f_max = call_seg_data(c).spectral_features.freq_max_amp;
        amp_max = call_seg_data(c).spectral_features.call_max_freq;
        
        drug = call_seg_data(c).drug;
        current = call_seg_data(c).current;
        n = string(length(call_seg_data(c).audio_filt_call));

        boxplot(sp_f(i), f_max);
        setAxes(sp_f(i), drug, current, n, [0 8500], 'Frequency (Hz)');

        boxplot(sp_amp(i), amp_max);
        setAxes(sp_amp(i), drug, current, n, [0 3], ['Amplitude']);
        
        boxplot(sp_dur(i), duration);
        setAxes(sp_dur(i), drug, current, n, [30 120], 'duration (ms)');

        i = i+1;
    end
end

%% save boxplots
save_path = "/Users/cirorandazzo/ek-spectral-analysis/figures/";

savefig(fig, save_path+'boxplots.fig', 'compact');


%% 

function setAxes(ax, drug, current, n, YLim, YLabel)
    ax.Title.String = [drug(1:end) ' ' current];
    ax.Title.Interpreter = 'none';
    ax.Title.Clipping = 'on';

    ax.XLabel.String = "n=" + n;
    ax.XTick = [];

    ax.YLim = YLim;
    ax.YLabel.String = YLabel;

    ax.YGrid = 'on';
end