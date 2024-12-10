% plot_wav_br_with_callLines.m
% 2024.04.24
% 
% Show 1 trial of wav AND breathing overlaid with audio-segmented calls
% 
% ONLY works on trials in "call_seg.one_call" substruct

% trs = data.call_seg.one_call(25:50);
% trs = 1:10;
trs = data.call_seg.multi_calls(1:5);

% % for evtaf rec (spontaneous data)
% fs = 32000;
% stim_i = 32001;  % call exp

% % for stim data
fs = p.fs;
stim_i = p.window.stim_i;  % stimulation onset frame index


xl = [-0.5 1];


close all

i_one_call = data.call_seg.one_call;
for i_tr=length(trs):-1:1
    tr = trs(i_tr);
    
    audio = data.audio_filt(tr,:);
    breath = data.breathing_filt(tr,:);

    x = ([1 : length(audio)] - stim_i )/ fs;

    

    onset = x(data.call_seg.onsets{tr});
    offset = x(data.call_seg.offsets{tr});
    
    thr = data.call_seg.noise_thresholds(tr);


    figure;
    set(gcf, "Position", [1000,591,1306,647] );

    % audio
    ax_audio = subplot(2,1,1);
    title("tr " + string(tr));
    
    hold on;
    low = min(audio);
    high = max(audio);

    % plot_wave_callLines(x, a, onset, offset, verts);
    plot(x, audio);
    plot([x(1) x(end)], [thr thr], "Color", '#757575');
    plot([x(stim_i) x(stim_i)], [low high], "Color", '#757575', 'LineStyle', '--');
    addCallLinesToPlot(onset, offset, [low high]);
    hold off;

    % breathing
    ax_breath = subplot(2,1,2);

    hold on;
    low = min(breath);
    high = max(breath);
    
    plot(x, breath);
    plot([x(1) x(end)], [0 0], "Color", '#757575', 'LineStyle','--');
    plot([x(stim_i) x(stim_i)], [low high], "Color", '#757575', 'LineStyle', '--');
    addCallLinesToPlot(onset, offset, [low high]);
    hold off;

    ylim([min(breath) max(breath)]);

    linkaxes([ax_audio, ax_breath], 'x');
    xlim(xl);
end


%%

function plot_avg(x1, x2, avg)
    plot([x1 x2], [avg avg], 'black', 'LineStyle', ':')
end

%%

function fig = plot_wave_callLines(filtsong, onsets, offsets, verts)
% 2023.01.05 CDR
% 
% Given filtsong, onset/offset times of calls in frames, plot waveform with calls labeled

hold on;

plot(filtsong);

colors = autumn(length(offsets));

low = min(filtsong);
high = max(filtsong);

for j=1:length(offsets)
    onset = onsets(j);
    offset = offsets(j);
    color = colors(j, :);
    w = 1;  % linewidth

    plot([onset onset], [low high], 'Color', color, 'LineWidth', w);
    plot([offset offset], [low high], 'Color', color, 'LineWidth', w);
    
end

for i=1:length(verts)
    v = verts(i);
    plot([v v], [low high], "Color", '#757575', 'LineStyle', '--');
end

hold off;

fig = gcf;

end

%%
% % compute avg of breath between 2 xs, then plot w/ label

% function avg = comp_plot_horz_avg(breath, x1, x2)
%     segment = breath(x1:x2);
%     avg = mean(segment);
% 
%     plot([x1 x2], [avg avg], 'black', 'LineStyle',':')
% 
%     mid = (x1+x2) / 2 ;
%     str = {"avg", string(round(avg, 2))};
% 
%     text(mid, avg, str);
% end