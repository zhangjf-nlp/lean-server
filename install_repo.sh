#!/usr/bin/env bash
install_repo() {
  local name="$1" url="$2" branch="$3" upd_manifest="$4"
  echo "Installing ${name}@${branch}..."
  if [ ! -d "$name" ]; then
    git clone --branch "${branch}" --single-branch --depth 1 "$url" "$name"
  fi
  pushd "$name"
    git checkout "${branch}"
    if [ "$name" = "mathlib4" ]; then
      #lake exe cache get
      wget https://github.com/leanprover-community/mathlib4/archive/refs/tags/${LEAN_SERVER_LEAN_VERSION}.tar.gz
      mkdir -p .lake/build
      tar -xzf ${LEAN_SERVER_LEAN_VERSION}.tar.gz -C .lake/build
    fi
    lake build
    if [ "$upd_manifest" = "true" ]; then
      jq '.packages |= map(.type="path"|del(.url)|.dir=".lake/packages/"+.name)' \
         lake-manifest.json > lake-manifest.json.tmp && mv lake-manifest.json.tmp lake-manifest.json
    fi
  popd
}

install_repo repl "$REPL_REPO_URL" "$REPL_BRANCH" false
install_repo mathlib4 "$MATHLIB_REPO_URL" "$MATHLIB_BRANCH" true