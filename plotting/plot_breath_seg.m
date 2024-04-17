
% from preprocessed data, plot breath waveform with overlaid segmented breath zero crossings

trs = [10:20];

stim_i = 45001;

for i=1:length(trs)
    
    tr = trs(i);

    r = data.breath_seg(tr);
    
    figure;
    hold on;
    
    xlabel('time from stim (s)')

    high = max(r.centered);
    low = min(r.centered);

    x = f2s(1:length(r.centered), fs, stim_i);

    plot(x, r.centered, 'black');
    plot(f2s([stim_i stim_i], fs, stim_i), [low high], "Color", '#757575', 'LineStyle', '--');

    a(r.insps_pre, r.centered, 'red', fs, stim_i);
    a(r.exps_pre, r.centered, 'blue', fs, stim_i);
    a(r.insps_post, r.centered, 'red', fs, stim_i);
    a(r.exps_post, r.centered, 'blue', fs, stim_i);

    title("tr"+int2str(tr));
end


%%

function a(points, breath, color, fs, stim_i)
    scatter(f2s(points, fs, stim_i), breath(points), color, 'filled');
end

function ms = f2s(f, fs, stim_i)
    ms = minus(f, stim_i) / fs;
end