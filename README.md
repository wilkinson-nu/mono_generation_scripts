All of the generated files are here: `/global/cfs/cdirs/nuisance/MC_mono`, under subdirectories for each generator, the naming should be self-explanatory.

On Perlmutter you can run the example plotting script with:
```
shifter --entrypoint --image=docker:wilkinsonnu/nuisance_project:genie_v3.00.06 python make_basic_plots.py
```
(But really you can probably get the ROOT version from anywhere)
