# CHC-COMP 2024 Scripts

This repository documents the scripts used in CHC-COMP 2024.
Here are the rough steps to prepare the benchmarks.

Make sure to read the comments in `Makefile`.
In general, all `make` commands can be parallelized with the `-j` flag.

## Prepare a Python environment (optional)

Purpose: install `python-z3` which is needed for various processing steps.
Can be skipped if this package is installed globally.

```bash
make venv
source venv/bin/activate # enter venv, needed in each shell
```

## Download all repositories

File `family` (historic name) contains the names of all repositories with
benchmarks that were used for CHC-COMP 2024.

Clone them all locally, something like (untested):

```bash
for a in `cat family`; do git clone https://github.com/chc-comp/$a.git; done
```

The space required is in the order of 60GB.

## Format all files according to the [CHC-COMP requirements](https://github.com/chc-comp/chc-tools.git)

```
# make sure the formatting script is available
git clone https://github.com/chc-comp/scripts.git ../scripts

# run 8 instances in parallel, adjust to available CPUs
make -j 8 format
```

## Classify benchmark files per difficulty

Download and make solvers available in subfolder `./solvers`
- `./solvers/z3` Z3 version 4.13.0 - 64 bit from https://github.com/Z3Prover/z3
- `./solvers/eld` Eldarica v2.0.9. from https://github.com/uuverifiers/eldarica
- `./solvers/golem` Golem 0.5.0 from https://github.com/usi-verification-and-security/golem

```bash
make -j 8 classify
```

## ...

Further steps to be documented
