# ECON 899 requirements checklist

Consolidated from the two course workshops (Reproducibility and version
control; Stage 2 Creation) and Brian's final stage email. Status marks what
exists in this project. Two separate deliverables: the paper and the
replication package.

## 0. HARD CONSTRAINTS (Brian, final stage email)

- Maximum 6000 words in the main text
- Maximum FIVE tables and figures in total in the main text
- NO literature review section. Antecedents belong briefly in the
  introduction only
- Direction decided: write up the current national design honestly.
  Do NOT change the moderator or move to regional data
- Triage: drop or postpone alternative specifications, extensions and extra
  robustness checks unless they are critical. One clearly explained
  regression beats twenty haphazard ones
- Priority is a COMPLETE draft as soon as possible, then improve it

### Dates

- July 31: Progress Assignment 3 (macro editing)
- Aug 3: optional complete draft submission to receive comments
- Aug 2 to 9: Brian on working vacation, replies by next business day
- Aug 10: drop in Teams meetings during class time

### Exhibit budget (max 5, main text)

1. Table 1: Summary statistics
2. Table 2: Main local projection results (baseline and interaction)
3. Figure 1: Interaction IRF, differential response of variable rate countries
4. Figure 2 (optional): Baseline IRF, average house price response
5. Reserve

Everything else goes to the appendix or gets dropped: shock validation,
LP dynamics, pre/post 2009 subsample, unemployment robustness, coverage
audit, and the short versus long rate decomposition.

## A. The paper (empirical structure)

- [ ] Abstract, max 100 words, written to recruit a reader
- [ ] Introduction (Head formula: hook, question, antecedents, value added,
      answer, short road map)
- [ ] Background / institutional context (euro area mortgage markets, fixed
      vs variable structure, ECB monetary policy)
- [ ] Theoretical framework / mechanism (budget or user cost channel; also
      motivates the short rate prediction)
- [x] Data section (draft: paper/sections/data.tex)
  - [x] All data sources cited (EA-MPD, OECD house prices, Eurostat controls,
        mortgage classification)
  - [x] Summary statistics table (01_summary_stats.R -> summary_stats.tex)
  - [x] Variable definitions and treatment of missing values
- [ ] Empirical strategy / model (local projections, shock identification,
      interaction, Driscoll Kraay standard errors, sample)
- [x] Results, in plain English plus tables and figures
      (draft: Paper/sections/results.tex)
- [ ] Robustness checks (mostly in appendix): raw vs pure shock, subsample
      pre/post 2009, alternative controls, unemployment
- [ ] Conclusion (Bellemare formula: summary, limitations, policy
      implications, future research; keep brief)
  - [ ] Limitations must include the power limitation honestly
  - [ ] Future research: regional route, cite Battistini et al. 2024
- [ ] References with every data source
- [ ] Appendix (robustness, extra tables, summary statistics)

Length norm from the example papers: roughly 16 to 25 pages of main text.

## B. The replication package (reproducibility workshop)

Structure (already in place):

- [x] Data/raw_data, Data/data_for_analysis, Programs/01_dataprep,
      Programs/02_analysis, Programs/03_appendix, Results
- [x] A README.md in each folder describing its purpose
- [x] config.R (only file the user edits), sourced by every program
- [x] 00_setup.R installs packages
- [x] data_for_analysis and Results excluded from the repo (.gitignore)

Gaps to close:

- [x] Main runner 01_main.R that calls every program in the correct order
- [x] Main README based on the SSDE structure (README.md), old readme moved
      to 899_readme.md
- [x] Raw data provenance documented in the main README (EA-MPD source,
      OECD via rdbnomics, Eurostat datasets, ECB MIR)
- [x] EA-MPD raw file committed (.gitignore exception), package self contained
- [ ] 00_setup.R could also note how to obtain raw data (minor)
- [ ] Program naming in 02_analysis: workshop wants output based names
      (Table01.R produces Results/Table01, Figure01.R produces Figure01).
      Current names are task based. Defer until the specification is final
      after Brian's steer.
- [ ] Optional: assert statements in each program to catch changes in key
      results

## C. Tables and Figures workshop (key points)

- Every exhibit has ONE purpose (make a point, tell a story, or give the
  reader something to explore) and must satisfy that purpose
- Value the reader's attention: remove extraneous information, reduce
  confusion and effort, direct attention to the most important number
- Prefer direct labels over legends; make the eye move less
- Significance star convention: * 10 percent, ** 5 percent, *** 1 percent;
  state the information explicitly in the notes as well, never rely on the
  convention alone
- Captions and notes self contained: a reader should understand the exhibit
  without the main text

## D. Models workshop (key points)

- Provide both the math and its interpretation; define every variable in
  the estimating equation
- Say what the equation is: causal model, prediction, or estimating
  equation for a more complex model
- State identifying assumptions in plain English, and in math unless they
  are entirely standard
- Distinguish: model of interest vs estimating equation, parameters of
  interest vs nuisance parameters, identifying vs simplifying assumptions
- Once the math is written down, stick with it (consistent notation
  throughout the paper)

## E. Timeline (from Stage 2 workshop)

- July 3: Progress Assignment 2 (done)
- July 20: target for a complete first draft
- Required meeting 2 after PA2

## Notes

- Analysis code should be minimal; move transformations to the dataprep
  scripts; put complex calculations in functions; get the standard errors
  right.
- Write for the "robot": linear, clear, plain, formal. State assumptions,
  methods, findings.
