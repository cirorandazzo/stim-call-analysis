% plot_wav_with_callLines.m
% 2023.01.08
% 
% Show 1 trial of spectrogram overlaid with calls. Requires struct output
% from b_segment_calls.m

% trs=[1:30];
% data = proc_data;

% trs = data.call_seg.no_calls;
trs = data.call_seg.one_call;

fs = 30000;
stim_i = 45001;  % stimulation onset frame index


% close all
for j=1:length(trs)
    figure;

    tr = trs(j);
    
    a = data.audio_filt(tr,:);
    
    % onset = onsets{tr};
    % offset = offsets{tr};
    
    onset = data.call_seg.onsets{tr};
    offset = data.call_seg.offsets{tr};
    
    plot_wave_callLines(a, onset, offset);

    thr = data.noise_thresholds(tr);
    
    hold on;
    plot([0 length(a)], [thr thr], 'black')
    hold off;
    
    title("tr " + string(tr));
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
    w = 1.5;  % linewidth

    plot([onset onset], [low high], 'Color', color, 'LineWidth', w);
    plot([offset offset], [low high], 'Color', color, 'LineWidth', w);
    
end


hold off;

fig = gcf;

end