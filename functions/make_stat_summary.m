function stat_summary = make_stat_summary(distr)

    stat_summary.median = median(distr);
    stat_summary.mean = mean(distr);
    stat_summary.std = std(distr);

end