%% pu65bk36
data_path = "C:\Users\ciro\Documents\code\stim-call-analysis\data\processed\pu65bk36\pu65bk36-data.mat";
bird_name = 'pu65bk36';
surgery_state = 'anesthetized';

comparisons(1).comparison = 'muscimol';
comparisons(1).ii_data = [1,4];

comparisons(2).comparison = 'gabazine';
comparisons(2).ii_data = [2,5];

comparisons(3).comparison = 'gabazine_current';
comparisons(3).ii_data = [2,3];
comparisons(3).colors = {"#81A263", "#365E32"};