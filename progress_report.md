Last week:
Submitted PA2 with the baseline and interaction panel local projections. The responses go in the expected direction, monetary tightening lowers real house prices at short horizons and the decline is stronger in variable rate countries, but the interaction was not significant and the sample looked too small.

This week:
Tracked down the observation loss you flagged. It is not a merge error. Of the 423 lost observations, 412 are missing only because of unemployment: the quarterly Eurostat series une_rt_q starts around 2009 for most countries, so every earlier quarter was dropped as soon as unemployment entered the regression. GDP growth and inflation cover the full sample.

I fixed it two ways. The baseline controls are now GDP growth and inflation, which alone lifts the estimation sample from 673 to 1085 with no new data. Unemployment now comes from the longer monthly series une_rt_m and moves to a robustness table. I also added a COVID dummy for 2020 to 2021, since q on q GDP growth has about 20 percent outliers there that would otherwise dominate the projection.

Next:
Rerun the pipeline on the full sample and re estimate the interaction. Report the baseline, the unemployment robustness, and the COVID adjusted version side by side, and check whether the interaction becomes significant on the larger sample.
