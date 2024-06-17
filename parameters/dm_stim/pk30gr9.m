%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters


%--files
p.files.raw_data = 'F:\ziggy\stim_data-20240604\dm\DMStim_pk30gr9.mat';

p.files.bird_name = 'pk30gr9';
p.files.group = 'dm';

p.fs = 30000;

p = default_params(p);

