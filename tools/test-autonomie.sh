#!/usr/bin/env bash
# Auto-test du garde-fou : prouve que check-fls.sh rejette bien une dépendance
# hors du dépôt, et accepte le document normal.
#
# make test-autonomie   (ou ./tools/test-autonomie.sh)

set -u

REPO=$(git rev-parse --show-toplevel)
cd "$REPO"
TEX=${1:-ssh-indep.tex}
BASE=${TEX%.tex}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"; latexmk -c "$TEX" >/dev/null 2>&1' EXIT

fail=0

# --- test 1 : le document normal doit passer ---------------------------------
latexmk -pdf -shell-escape -halt-on-error -interaction=nonstopmode "$TEX" >/dev/null 2>&1
if ./tools/check-fls.sh "$BASE.fls" >/dev/null; then
  echo "test 1 OK : document autonome accepte"
else
  echo "test 1 ECHEC : le document autonome est rejette a tort"
  fail=1
fi

# --- test 2 : image chargee par un chemin absolu hors du depot ---------------
# Cas non detectable par le grep sur le source : \graphicspath ne contient
# ni \input ni « ../ ».
mkdir -p "$TMP/hors"
python3 - "$TMP/hors/logo.png" <<'PY'
import struct, sys, zlib
w = h = 8
raw = b''.join(b'\x00' + b'\x88\x44\x22' * w for _ in range(h))
def chunk(t, d):
    c = t + d
    return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
png = (b'\x89PNG\r\n\x1a\n'
       + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
       + chunk(b'IDAT', zlib.compress(raw))
       + chunk(b'IEND', b''))
open(sys.argv[1], 'wb').write(png)
PY

cp "$TEX" "$TMP/probe.tex"
python3 - "$TMP/probe.tex" "$TMP" <<'PY'
import sys
path, tmp = sys.argv[1], sys.argv[2]
src = open(path).read()
old = r'\graphicspath{{./images/}}'
new = r'\graphicspath{{%s/hors/}}' % tmp
if old in src:
    src = src.replace(old, new)
else:
    i = src.index(r'\begin{document}')
    src = src[:i] + r'\graphicspath{{%s/hors/}}' % tmp + '\n' + src[i:]
i = src.index(r'\begin{document}') + len(r'\begin{document}')
src = src[:i] + '\n\\iconetext{logo}\n' + src[i:]
open(path, 'w').write(src)
PY

cp "$TEX" "$TMP/keep.tex" 2>/dev/null
cp minted2.sty "$TMP/" 2>/dev/null
( cd "$TMP" && latexmk -pdf -shell-escape -interaction=nonstopmode probe.tex >/dev/null 2>&1 )

if [ -f "$TMP/probe.fls" ]; then
  if ./tools/check-fls.sh "$TMP/probe.fls" >/dev/null 2>&1; then
    echo "test 2 ECHEC : dependance hors depot acceptee (garde-fou inefficace)"
    fail=1
  else
    echo "test 2 OK : dependance hors du depot rejetee"
  fi
else
  echo "test 2 ECHEC : compilation du probe impossible, garde-fou non teste"
  fail=1
fi

# --- test 3 : \input par chemin absolu ---------------------------------------
echo "Dependance externe." > "$TMP/hors/autre.tex"
cp "$TEX" "$TMP/probe2.tex"
python3 - "$TMP/probe2.tex" "$TMP" <<'PY'
import sys
path, tmp = sys.argv[1], sys.argv[2]
src = open(path).read()
i = src.index(r'\begin{document}') + len(r'\begin{document}')
open(path, 'w').write(src[:i] + '\n\\input{%s/hors/autre.tex}\n' % tmp + src[i:])
PY
cp minted2.sty "$TMP/" 2>/dev/null
( cd "$TMP" && latexmk -pdf -shell-escape -interaction=nonstopmode probe2.tex >/dev/null 2>&1 )

if [ -f "$TMP/probe2.fls" ]; then
  if ./tools/check-fls.sh "$TMP/probe2.fls" >/dev/null 2>&1; then
    echo "test 3 ECHEC : \\input absolu hors depot accepte"
    fail=1
  else
    echo "test 3 OK : \\input absolu hors du depot rejete"
  fi
else
  echo "test 3 ECHEC : compilation du probe impossible, garde-fou non teste"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "garde-fou d'autonomie valide"
else
  exit 1
fi
