function [color] = defaultDMPAMColors(option)
% defaultPharmacologyColors.m
% 2024.06.18 CDR
% 
% Given drug name, return default color. If unknown, return black.

    switch option
        % TODO: better deal with variation in washout names
        case {"dm"}
            color = '#00A5E0';
        case "pam"
            color = '#BA2561';
        otherwise
            warning("Unexpected name, plotting black.");
            color = 'k';
    end

end

