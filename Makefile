.PHONY: help format classify test

help:
	@echo "make venv        # initialize python virtual environment"
	@echo "make format      # generate correctly formatted benchmarks in folder prepared/"
	@echo "make classify    # generate files containing a classification into categories in prepared/"
	@echo "make lists       # generate .list files with paths to all benchmarks in each category"
	@echo "make ...         # TODO: document more commands"

venv:
	python3 -m venv venv
	venv/bin/pip3 install z3-solver
	@echo "now run `source venv/bin/activate` (resp. the correct script for your shell)"

SRC ?= $(shell find `cat family` -name "*.smt2")
MUZ ?= $(shell find `cat family` -name "*.muz")

# this variable defines the target folder into which the benchmarks are generated
PREPARED=prepared

# this variable defines the target folder for the benchmark categories
CATEGORIES=categories

# this command is how the benchmark files are formatted,
# note, it is implemented with the help of the python Z3 module,
# re-using its parser and printer
FORMAT=python3 ../scripts/format/src/format.py --merge_queries True

# this variable collects all target files that *should* be generated.
# for a file path/to/benchmark.smt2 in SRC, $FORMATTED will have an entry prepared/path/to/benchmark_000.smt2
# where the _000 will be added automatically by the format script
FORMATTED ?= $(MUZ:%.muz=$(PREPARED)/%_000.smt2) $(SRC:%.smt2=$(PREPARED)/%_000.smt2)

# below, we define two conversion rules, depending on whether the source is in the old moz format
# or whether it is in the newer smt2 format, both rules do exactly the same, as format.py understands both
$(PREPARED)/%_000.smt2: %.smt2
	mkdir -p $(PREPARED)/$(dir $*)
	$(FORMAT) --out_dir $(PREPARED)/$(dir $*) $<

$(PREPARED)/%_000.smt2: %.muz
	mkdir -p $(PREPARED)/$(dir $*)
	$(FORMAT) --out_dir $(PREPARED)/$(dir $*) $<

# this make target ensures that all files denoted by $FORMATTED should be generated
format: $(FORMATTED)

# we decouple classification from $FORMATTED, because not all benchmarks translate
# SMT2 are all smt2 files that are currently in the prepared folder
SMT2 ?= $(shell find $(PREPARED) -name "*.smt2")
CLASSIFIED = $(SMT2:%.smt2=%.txt)

# this rule produces a txt file for the a given smt2 file which contains the name of the category
$(PREPARED)/%.txt: $(PREPARED)/%.smt2
	./classify $^ $@

classify: $(CLASSIFIED)

# category definitions
TRACKS ?= LIA-Lin LIA LIA-Lin-Arrays LIA-Arrays ADT-LIA ADT-LIA-Arrays #  LIA-LRA-TS
LISTS = $(addsuffix .list,$(TRACKS))

%.list: 
	grep $* $(PREPARED) -r -x -l | sed "s/.txt/.smt2/" | tee $@

lists: $(LISTS)

CATEGORY ?= LIA
SRC = $(shell cat $(CATEGORY).list)
DST = $(SRC:$(PREPARED)/%=$(CATEGORIES)/$(CATEGORY)/%)

$(CATEGORIES)/$(CATEGORY)/%.smt2: $(PREPARED)/%.smt2
	mkdir -p `dirname $@`
	ln -srf $< $@

categorize: $(DST)

# this rule produces a txt file for the a given smt2 file which contains the name of the category

TIMEOUT ?= 30s

$(CATEGORIES)/LIA-Lin/%.txt: $(CATEGORIES)/LIA-Lin/%.smt2
	./difficulty $(TIMEOUT) "golem --engine spacer,lawi,split-tpa" "eld -portfolio" $^ $@

$(CATEGORIES)/LIA/%.txt: $(CATEGORIES)/LIA/%.smt2
	./difficulty $(TIMEOUT) "eld -portfolio" "golem --engine spacer" $^ $@

$(CATEGORIES)/LIA-Lin-Arrays/%.txt: $(CATEGORIES)/LIA-Lin-Arrays/%.smt2
	./difficulty $(TIMEOUT) "eld -portfolio" "z3" $^ $@

$(CATEGORIES)/LIA-Arrays/%.txt: $(CATEGORIES)/LIA-Arrays/%.smt2
	./difficulty $(TIMEOUT) "eld -portfolio" "z3" $^ $@

$(CATEGORIES)/ADT-LIA/%.txt: $(CATEGORIES)/ADT-LIA/%.smt2
	./difficulty $(TIMEOUT) "eld -portfolio" "z3" $^ $@

$(CATEGORIES)/ADT-LIA-Arrays/%.txt: $(CATEGORIES)/ADT-LIA-Arrays/%.smt2
	./difficulty $(TIMEOUT) "eld -portfolio" "z3" $^ $@

RANK = $(DST:%.smt2=%.txt)

rank: $(RANK)

rank-clean:
	find $(CATEGORIES)/$(CATEGORY) | grep .txt | xargs rm

SELECT = $(addsuffix .select,$(TRACKS))

N=300

$(CATEGORIES)/%/ranked.csv:
	./collect $(CATEGORIES)/$*

collect: $(addprefix $(CATEGORIES)/,$(addsuffix /ranked.csv,$(TRACKS)))

collect-clean:
	rm $(CATEGORIES)/*/ranked.csv

%.select: $(CATEGORIES)/%/ranked.csv
	./select $N $<  | sort > $@

select: $(SELECT)

%.zip: %.select
	cat $< | cut -d ";" -f 2 | zip $@ -@

%.uniq: %.select
	cat $< | xargs md5sum | cut -d " " -f 1 | sort | uniq > $@

zip: $(addsuffix .zip,$(TRACKS))
uniq: $(addsuffix .uniq,$(TRACKS))

test:
	@echo "test"

