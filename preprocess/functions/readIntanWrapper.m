function data = readIntanWrapper(x, labels, varargin)
% readIntanWrapper.m
% 2023.01.09 CDR
% 
% given struct containing intan file path & labels (eg, stimulation
% amplitude), load data from file path.
% 
% TODO: documentation.
% 
% varargin currently supports "SuppressOutput"

    for i=1:length(labels)  % carry over labels from input
        l = labels{i};
        if ~isempty(l)
            data.(l) = x.(l);
        end
    end

    name = x.name;
    folder = x.folder;

    if ~isempty(varargin) && strcmp(varargin{1}, "SuppressOutput")
        [~, c] = evalc("ek_read_Intan_RHS2000_file(name, folder)"); % evalc streams command window output into first var
    else
        c = ek_read_Intan_RHS2000_file(name, folder);
    end

    data.fs =       c.frequency_parameters.amplifier_sample_rate;
    data.sound =    c.board_adc_data(1, :);
    data.stim =     c.board_dig_in_data; %stim_data(stimChan, :);
    data.breathing= c.board_adc_data(2, :);

end

