# Contribuer

Ce TP est écrit **en commun** : les étudiants qui le font sont censés l'améliorer.
Une commande mal écrite, un piège oublié, une explication obscure : ce sont des
contributions légitimes.

Le principe qui organise tout : **une idée se signale par une issue, une issue se
règle par une petite pull request.**

## Le cycle en quatre étapes

1. **Ouvrir une issue.** Vous avez repéré quelque chose ? Décrivez-le, sans corriger
   quoi que ce soit. Les trois modèles disponibles (bouton *New issue*) :
   * *Signaler une commande erronée*
   * *Proposer une question*
   * *Demander une clarification*

   Une issue porte une **intention**, pas un diff. Elle sert à se mettre d'accord sur
   le problème avant d'écrire du LaTeX.

2. **Attendre un feu vert.** L'auteur (ou un autre étudiant) commente, valide, ou
   propose une autre formulation. Le label passe à `bonne-premiere-PR` si la tâche est
   accessible.

3. **Ouvrir une PR.** Une seule intention, une seule section. La PR est compilée par
   la CI ; si la compilation échoue, elle ne peut pas être fusionnée.

4. **Relire le PDF de la CI, pas le diff.** Chaque run publie un artifact
   `ssh-indep-pdf`. Ouvrez-le à la page concernée : un diff LaTeX ne montre ni une
   page cassée, ni un tableau débordé, ni une commande coupée en deux.

## Les labels

| Label | Sens |
|---|---|
| `correction-commande` | une commande du TP est fausse, incomplète ou dangereuse |
| `nouvelle-question` | ajouter une question ou un exercice |
| `piege-a-documenter` | un comportement contre-intuitif de SSH mérite une explication |
| `precision-redaction` | clarifier une phrase, corriger une coquille |
| `cheatsheet` | compléter le mémo final |
| `bonne-premiere-PR` | tâche accessible pour une première contribution |
| `a-verifier-sur-terrain` | la proposition doit être testée sur bastion + cible |

Cherchez une issue avec `bonne-premiere-PR` pour commencer :
<https://github.com/pushou/sshiutb/labels/bonne-premiere-PR>

## Comment fork et envoyer une PR

```bash
# 1. sur github.com : bouton "Fork" vers votre compte, puis
git clone https://github.com/VOTRE-COMPTE/sshiutb.git
cd sshiutb

# 2. une branche par intention
git checkout -b corriger-tunnel-distant

# 3. modifier, puis compiler localement
make check          # compilation + preuve d'autonomie

# 4. pousser et ouvrir la PR depuis la branche
git push -u origin corriger-tunnel-distant
```

Une PR doit rester **petite** : une question ajoutée, une commande corrigée, une
phrase clarifiée. Une PR qui réécrit trois sections est refusée non par principe mais
parce qu'elle est illisible en revue.

## Les deux règles non négociables

### 1. Ne proposez pas une commande que vous n'avez pas exécutée

Le TP est un document d'exécution : tout ce qu'il affirme doit avoir été observé.
Dans la PR, collez les commandes réellement lancées sur les deux VMs (bastion exposé
sur 2222, cible en réseau interne) et leur sortie. Une correction « d'après moi »
n'est pas une correction.

### 2. Le document doit rester autonome

`ssh-indep.tex` et les fichiers qu'il lit doivent être **dans le dépôt**. Aucune
dépendance vers un fichier extérieur, même proche, même sur votre machine.

La CI ne se contente pas de lire le source : elle classe **chaque fichier réellement
ouvert pendant la compilation** (le *file* de latexmk, `ssh-indep.fls`) et refuse tout
chemin qui n'est ni dans le dépôt ni dans un arbre TeX installé par le système. Ce
contrôle attrape les dépendances invisibles au grep sur le `.tex`, par exemple une
image atteinte via `\graphicspath{{/chemin/hors/depot/}}` ou `\graphicspath{{../outside/}}`.

Les arbres TeX personnels (`~/texmf`) sont volontairement exclus : un fichier qui
n'existe que sur une machine est précisément ce que l'autonomie interdit.

Si vous ajoutez une image, versionnez-la dans le dépôt. `\graphicspath` doit pointer
uniquement vers un dossier qui y est présent.

Le garde-fou est lui-même testé :

```bash
make test-autonomie
```

## Avant d'ouvrir la PR

```bash
make check
```

Le PDF doit être produit sans erreur, et l'autonomie vérifiée. Les avertissements
`multiply defined` sur les labels de questions sont connus et acceptés (effets de
`\printanswers` / `\noprintanswers`).

## Ne pas supprimer `minted2.sty`

`minted2.sty` est une variante Debian de `minted` : elle n'existe ni dans TeXLive amont
ni dans Ubuntu. Elle est donc versionnée à la racine du dépôt (licence LPPL, voir son
en-tête) et LaTeX la charge depuis le dossier courant. Sans elle, la CI Ubuntu ne peut
pas compiler le document. Ne la remplacez pas par `minted` : `minted` v3 (TeXLive amont)
exige en plus un exécutable `minted` (pip), absent des images CI, et son rendu diffère
avec les options utilisées ici (`fontfamily=helvetica`, `baselinestretch`).

## Licence de votre contribution

Le support de cours est sous **CC BY-SA 4.0** (voir `LICENSE` et `NOTICE`).

En ouvrant une PR, vous acceptez que votre contribution soit intégrée au dépôt sous
cette licence : elle sera redistribuée avec le document, créditée, et ses dérivés
devront rester sous la même licence. `minted2.sty` reste sous LPPL et n'est pas
concerné par vos contributions.

## Ce que vérifie la CI

Quatre contrôles, tous bloquants :

1. `minted2.sty` est présent dans le dépôt.
2. Le source ne contient aucun `\input`, `\include`, `\import` ou `\subfile`
   (les lignes de commentaire sont ignorées, `\includegraphics` n'est pas concernée).
3. Le document compile sans erreur fatale et produit un PDF non vide.
4. Aucun fichier lu pendant la compilation ne sort du dépôt (voir plus haut).

## Fusion

La branche `main` est protégée : le check `compile (LaTeX)` est obligatoire, y compris
pour l'auteur (un merge rouge est impossible, même en administrateur). Le dépôt impose
un historique linéaire, donc **les merge commits sont interdits** : la fusion se fait en
squash ou en rebase (`gh pr merge --squash`).

## Premier contributeur : la CI démarre en attente

GitHub ne lance pas les workflows à l'aveugle pour un contributeur qui n'a jamais
contribué au dépôt. À l'ouverture de votre **première** PR, le check `compile (LaTeX)`
apparaît en attente d'approbation (`action_required`) : le bouton *Review pending
changes* est visible sur la page du run.

Ce n'est pas une panne et ce n'est pas un refus. Il faut qu'un membre du dépôt
approuve l'exécution. Concrètement : **commentez votre PR** en demandant le lancement
de la CI, l'auteur approuve, et le run démarre. Une fois votre première contribution
fusionnée, vos PR suivantes compilent sans cette étape.

Si vous voyez `pending` sans jamais passer à `pass`, c'est presque toujours cet
attente : dites-le plutôt que de pousser des commits en plus.

## Style

- Le document est en français.
- Les blocs de commandes utilisent l'environnement `bashcode` (minted) ; les réponses
  sont dans `\begin{solution}...\end{solution}` pour rester masquables.
- Les questions sont dans l'environnement `questions` avec `\question`.
- Une question doit être **vérifiable par une commande** : on doit pouvoir prouver la
  réponse en exécutant quelque chose sur les deux VMs.
