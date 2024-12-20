function stat_summary = summarize_distribution(distr)

    stat_summary.median = median(distr);
    stat_summary.mean = mean(distr);
    stat_summary.std = std(distr);
    stat_summary.n = length(distr);

end