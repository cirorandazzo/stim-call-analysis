


fs = 30000;
stim_i = 45001;

figure;
hold on;


xlabel('Time since stim (ms)')
ylabel('Pressure')

trs_one_call = data.call_seg.one_call;
to_plot = data.breathing_filt(trs_one_call, :);
x = f2ms(1:size(to_plot, 2), fs, stim_i);

plot(x, to_plot', 'Color', '#c3c3c3', 'LineWidth', 0.5);  % transpose is very important, might crash computer otherwise :(
plot(x, mean(to_plot, 1), 'black', 'LineWidth', 4);

l = min(to_plot, [], 'all'); 
h = max(to_plot, [], 'all');

plot([0 0], [l h], 'Color', 'black', 'LineStyle', '--')

xlim([-100 200]);

% for j=1:length(trs_one_call)
%     tr = trs_one_call(j);
% 
%     y = data.breathing_filt(tr, :);
%     x = f2s(1:length(y), fs, stim_i);
% 
%     plot(x, y ...
%         , 'LineWidth', 0.5 ...
%         );
% end


%%
function ms = f2ms(f, fs, stim_i)
    ms = minus(f, stim_i) * 1000 / fs;
end