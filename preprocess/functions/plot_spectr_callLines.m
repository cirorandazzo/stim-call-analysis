function f = plot_spectr_callLines(filtsong, onsets, offsets, fs, spec_threshold, n , overlap, f_low, f_high)
% 2023.01.05 CDR
% 
% Given filtsong, onset/offset times of calls in ms, and spectrogram parameters, plots spectrogram with calls labeled

hold on;
S = ek_spectrogram(filtsong, fs, spec_threshold, n, overlap, f_low, f_high);


colors = autumn(length(offsets));
y_min = f_low;
y_max = f_high;

for j=1:length(offsets)
    onset = onsets(j);
    offset = offsets(j);
    color = colors(j, :);
    w = 1.5;  % linewidth

    plot([onset onset], [y_min y_max], 'Color', color, 'LineWidth', w);
    plot([offset offset], [y_min y_max], 'Color', color, 'LineWidth', w);
end

fig = gcf;

end