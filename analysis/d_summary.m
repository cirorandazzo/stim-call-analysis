%% d_summary.m
% 2023.01.08 CDR
% 
% Summary measures/statistics on spectral features

%% TODO: load file

clear;
close all;
close_figs = 0;  % set true to automatically close figures one plotting is complete

file_path = '/Users/cirorandazzo/ek-spectral-analysis/spectral_features-bk68wh15.mat';
load(file_path);

%% boxplots for frequency, amplitude, duration
% in each condition with >=1 trial with exactly 1 call

close all;

rows = 1;
columns = 1;
% rows = 2;  % TODO: count # of non-empty conditions before plotting & pick rows/cols
% columns = 4;

fig(1) = figure('Name', 'f_max', 'Position', [1 708 1280 629]);
sp_f = arrayfun(@(i) subplot(rows,columns,i), 1:rows*columns);

fig(2) = figure('Name', 'max_amp_filt', 'Position', [1281 708 1280 629]);
sp_amp_filt = arrayfun(@(i) subplot(rows,columns,i), 1:rows*columns);

fig(3) = figure('Name', 'max_amp_fft', 'Position', [1281 1 1280 629]);
sp_amp_fft = arrayfun(@(i) subplot(rows,columns,i), 1:rows*columns);

fig(4) = figure('Name', 'call duration', 'Position', [1 1 1280 629]);
sp_dur = arrayfun(@(i) subplot(rows,columns,i), 1:rows*columns);


i=1;

for c = 1:length(spectral_features)
    if ~isempty(spectral_features(c).audio_filt_call)

        duration = spectral_features(c).spectral_features.duration;
        f_max = spectral_features(c).spectral_features.freq_max_amp;
        amp_max_filt = spectral_features(c).spectral_features.max_amp_filt;
        amp_max_fft = spectral_features(c).spectral_features.max_amp_fft;
        
        % drug = spectral_features(c).drug;
        % current = spectral_features(c).current;
        n = string(length(spectral_features(c).audio_filt_call));

        boxplot(sp_f(i), f_max);
        setAxes(sp_f(i), n, 'auto', 'Frequency (Hz)');
        % setAxes(sp_f(i), drug, current, n, [0 8500], 'Frequency (Hz)');

        boxplot(sp_amp_filt(i), amp_max_filt);
        setAxes(sp_amp_filt(i), n, 'auto', 'Amplitude_Filt');
        % setAxes(sp_amp_filt(i), drug, current, n, [0 0.05], 'Amplitude_Filt');
        
        boxplot(sp_amp_fft(i), amp_max_fft);
        setAxes(sp_amp_fft(i), n, 'auto', 'Amplitude_FFT');
        % setAxes(sp_amp_fft(i), drug, current, n, [0 3], 'Amplitude_FFT');
        
        boxplot(sp_dur(i), duration);
        setAxes(sp_dur(i), n, 'auto', 'duration (ms)');
        % setAxes(sp_dur(i), drug, current, n, [30 120], 'duration (ms)');

        i = i+1;
    end
end

%% save boxplots
save_path = "/Users/cirorandazzo/ek-spectral-analysis/";

savefig(fig, save_path+'boxplots.fig', 'compact');

if close_figs
    close all;
end

%% 

function setAxes(ax, n, YLim, YLabel)
    ax.Title.Interpreter = 'none';
    ax.Title.Clipping = 'on';

    ax.XLabel.String = "n=" + n;
    ax.XTick = [];

    ylim(ax, YLim);
    ax.YLabel.String = YLabel;

    ax.YGrid = 'on';
end
% function setAxes(ax, drug, current, n, YLim, YLabel)
%     ax.Title.String = [drug(1:end) ' ' current];
%     ax.Title.Interpreter = 'none';
%     ax.Title.Clipping = 'on';
% 
%     ax.XLabel.String = "n=" + n;
%     ax.XTick = [];
% 
%     ax.YLim = YLim;
%     ax.YLabel.String = YLabel;
% 
%     ax.YGrid = 'on';
% end