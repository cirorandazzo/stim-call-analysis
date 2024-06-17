function fig = plotSpectrCallLines(filtsong, onsets, offsets, fs, spec_threshold, n , overlap, f_low, f_high)
% 2023.01.05 CDR
% 
% Given filtsong, onset/offset times of calls in ms, and spectrogram parameters, plots spectrogram with calls labeled

% call label line parameters; TODO: add optional arguments
w = 1; % linewidth
ls = '--';  % linestyle

% ylim to use for (1) axis ylim and (2) height of call label lines. TODO: add optional argument
yl = [f_low f_high];

hold on;
S = ek_spectrogram(filtsong, fs, spec_threshold, n, overlap, f_low, f_high);

colors = autumn(length(offsets));

for i_call=1:length(offsets)
    onset = onsets(i_call);
    offset = offsets(i_call);
    color = colors(i_call, :);

    plot([onset onset], yl, 'Color', color, 'LineWidth', w, 'LineStyle', ls);
    plot([offset offset], yl, 'Color', color, 'LineWidth', w, 'LineStyle', ls);
end

ylim(yl);

fig = gcf;
hold off;

end