# hvc pharmacology calls

Spectral analysis for DM-stim + pharmacology experiments in [Eszter's vocalization project](https://cirorandazzo.github.io/blab-obsidian/EK-Vocalizations/).

Pipeline:
- `preprocess\`
    - `a1_load_raw_files.m`
    - `a_restruct_data.m`
    - `b_segment_calls.m`
- `analysis\`
    - `c_spectral_analysis`
    - `d_summary`

Automated pipeline: see `./automated_pipeline/main.m`
2024.02.12

Major functions:
- `s1_load_raw`
- `s2_restructure`
- `s3_segment_calls`
- TODO: breathing around call analysis
