function statistics = get_summary_stats(distr, options)

    arguments
        distr;
        options.statFunction = @summarize_distribution;
    end

    if isstruct(distr)  % runs recursively

        % pass options recursively; need cell
        C = [fieldnames(options).'; struct2cell(options).'];
        C=C(:).';

        statistics = arrayfun( ...
            @(x) structfun(@(y) get_summary_stats(y, C{:}), x, "UniformOutput", false), ...
            distr...
        );

    % scalars, strings, empty
    elseif ~isnumeric(distr) | isscalar(distr) | isempty(distr)
        statistics = distr;

    else  % this actually is a distribution; compute stats
        statistics=options.statFunction(distr);

    end

end
