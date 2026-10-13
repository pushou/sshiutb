# Contribuer

Les contributions sont les bienvenues : coquilles, précisions techniques, nouvelles
questions, corrections d'exemples de commandes.

## Ce qui est attendu

1. **Le document doit rester autonome.** N'ajoutez pas de `\input{...}` ou
   `\include{...}` vers un fichier hors du dépôt : `ssh-indep.tex` doit se compiler seul.
   La CI vérifie ce point.
2. **Le document doit compiler.** Toute PR déclenche la compilation ; si elle échoue,
   la fusion est bloquée.
3. **Une modification par PR, une intention claire.** Décrivez dans la PR ce que vous
   changez et pourquoi (une commande SSH erronée, une explication ambiguë, un cas
   manquant).
4. **Vérifiez techniquement ce que vous avancez.** Les commandes de ce TP sont exécutables :
   testez-les sur deux VMs (un bastion exposé sur 2222, une cible en réseau interne)
   avant de proposer une correction.

## Avant d'ouvrir la PR

```bash
latexmk -pdf -shell-escape ssh-indep.tex
```

Le PDF doit être produit sans erreur. Les avertissements `multiply defined` sur les
labels de questions sont connus et acceptés (effets de `\printanswers` /
`\noprintanswers`).

## Ne pas supprimer `minted2.sty`

`minted2.sty` est une variante Debian de `minted` : elle n'existe ni dans TeXLive amont
ni dans Ubuntu. Elle est donc versionnée à la racine du dépôt (licence LPPL, voir son
en-tête) et LaTeX la charge depuis le dossier courant. Sans elle, la CI Ubuntu ne peut
pas compiler le document. Ne le remplacez pas par `minted` : `minted` v3 (TeXLive amont)
exige en plus un exécutable `minted` (pip), absent des images CI, et son rendu diffère
avec les options utilisées ici (`fontfamily=helvetica`, `baselinestretch`).

## Cycle de revue

1. Vous ouvrez une PR depuis une branche de votre fork.
2. La CI compile le document et publie le PDF en artifact : téléchargez-le pour relire
   le rendu, pas seulement le diff.
3. Le check `compile` doit être vert.
4. L'auteur relit, demande des changements éventuellement, puis fusionne.

## Ce que vérifie la CI

Quatre contrôles, tous bloquants :

1. `minted2.sty` est présent dans le dépôt.
2. Le source ne contient aucun `\input`, `\include`, `\import` ou `\subfile`
   (les lignes de commentaire sont ignorées, `\includegraphics` n'est pas concernée).
3. Le document compile sans erreur fatale et produit un PDF non vide.
4. Aucun fichier lu pendant la compilation ne sort du dépôt : la CI inspecte le
   *file* de latexmk (`ssh-indep.fls`) classe chaque entrée `INPUT` et rejette
   tout chemin qui n'est ni dans le dépôt ni dans un arbre TeX installé par le
   système. Ce contrôle attrape les dépendances invisibles au grep sur le source,
   par exemple une image atteinte via `\graphicspath{{/chemin/hors/depot/}}`
   (chemin absolu) ou `\graphicspath{{../outside/}}` (chemin relatif).
   Les arbres TeX personnels (`~/texmf`) sont volontairement exclus : un fichier
   qui n'existe que sur une machine est précisément ce que l'autonomie interdit.

Le garde-fou lui-même est testé : `make test-autonomie` compile deux documents
piégés (image par chemin absolu, `\input` absolu) et vérifie qu'ils sont bien
rejetés, en plus d'accepter le document normal.

`make check` exécute localement exactement les mêmes contrôles.

## Fusion

La branche `main` est protégée : le check `compile (LaTeX)` est obligatoire, y compris
pour l'auteur (un merge rouge est impossible, même en administrateur). Le dépôt impose
un historique linéaire, donc **les merge commits sont interdits** : la fusion se fait en
squash ou en rebase (`gh pr merge --squash`).

## Style

- Le document est en français.
- Les blocs de commandes utilisent l'environnement `bashcode` (minted) ; les réponses
  sont dans `\begin{solution}...\end{solution}` pour rester masquables.
- Les questions sont dans l'environnement `questions` avec `\question`.
