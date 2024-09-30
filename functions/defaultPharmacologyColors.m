function [color] = defaultPharmacologyColors(drug)
% defaultPharmacologyColors.m
% 2024.06.18 CDR
% 
% Given drug name, return default color. If unknown, return black.

    switch drug
        % TODO: better deal with variation in washout names
        case {"baseline", "washout", "washout_muscimol", "washout_muscimol2"}
            color = '#405e5d';
        case "gabazine"
            color = '#81A263';
        case "muscimol"
            color = '#EF9C66';
        otherwise
            warning("Unexpected drug name, plotting black.");
            color = 'k';
    end

end

