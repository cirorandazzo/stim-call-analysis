function data = readIntanWrapper(x, parameter_names, options)
% readIntanWrapper.m
% 2023.01.09 CDR
% 
% given struct containing intan file path & labels (eg, stimulation
% amplitude), load data from file path.
% 
% TODO: documentation.

    arguments
        x
        parameter_names
        options.SuppressOutput = 1
    end

    for i=1:length(parameter_names)  % carry over labels from input
        l = parameter_names{i};
        if ~isempty(l)
            data.(l) = x.(l);
        end
    end

    name = x.name;
    folder = x.folder;

    if options.SuppressOutput
        [~, c] = evalc("ek_read_Intan_RHS2000_file(name, folder)"); % evalc streams command window output into first var
    else
        c = ek_read_Intan_RHS2000_file(name, folder);
    end

    data.fs         = c.frequency_parameters.amplifier_sample_rate;
    data.sound      = c.board_adc_data(1, :);
    data.stim       = c.board_dig_in_data; %stim_data(stimChan, :);  % error here might occur bc there are 2 channels
    data.breathing  = c.board_adc_data(2, :);
    data.file       = x;
end

