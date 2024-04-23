% plot_wav_with_callLines.m
% 2023.01.08
% 
% Show 1 trial of wav overlaid with calls. Requires struct output
% from b_segment_calls.m

% data = proc_data;

% trs = 132:140;
% trs = data.call_seg.no_calls([1:5 100:105 300:310]);
% trs = data.call_seg.one_call([1:5 100:105 400:405]);
trs = later;


% % for evtaf rec (spontaneous data)
stim_i = 32001;
fs = 32000;

% % for stim data
% fs = 30000;
% stim_i = 45001;  % stimulation onset frame index


% close all
for j=length(trs):-1:1
    figure;

    tr = trs(j);
    
    % a = data.audio_filt(tr,:);
    % a = data.audioMat(tr,:);
    a = data.audio(tr,:);

    % onset = onsets{tr};
    % offset = offsets{tr};
    
    onset = data.call_seg.onsets{tr};
    offset = data.call_seg.offsets{tr};
    
    plot_wave_callLines(a, onset, offset);

    thr = data.call_seg.noise_thresholds(tr);
    % thr = data.noise_thresholds(tr);
    
    hold on;

    % stim (or exp align)
    low = min(a);
    high = max(a);
    plot([stim_i stim_i], [low high], "Color", '#757575', 'LineStyle', '--');

    % threshold (horizontal line)
    plot([0 length(a)], [thr thr], "Color", '#757575');
    hold off;
    
    title("tr " + string(tr));

    xlim([30000 34000])
    ylim([0 100])

end

%%

function fig = plot_wave_callLines(filtsong, onsets, offsets)
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


hold off;

fig = gcf;

end