
% from preprocessed data, plot breath waveform with overlaid segmented breath zero crossings

trs = [28:40];
% trs = data.call_seg.one_call;

fs = 32000;
stim_i = 32001;

% fs = 32000;
% stim_i = 45001;

for i=1:length(trs)
    
    tr = trs(i);

    r = data.breath_seg(tr);
    
    centered = r.centered;
    insps_pre = r.insps_pre; 
    exps_pre = r.exps_pre;
    insps_post = r.insps_post;
    exps_post = r.exps_post;
    
    latency_insp = r.latency_insp;
    
    figure;
    hold on;
    
    xlabel('time from stim (s)')

    high = max(centered);
    low = min(centered);

    x = f2s(1:length(centered), fs, stim_i);

    plot(x, centered, 'black');
    plot(f2s([stim_i stim_i], fs, stim_i), [low high], "Color", '#757575', 'LineStyle', '--');

    a(insps_pre, centered, 'red', fs, stim_i);
    a(exps_pre,  centered, 'blue', fs, stim_i);
    a(insps_post,centered, 'red', fs, stim_i);
    a(exps_post, centered, 'blue', fs, stim_i);

    scatter(latency_insp/1000, centered(ms2f(latency_insp, fs, stim_i)), 'green', 'filled');

    % a(insps,centered, 'red', fs, stim_i);
    % a(exps, centered, 'blue', fs, stim_i);

    title("tr"+int2str(tr));
    % title("pu65bk36-tr" + int2str(tr) + "-short_exp", 'Interpreter','none')
    % set(gcf,'units','normalized','outerposition',[0 0 1 1])
    % 
    % saveas(gcf, "pu65bk36-tr" + int2str(tr) + "-short_exp.png")
end


%%

function a(points, breath, color, fs, stim_i)
    scatter(f2s(points, fs, stim_i), breath(points), color, 'filled');
end

function s = f2s(f, fs, stim_i)
    s = minus(f, stim_i) / fs;
end

function f = ms2f(ms, fs, stim_i)
    f = round(plus(ms*fs/1000, stim_i));
end