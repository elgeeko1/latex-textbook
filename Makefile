# Author: Jeff C. Jensen
# Date: 2015-10-16
# Copyright: (c) 2015, all rights reserved.
# License: Creative Commons Attribution 4.0 International (CC BY 4.0).
# 
# To build a PDF using draft and solutions modes as defined below:
#   make
# 
# To clean:
#   make clean
#
# Requires: LaTeX build system in path. Calls pdflatex, bibtex, makeindex.
#			[Windows] MinGW+MinSYS or Cygwin (also recommended: WinEdt)
#			[Mac] MacTex
#			[Linux] texlive-all (also recommended: Kile IDE and Okular PDF viewer)

# Build commands
PDFLATEX ?= pdflatex -interaction=errorstopmode
GREPERRORS ?= (grep -A3 "TeX Error\|\!" || true)
GREPWARNINGS ?= (grep -A3 "TeX Warning\|TeX Error\|\!" || true)
BIBTEX ?= bibtex -terse
MAKEINDEX ?= makeindex -q

# Build source and distribution information
# This is the name of the .tex file (without the .tex).
# All build dependencies are automatically generated from this name.
TEXFILE ?= book

# LaTeX dependencies
target  = $(TEXFILE)
pdffile = $(target).pdf
auxfile = $(target).aux
idxfile = $(target).idx
indfile = $(target).ind
logfile = $(target).log

# trim whitespace
sedremovewhitespace = sed -e "/^[[:space:]]*$$/d" -e "s/[[:space:]]\+/ /g"
	
# Build the TeX file
all $(pdffile): $(auxfile) $(indfile)
	@$(RM) $(pdffile)
	@echo Building LaTeX
	@$(PDFLATEX) $(TEXFILE) | $(GREPERRORS)
	@if grep -q "TeX Error\|\!" $(logfile); \
		then echo LaTeX reported build errors && false ; \
	fi
	@if grep -q "undefined citations" $(logfile); \
		then echo Building LaTeX bibliography \
			&& $(BIBTEX) $(auxfile) \
			&& echo Rebuilding LaTeX with new bibliography \
			&& $(PDFLATEX) $(TEXFILE) | $(GREPERRORS); \
	fi
	@while grep -q "Rerun to" $(logfile); \
		do echo Rebuilding LaTeX for cross-references \
			&& $(PDFLATEX) $(TEXFILE) | $(GREPERRORS); \
	done
	@cat $(logfile) | $(GREPWARNINGS)
	@echo LaTeX build complete.

clean:
	@$(RM) $(target).out $(target).blg $(target).synctex
	@$(RM) $(target).bbl $(target).lof $(target).lot
	@$(RM) $(target).idx $(target).ilg $(target).ind
	@$(RM) $(target).maf $(target).mtc $(target).mtc?
	@$(RM) $(target).nav $(target).snm $(target).toc
	@$(RM) $(auxfile) $(logfile) $(pdffile) $(idxfile) $(indfile)
	@$(RM) *.log
	
# Builds require an .aux file; if none, build here
.SECONDARY: $(auxfile)
%.aux: %.tex
	@echo Building LaTeX auxiliary files
	@$(PDFLATEX) -draftmode $(TEXFILE) | $(GREPERRORS)

# Builds require an index file; if none, build here
.SECONDARY: $(indfile)
%.ind: %.tex
	@echo Building LaTeX index
	@$(MAKEINDEX) $(idxfile)
