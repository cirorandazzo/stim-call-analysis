%% derivatives

% trs = [35:40];
trs = data.call_seg.one_call;
% trs = [1];


fs = 32000;
stim_i = 45001;
window = 40 * fs / 1000;

sm_win = 50;

xl = [stim_i-100 stim_i+5000];

% deq_br = designfilt(...
%     p.filt_breath.type,...
%     'FilterOrder', p.filt_breath.FilterOrder,...
%     'PassbandFrequency', p.filt_breath.PassbandFrequency,...
%     'StopbandFrequency', p.filt_breath.StopbandFrequency,...
%     'SampleRate', p.fs ...
% );


for i = 1:length(trs)
    tr = trs(i);

    y = data.breathing_filt(tr, :);
    % y = data.breathing(tr, :);
    % y = filtfilt(deq_br, y);
    % y = smoothdata(y);
    
    yp = ddt(y);
    % yp = filtfilt(deq_br, yp);
    yp = smoothdata(yp, 'movmean', sm_win);
    
    ypp = ddt(yp);
    % ypp = filtfilt(deq_br, ypp);
    ypp = smoothdata(ypp, 'movmean', sm_win);
    [m, m_i] = min(ypp(stim_i+1 : stim_i+window));
    
    min_i = stim_i + m_i + 2;
    
    figure;
    subplot(3,1,1)
    hold on;
    title("tr" + string(tr));
    plot_stuff(y, fs, stim_i, min_i, window, xl);
    
    ylabel('Breath trace')

    subplot(3,1,2)
    hold on;
    plot_stuff([0 yp], fs, stim_i, min_i, window, xl);

    ylabel("y'", 'Interpreter','latex')

    subplot(3,1,3)
    hold on
    plot_stuff([0 0 ypp], fs, stim_i, min_i, window, xl);

    ylabel("y''", 'Interpreter','latex')
    xlabel('Time post-stim (s)')
end


%%

function dydt = ddt(y)
    % derivative of a discrete time series
    dydt = minus(y(2:end), y(1:end-1));
end

function plot_stuff(y, fs, stim_i, min_i, e, xl)
    x = minus(1:length(y), stim_i) / fs;
    xl_t = minus(xl, stim_i) / fs;
    stim_t = 0;
    min_t = minus(min_i, stim_i) / fs;
    e_t = e / fs;

    plot(x, y);
    plot([stim_t stim_t], [min(y), max(y)], 'black', 'LineStyle', '--');
    plot([stim_t+e_t stim_t+e_t], [min(y), max(y)], 'black', 'LineStyle', '--');
    scatter(min_t, y(min_i), 'red', 'filled');
    xlim(xl_t);

end