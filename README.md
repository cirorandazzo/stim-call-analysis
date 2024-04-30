# stim-call-analysis

Spectral analysis for DM & PAm stimulation experiments.

Automated pipeline: `./automated_pipeline/main.m`

Major functions:

*Each bird* (in `pipeline.m`)
- `s1_load_raw`
- `s2_restructure`
- `s3_segment_calls`
- `s4_segment_breaths`
- `pipeline_plots`

*Summary* (in `main.m`)
- `make_group_summaries`
- `make_group_histogram`

TODO: describe inputs/outputs