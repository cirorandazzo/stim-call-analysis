% plot_wav_with_callLines.m
% 2024.01.08
% 
% Show 1 trial of wav overlaid with calls. Requires struct output
% from b_segment_calls.m

% data = proc_data;

% trs = 132:140;
trs = data.call_seg.multi_calls;


% % for evtaf rec (spontaneous data)
% stim_i = 32001;
% fs = 32000;

% % for stim data
fs = 30000;
stim_i = 45001;  % stimulation onset frame index

x = [1 : length(data.audio_filt(1,:))] / fs * 1000;  % ms values for plotting
xl = [1495 1600];  % xlim

close all
for j=1:length(trs)
    tr = trs(j);

    onsets = data.call_seg.onsets{tr};
    offsets = data.call_seg.offsets{tr};
   
    figure;
    title("tr " + string(tr));
    hold on
    
    % audio
    a_filt = data.audio_filt(tr, :);
    y_min = min(a_filt, [], 'all');
    y_max = max(a_filt, [], 'all');
    plot(x , a_filt)

    % call lines
    addCallLinesToPlot(onsets, offsets, [y_min y_max])

    % stimulus
    plot([stim_i stim_i] * 1000/fs, [0 y_max], Color='k', LineStyle='--', LineWidth=1);

    % threshold
    thr = data.call_seg.noise_thresholds(tr);
    plot([x(1) x(end)], [thr thr], LineStyle='--', Color='k')
    hold off

    xlabel('Time (ms)')
    xlim(xl)
    ylim([0 thr*2])
end
