% plot_wav_br_with_callLines.m
% 2024.04.24
% 
% Show 1 trial of wav AND breathing overlaid with audio-segmented calls and
% vicinity analysis windows/averages
% 
% ONLY works on trials in "call_seg.one_call" substruct

trs = data.call_seg.one_call(25:50);

% % for evtaf rec (spontaneous data)
fs = 32000;
stim_i = 32001;  % call exp
pre_window = 100 * fs / 1000;
post_window = 100 * fs / 1000;

xl = [28 37] * 1000;


close all

i_one_call = data.call_seg.one_call;
for i=length(trs):-1:1
    figure;
    

    tr = trs(i);
    
    % a = data.audio_filt(tr,:);
    % a = data.audioMat(tr,:);
    a = data.audio(tr,:);

    % onset = onsets{tr};
    % offset = offsets{tr};
    onset = data.call_seg.onsets{tr};
    offset = data.call_seg.offsets{tr};
    
    thr = data.call_seg.noise_thresholds(tr);
    % thr = data.noise_thresholds(tr);

    verts = [onset - pre_window, offset + post_window, stim_i];

    % audio
    subplot(2,1,1)
    title("tr " + string(tr));
    plot_wave_callLines(a, onset, offset, verts);
    hold on;
    plot([0 length(a)], [thr thr], "Color", '#757575');
    xlim(xl)
    ylim([0 max(a(onset:offset))]);
    hold off;

    % breathing
    subplot(2,1,2);
    % b = data.breathing_filt(tr,:);
    % b = data.breath_seg(tr).centered;

    i_vic = find(i_one_call == tr);

    b = data.vicinity(i_vic).normd;
    plot_wave_callLines(b, onset, offset, verts);

    hold on;
    plot_avg(onset, offset, data.vicinity(i_vic).call_breath_mean);
    plot_avg(onset-pre_window, onset, data.vicinity(i_vic).pre_call_breath_mean);
    plot_avg(offset, offset+post_window, data.vicinity(i_vic).post_call_breath_mean);

    plot([0 length(b)], [0 0], "Color", '#757575', 'LineStyle','--');
    xlim(xl);
    ylim([min(b) max(b)]);
    hold off;
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