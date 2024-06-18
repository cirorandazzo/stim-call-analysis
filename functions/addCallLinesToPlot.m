function addCallLinesToPlot(onsets, offsets, ylims, options)
% addCallLinesToPlot
% 2024.06.17 CDR
% 

arguments
    onsets {mustBeNumeric};
    offsets {mustBeNumeric};
    ylims (2,1) {mustBeNumeric};
    options.LineWidth (1,1) {mustBeNumeric} = 1;
    options.LineStyle (1,1) string = '--';
end

holdstate = ishold;  % return to initial hold state after plotting.

hold on;
colors = autumn(length(offsets));

for i_call=1:length(offsets)
    onset = onsets(i_call);
    offset = offsets(i_call);
    color = colors(i_call, :);

    plot([onset onset  ], ylims, 'Color', color, 'LineWidth', options.LineWidth, 'LineStyle', options.LineStyle);
    plot([offset offset], ylims, 'Color', color, 'LineWidth', options.LineWidth, 'LineStyle', options.LineStyle);
end

hold(holdstate);

end