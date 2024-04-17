%% dm_pam_checks.m
% 2024.04.15 CDR
% 
% some quick summary statistics from processed data in a given folder.

proc_folder = '/Users/cirorandazzo/code/stim-call-analysis/data/processed';
files = dir([proc_folder filesep '**' filesep '*_data.mat'] );

to_plot = {};
% to_plot = {'exp', 'aud', 'insp'};
% to_plot = {'insp'};
savefolder = '/Users/cirorandazzo/code/stim-call-analysis/data/figures';

stim_i = 45001;
fs = 30000;

xl = [0 200];
nbins = 20;
edges = [0:nbins]* (xl(2)-xl(1))/nbins;

summary = [];
summary.bird = [];
summary.cond = [];
summary.n_rows = [];
summary.n_one_call = [];
summary.n_no_calls = [];
summary.n_multi_calls = [];

for i = length(files):-1:1
    f = files(i);

    load([f.folder filesep f.name]);  % loads var `data`
    
    bird = replace(f.name, '_data.mat', '');
    pth = split(f.folder, filesep);
    files(i).cond = pth{length(pth)};

    summary(i).bird = bird;
    summary(i).n_rows = size(data.breath_seg, 1);
    summary(i).n_one_call = size(data.call_seg.one_call, 1);
    summary(i).n_no_calls = size(data.call_seg.no_calls, 1);
    summary(i).n_multi_calls = size(data.call_seg.multi_calls, 1);

    i_one_call = data.call_seg.one_call;

    if ismember('exp', to_plot)
        % EXPIRATORY LATENCY
        exp_latencies = [data.breath_seg.latency_exp];
        exp_latencies = exp_latencies(i_one_call);
        
        fig = histogram(exp_latencies, edges);
        title([bird ' exp latency (' int2str(length(i_one_call)) ')']);
        xlabel("Latency to Expiration (ms)");
        ylabel("Count");
        xlim(xl);
    
        saveas(fig, [savefolder filesep 'exp' filesep bird '_expHist.png']);
        close;
    end

    if ismember('insp', to_plot)
        % INSPIRATORY LATENCY
        insp_latencies = arrayfun(@(tr) data.breath_seg(tr).insps_post(1) - stim_i, i_one_call);  % first insp after call
        insp_latencies = insp_latencies*1000/fs;

        fig = histogram(insp_latencies, 20);
        title([bird ' insp latency (' int2str(length(i_one_call)) ')']);
        xlabel("Latency to Inspiration (ms)");
        ylabel("Count");
    
        % xlim(xl);
    
        saveas(fig, [savefolder filesep 'insp' filesep bird '_inspHist.png']);
        close;
    end
    
    if ismember('aud', to_plot)
        % CALL LATENCY
        call_latencies = [data.call_seg.acoustic_features.latencies{:}];
    
        fig = histogram(call_latencies, edges);
        title([bird ' audio latency (' int2str(length(i_one_call)) ')']);
        xlabel("Latency to Call (ms)");
        ylabel("Count");
        xlim(xl);
    
        saveas(fig, [savefolder filesep 'aud' filesep bird '_audHist.png']);
        close;
    end

end


%%

% i=4;
% f=files(i);
% load([f.folder filesep f.name]);  % loads var `data`
% 
% i_one_call = data.call_seg.one_call;
% 
% for q=1:length(i_one_call)
% 
%     j=i_one_call(q);
% 
%     y = data.audio_filt(j, :);
% 
%     figure;
%     plot(y)
% 
% end

%%

























