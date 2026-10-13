#!/usr/bin/env bash
# Verifie qu'aucun fichier lu pendant la compilation ne sort du depot.
#
# Le controle ne peut pas se limiter aux chemins relatifs « ../ » : un
# \graphicspath{{/chemin/absolu/hors/depot/}} est invisible au grep sur le
# source et ne contient pas de « ../ ». On classe donc chaque entree INPUT
# du file de latexmk :
#   - chemin relatif            -> lu depuis le depot, OK
#   - chemin absolu dans le depot -> OK
#   - chemin absolu dans un arbre TeX installe par le systeme -> OK
#   - tout autre chemin absolu  -> HORS DEPOT, erreur
#
# Les arbres TeX utilisateur (TEXMFHOME, TEXMFVAR) sont volontairement exclus :
# un fichier qui n'existe que dans le home d'une machine est exactement le type
# de dependance qu'autonomie veut interdire.

set -u

FLS=${1:-}
if [ -z "$FLS" ] || [ ! -f "$FLS" ]; then
  echo "usage: $0 <fichier.fls>" >&2
  exit 2
fi

# Repertoire de compilation : les INPUT relatifs du file y sont relatifs.
FLS_DIR=$(cd "$(dirname "$FLS")" && pwd)

REPO=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO" ]; then
  echo "erreur: pas dans un depot git" >&2
  exit 2
fi

# Arbres TeX systeme, declares par kpathsea (les memes que la CI installe).
roots=()
for v in TEXMFMAIN TEXMFDIST TEXMFLOCAL TEXMFSYSVAR TEXMFSYSCONF; do
  p=$(kpsewhich -var-value "$v" 2>/dev/null)
  case "$p" in
    /*) roots+=("$p") ;;
  esac
done
# Racines Debian/Ubuntu usuelles, pas toujours declarees par kpathsea.
roots+=(/usr/share/texmf /usr/share/texlive /var/lib/texmf /etc/texmf /usr/local/share/texmf)

norm() {
  # Normalise sans exiger que le chemin existe (realpath -m).
  realpath -m -- "$1" 2>/dev/null || printf '%s\n' "$1"
}

REPO_NORM=$(norm "$REPO")
allowed=("$REPO_NORM")
for r in "${roots[@]}"; do
  allowed+=("$(norm "$r")")
done

inside() {
  local f=$1 a
  for a in "${allowed[@]}"; do
    [ -z "$a" ] && continue
    case "$f" in
      "$a"|"$a"/*) return 0 ;;
    esac
  done
  return 1
}

outside=0
total=0
while read -r _ path; do
  [ -z "$path" ] && continue
  total=$((total + 1))
  case "$path" in
    /*) abs=$path ;;                                  # absolu : a controler
    *)  abs="$FLS_DIR/$path" ;;                       # relatif : resolu
  esac
  if ! inside "$(norm "$abs")"; then
    echo "HORS DEPOT: $path"
    outside=$((outside + 1))
  fi
done < <(grep '^INPUT ' "$FLS")

if [ "$outside" -ne 0 ]; then
  echo "ERREUR : $outside fichier(s) lu(s) hors du depot et hors arbres TeX systeme."
  echo "Le document doit rester autonome."
  exit 1
fi

echo "Autonomie verifiee : $total fichiers lus, tous dans le depot ou dans un arbre TeX installe."
