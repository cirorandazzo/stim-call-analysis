function combos = getUniqueConditionCombos(conditions)
% getUniqueConditionCombos.m
% 2023.01.10
% 
% Given cell array where each cell is a string list of conditions, get
% every possible combination of conditions.
% 
% ie, cartesian product
% 
% Thanks stackexchange stranger :) https://stackoverflow.com/a/4169488/23017760

    
    c = cell(1, numel(conditions));
    [c{:}] = ndgrid( conditions{:} );
    combos = cellfun(@(v) v(:)', c, 'UniformOutput',false);
    
    combos = string(vertcat(combos{:}))';  % convert to string so @unique works
    combos = unique(combos, 'rows');  % remove any duplicate conditions
end

