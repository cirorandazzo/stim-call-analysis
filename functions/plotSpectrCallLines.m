function fig = plotSpectrCallLines(filtsong, onsets, offsets, fs, spec_threshold, n , overlap, f_low, f_high)
% 2023.01.05 CDR
% 
% Given filtsong, onset/offset times of calls in ms, and spectrogram parameters, plots spectrogram with calls labeled
% 
% TODO: add optional arguments for call label line parameters

% ylim to use for (1) axis ylim and (2) height of call label lines. TODO: add optional argument
yl = [f_low f_high];

holdstate = ishold;
hold on;

S = ek_spectrogram(filtsong, fs, spec_threshold, n, overlap, f_low, f_high);
set(gca, 'TickDir', 'out'); % otherwise 
addCallLinesToPlot(offsets, onsets, yl, LineWidth=1, LineStyle='--');
ylim(yl);
fig = gcf;

hold(holdstate); % return to initial hold;

end