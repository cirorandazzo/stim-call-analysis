% batch_plot_spectrograms.m
% 2024.06.7
% 
% Batch plot the spectrograms from multiple processed data files.
% 
% NOTE: the parfor (parallel for) loop has some memory leak. If you get a memory error, just re-run the code with `skip_existing=True`, or replace parfor with for (will take a lot longer.)

% for stim data
fs = 30000;
stim_i = 45001;  % stimulation onset frame index

%--windowing/spectrogram options
n = 1024;
overlap = 1020;

f_low = 500;
f_high = 15000;


%%
close all

delete(gcp('nocreate'));
parpool(5);

save_root = "C:\Users\ciro\Documents\code\stim-call-analysis\data\figures\spectrograms";
mkdir(save_root)

ext = '.jpeg';
skip_existing = true;
save_wav = true;
xl = [1450 2000];  % ms. not zeroed on stimulus.

spec_threshold = 1.25e-2; % determined manually; see spectrogram_thresholding.m

data_files = {
    "C:\Users\ciro\Documents\code\stim-call-analysis\data\processed\bu69bu75\bu69bu75-data.mat"
    "C:\Users\ciro\Documents\code\stim-call-analysis\data\processed\pk15\pk15-data.mat"
    "C:\Users\ciro\Documents\code\stim-call-analysis\data\processed\pk30gr9\pk30gr9-data.mat"
    "C:\Users\ciro\Documents\code\stim-call-analysis\data\processed\pk48br83\pk48br83-data.mat"
    "C:\Users\ciro\Documents\code\stim-call-analysis\data\processed\pu65bk36\pu65bk36-data.mat"
};

call_count_cats = {'one_call', 'no_calls', 'multi_calls'};

set(groot, 'DefaultFigureVisible','off');  % suppress figures

parfor i_df = 1:length(data_files)
    data = load(data_files{i_df}, 'data').data;
    bird_name = data(1).bird;
    x = [1 : length(data(1).audio(1,:))] / fs * 1000;  % ms values for plotting
    
    % make 1 figure that's recycled (prevent memory leak)
    fig = figure;
    set(fig, "Position", [2   356   894   680]);

    for i_c=1:length(data)
        cond_string = strcat(bird_name, '-', data(i_c).drug, '_', data(i_c).current);
        
        for i_ccc = 1:length(call_count_cats)
            disp(strcat('Plotting: ', cond_string, ', ', call_count_cats{i_ccc}))
            tic
            trs = data(i_c).call_seg.(call_count_cats{i_ccc});
    
            % don't make folder if condition + call count is empty
            if isempty(trs)
                trs = [];
                continue
            end

            folder = fullfile(save_root, bird_name, cond_string, call_count_cats{i_ccc});
            mkdir(folder);
    
            data_ic = data(i_c);

            
            for i_tr=1:length(trs)
                tr = trs(i_tr);
                figname = strcat(cond_string, "-tr", string(tr), ext);
                wavname = strcat(cond_string, "-tr", string(tr), '.wav');
                figpath = fullfile(folder, figname);
                wavpath = fullfile(folder, wavname);

                if skip_existing & isfile(figpath)
                    continue
                end

                % a = audio_filt(tr, :);
                onsets = data_ic.call_seg.onsets{tr} * 1000/fs;
                offsets = data_ic.call_seg.offsets{tr} * 1000/fs;

                clf(fig)

                % plot rectified audio
                ax1 = subplot(3,1,1);

                subtitle("tr " + string(tr));
                title(cond_string, 'Interpreter','none');

                hold on
                a_filt = data_ic.audio_filt(tr, :);
                y_min = min(a_filt, [], 'all');
                y_max = max(a_filt, [], 'all');

                plot(x , a_filt)
                a_filt = [];

                % add horizontal threshold line
                thr = data_ic.call_seg.noise_thresholds(tr);
                plot([x(1) x(end)], [thr thr], LineStyle='--', Color='k')

                ylim([0 thr*2]);

                % add onset/offset lines
                colors = autumn(length(offsets));
                for j=1:length(offsets)
                    onset = onsets(j);
                    offset = offsets(j);
                    color = colors(j, :);
                    w = 1;  % linewidth

                    plot([onset onset], [y_min y_max], 'Color', color, 'LineWidth', w, 'LineStyle', '-');
                    plot([offset offset], [y_min y_max], 'Color', color, 'LineWidth', w, 'LineStyle', '-');
                end

                hold off

                ax2 = subplot(3,1,[2,3]);

                plotSpectrCallLines(data_ic.audio(tr,:), onsets, offsets, fs, spec_threshold, n , overlap, f_low, f_high);
                hold on;
                plot([stim_i stim_i] * 1000/fs, [0 f_high], Color='k', LineStyle='--', LineWidth=1);
                hold off;
                ylim([f_low f_high])


                linkaxes([ax2 ax1], 'x')
                xlim(xl);
                
                saveas( fig, figpath );

                if save_wav
                    audiowrite(wavpath, data_ic.audio(tr,:), fs);
                end
            end

            toc  % time elapsed for this condition + call_count
        end

        get(groot, 'Children')
    end

    close all hidden;
end

disp('Finished spectrogramming!')
delete(gcp('nocreate'));
set(groot, 'DefaultFigureVisible','on');  % un-suppress figures
