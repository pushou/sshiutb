# Makefile du TP SSH autonome
# make        : compile ssh-indep.pdf
# make check  : compilation stricte (utilisée par la CI) + vérification d'autonomie
# make test-autonomie : prouve que le garde-fou d'autonomie fonctionne
# make clean  : supprime les fichiers auxiliaires

TEX   := ssh-indep.tex
PDF   := $(TEX:.tex=.pdf)
LATEX := latexmk -pdf -shell-escape -interaction=nonstopmode

.PHONY: all check test-autonomie clean

all: $(PDF)

$(PDF): $(TEX)
	$(LATEX) $(TEX)

check: $(TEX)
	@# 1. le document ne doit dépendre d'aucun fichier extérieur
	@if grep -nE '^[^%]*\\(input|include|import|subfile)([^a-zA-Z]|$$)' $(TEX); then \
	  echo "ERREUR : dépendance externe détectée dans $(TEX)"; exit 1; \
	fi
	@# 2. le document doit compiler sans erreur
	$(LATEX) -halt-on-error $(TEX)
	@# 3. le PDF doit exister et être de taille raisonnable
	@test -s $(PDF) || { echo "ERREUR : $(PDF) absent ou vide"; exit 1; }
	@# 4. aucun fichier lu ne doit sortir du dépôt (preuve d'autonomie)
	@#    Le contrôle porte sur le file de latexmk, pas seulement sur le source :
	@#    un \graphicspath{{/chemin/absolu}} est invisible au grep sur le .tex.
	./tools/check-fls.sh $(TEX:.tex=.fls)
	@echo "OK : $(PDF) compilé ($$(wc -c < $(PDF)) octets), autonomie vérifiée"

test-autonomie:
	./tools/test-autonomie.sh $(TEX)

clean:
	latexmk -c $(TEX)
	rm -rf _minted-* *.w18 *.aex *.pyg
