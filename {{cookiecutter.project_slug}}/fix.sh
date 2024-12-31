#!/bin/bash -eu

set -o pipefail

if [ -n "${FIX_SH_TIMING_LOG+x}" ]; then
    rm -f "${FIX_SH_TIMING_LOG}"
    if ! type gdate >/dev/null 2>&1; then sudo ln -sf /bin/date /bin/gdate; fi
fi

debug_timing() {
  if [ -n "${FIX_SH_TIMING_LOG+x}" ]; then
    # shellcheck disable=SC2034
    _lastcmd=$(gdate +%s%3N)
    last_command='start'
    # shellcheck disable=SC2154
    trap '_now=$(gdate +%s%3N); duration=$((_now - _lastcmd)); echo ${duration} ms: $last_command >> '"${FIX_SH_TIMING_LOG}"'; last_command="$BASH_COMMAND" >> '"${FIX_SH_TIMING_LOG}"'; _lastcmd=$_now' DEBUG
  fi
}

# copy this into any function you want to debug further
debug_timing

set -o pipefail

install_rbenv() {
  if [ "$(uname)" == "Darwin" ]
  then
    HOMEBREW_NO_AUTO_UPDATE=1 brew install rbenv || true
    if ! type rbenv 2>/dev/null
    then
      # https://github.com/pyenv/pyenv-installer/blob/master/bin/pyenv-installer
      >&2 cat <<EOF
WARNING: seems you still have not added 'rbenv' to the load path.

# Load rbenv automatically by adding
# the following to ~/.bashrc:

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
EOF
    fi
  else
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  fi
}

set_rbenv_env_variables() {
  export PATH="${HOME}/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
}

install_ruby_build() {
  if [ "$(uname)" == "Darwin" ]
  then
    HOMEBREW_NO_AUTO_UPDATE=1 brew install ruby-build || true
  else
    mkdir -p "$(rbenv root)"/plugins
    git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
  fi
}

ensure_ruby_build() {
  if ! type ruby-build >/dev/null 2>&1 && ! [ -d "${HOME}/.rbenv/plugins/ruby-build" ]
  then
    install_ruby_build
  fi
}

ensure_rbenv() {
  if ! type rbenv >/dev/null 2>&1 && ! [ -f "${HOME}/.rbenv/bin/rbenv" ]
  then
    install_rbenv
  fi

  set_rbenv_env_variables

  ensure_ruby_build
}

latest_ruby_version() {
  major_minor=${1}

  # Double check that this command doesn't error out under -e
  rbenv install --list >/dev/null 2>&1

  # not sure why, but 'rbenv install --list' below exits with error code
  # 1...after providing the same output the previous line gave when it
  # exited with error code 0.
  #
  # https://github.com/rbenv/rbenv/issues/1441
  set +e
  rbenv install --list 2>/dev/null | cat | grep "^${major_minor}."
  set -e
}

ensure_binary_library() {
  library_base_name=${1:?library base name - like libfoo}
  homebrew_package=${2:?homebrew package}
  apt_package=${3:-${homebrew_package}}
  if ! [ -f /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/lib/"${library_base_name}*.dylib" ] && \
      ! [ -f /opt/homebrew/lib/"${library_base_name}*.dylib" ] && \
      ! [ -f /usr/lib/"${library_base_name}.so" ] && \
      ! [ -f /usr/lib/x86_64-linux-gnu/"${library_base_name}.so" ] && \
      ! [ -f /usr/local/lib/"${library_base_name}.so" ] && \
      ! [ -f /usr/local/opt/"${homebrew_package}/lib/${library_base_name}*.dylib" ]
  then
      if ! compgen -G "/opt/homebrew/Cellar/${homebrew_package}"*/*/"lib/${library_base_name}"*.dylib >/dev/null 2>&1
      then
        install_package "${homebrew_package}" "${apt_package}"
      fi
  fi
}

ensure_ruby_build_requirements() {
  ensure_dev_library readline/readline.h readline libreadline-dev
  ensure_dev_library zlib.h zlib zlib1g-dev
  ensure_dev_library openssl/ssl.h openssl libssl-dev
  ensure_dev_library yaml.h libyaml libyaml-dev
}

ensure_latest_ruby_build_definitions() {
  ensure_rbenv

#  last_pulled_unix_epoch="$(stat -f '%m' "$(rbenv root)"/plugins/ruby-build/.git/FETCH_HEAD)"
#  # if not pulled in last 24 hours
#  if [ $(( $(date +%s) - last_pulled_unix_epoch )) -gt $(( 24 * 60 * 60 )) ]
#  then
      git -C "$HOME"/.rbenv/plugins/ruby-build pull --force
#  fi
}

# https://stackoverflow.com/questions/2829613/how-do-you-tell-if-a-string-contains-another-string-in-posix-sh
contains() {
  string="$1"
  substring="$2"
  if [ "${string#*"$substring"}" != "$string" ]; then
    return 0    # $substring is in $string
  else
    return 1    # $substring is not in $string
  fi
}

# You can find out which feature versions are still supported / have
# been release here: https://www.ruby-lang.org/en/downloads/
ensure_ruby_versions() {
  ensure_latest_ruby_build_definitions

  # You can find out which feature versions are still supported / have
  # been release here: https://www.ruby-lang.org/en/downloads/
  ruby_versions="$(latest_ruby_version 3.3)"

  installed_ruby_versions="$(rbenv versions --bare --skip-aliases)"

  echo "Latest Ruby versions: ${ruby_versions}"

  for ver in $ruby_versions
  do
    if ! contains "${installed_ruby_versions}"$'\n' "${ver}"$'\n'; then
      echo "Installing Ruby version $ver - existing versions: $installed_ruby_versions"
      ensure_ruby_build_requirements

      rbenv install -s "${ver}"
      hash -r  # ensure we are seeing latest bundler etc
    else
      echo "Found Ruby version $ver already installed"
    fi
  done
}

ensure_bundle() {
  # Not sure why this is needed a second time, but it seems to be?
  #
  # https://app.circleci.com/pipelines/github/apiology/source_finder/21/workflows/88db659f-a4f4-4751-abc0-46f5929d8e58/jobs/107
  set_rbenv_env_variables

  bundler_version=$(ruby -e 'require "rubygems/bundler_version_finder"; puts Gem::BundlerVersionFinder.bundler_version')
  # if bundler_version is empty
  if [ -z "${bundler_version}" ]
  then
      bundler_version=$(bundle --version | cut -d ' ' -f 3)
  fi
  # if bundler_version is still empty
  if [ -z "${bundler_version}" ]
  then
      gem install bundler
      bundler_version=$(bundle --version | cut -d ' ' -f 3)
  fi
  echo "Bundler version: ${bundler_version}"
  bundler_version_major=$(cut -d. -f1 <<< "${bundler_version}")
  bundler_version_minor=$(cut -d. -f2 <<< "${bundler_version}")
  bundler_version_patch=$(cut -d. -f3 <<< "${bundler_version}")
  # Version 2.1 of bundler seems to have some issues with nokogiri:
  #
  # https://app.asana.com/0/1107901397356088/1199504270687298

  # Version <2.2.22 of bundler isn't compatible with Ruby 3.3:
  #
  # https://stackoverflow.com/questions/70800753/rails-calling-didyoumeanspell-checkers-mergeerror-name-spell-checker-h
  need_better_bundler=false
  if [ "${bundler_version_major}" -lt 2 ]
  then
    need_better_bundler=true
  elif [ "${bundler_version_major}" -eq 2 ]
  then
    if [ "${bundler_version_minor}" -lt 2 ]
    then
      need_better_bundler=true
    elif [ "${bundler_version_minor}" -eq 2 ]
    then
      if [ "${bundler_version_patch}" -lt 23 ]
      then
        need_better_bundler=true
      fi
    fi
  fi
  if [ "${need_better_bundler}" = true ]
  then
    >&2 echo "Original bundler version: ${bundler_version}"
    # need to do this first before 'bundle update --bundler' will work
    make bundle_install
    bundle update --bundler
    gem install bundler:2.2.23
    >&2 echo "Updated bundler version: $(bundle --version)"
    # ensure next step installs fresh bundle
    rm -f Gemfile.lock.installed
  fi
  # https://bundler.io/v2.0/bundle_lock.html#SUPPORTING-OTHER-PLATFORMS
  #
  # "If you want your bundle to support platforms other than the one
  # you're running locally, you can run bundle lock --add-platform
  # PLATFORM to add PLATFORM to the lockfile, force bundler to
  # re-resolve and consider the new platform when picking gems, all
  # without needing to have a machine that matches PLATFORM handy to
  # install those platform-specific gems on.'
  #
  # This affects nokogiri, which will try to reinstall itself in
  # Docker builds where it's already installed if this is not run.
  make Gemfile.lock
  PLATFORMS="arm64-darwin-24 x86_64-linux x86_64-linux-musl aarch64-linux aarch64-linux-musl"
  for platform in ${PLATFORMS}
  do
    if ! grep -q "^  ${platform}$" Gemfile.lock
    then
      echo "Missing platform $platform in Gemfile.lock - adding all of ${PLATFORMS}"
      bundle lock --add-platform "${PLATFORMS// /,}"
      break
    fi
  done
  make bundle_install
}

set_ruby_local_version() {
  latest_ruby_version="$(cut -d' ' -f1 <<< "${ruby_versions}")"
  echo "${latest_ruby_version}" > .ruby-version
}

latest_python_version() {
  major_minor=${1}
  # https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
  pyenv install --list | grep "^  ${major_minor}." | grep -v -- -dev | tail -1 | xargs
}

install_pyenv() {
  if [ "$(uname)" == "Darwin" ]
  then
    HOMEBREW_NO_AUTO_UPDATE=1 brew install pyenv || true
    if ! type pyenv 2>/dev/null
    then
      # https://github.com/pyenv/pyenv-installer/blob/master/bin/pyenv-installer
      >&2 cat <<EOF
WARNING: seems you still have not added 'pyenv' to the load path.

# Load pyenv automatically by adding
# the following to ~/.bashrc:

export PYENV_ROOT="${HOME}/.pyenv"
export PATH="${PYENV_ROOT}/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"
EOF
    fi
  else
    curl https://pyenv.run | bash
  fi
}

set_pyenv_env_variables() {
  # looks like pyenv scripts aren't -u clean:
  #
  # https://app.circleci.com/pipelines/github/apiology/cookiecutter-pypackage/15/workflows/10506069-7662-46bd-b915-2992db3f795b/jobs/15
  set +u
  export PYENV_ROOT="${HOME}/.pyenv"
  export PATH="${PYENV_ROOT}/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv virtualenv-init -)"
  set -u
}

ensure_pyenv() {
  if ! type pyenv >/dev/null 2>&1 && ! [ -f "${HOME}/.pyenv/bin/pyenv" ]
  then
    install_pyenv
  fi

  if ! type pyenv >/dev/null 2>&1
  then
    set_pyenv_env_variables
  fi
}

update_package() {
  homebrew_package=${1:?homebrew package}
  apt_package=${2:-${homebrew_package}}
  if [ "$(uname)" == "Darwin" ]
  then
    brew install "${homebrew_package}"
  elif type apt-get >/dev/null 2>&1
  then
    make update_apt
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${apt_package}"
  else
    >&2 echo "Teach me how to install packages on this plaform"
    exit 1
  fi
}

ensure_python_build_requirements() {
  ensure_dev_library zlib.h zlib zlib1g-dev
  ensure_dev_library bzlib.h bzip2 libbz2-dev
  ensure_dev_library openssl/ssl.h openssl libssl-dev
  ensure_dev_library ffi/ffi.h libffi libffi-dev
  ensure_dev_library sqlite3.h sqlite3 libsqlite3-dev
  ensure_dev_library lzma.h xz liblzma-dev
  ensure_dev_library readline/readline.h readline libreadline-dev
}

# You can find out which feature versions are still supported / have
# been release here: https://www.python.org/downloads/
ensure_python_versions() {
  # You can find out which feature versions are still supported / have
  # been release here: https://www.python.org/downloads/
  python_versions="$(latest_python_version 3.12)"

  echo "Latest Python versions: ${python_versions}"

  installed_python_versions="$(pyenv versions --skip-envs --skip-aliases --bare)"

  for ver in $python_versions
  do
    if ! contains "${installed_python_versions}"$'\n' "${ver}"$'\n'; then
      echo "Installing Python version $ver - existing versions: $installed_python_versions"
      ensure_python_build_requirements

      if [ "$(uname)" == Darwin ]
      then
        if [ -z "${HOMEBREW_OPENSSL_PREFIX:-}" ]
        then
          HOMEBREW_OPENSSL_PREFIX="$(brew --prefix openssl)"
        fi
        pyenv_install() {
          CFLAGS="-I/usr/local/opt/zlib/include -I/usr/local/opt/bzip2/include -I${HOMEBREW_OPENSSL_PREFIX}/include" LDFLAGS="-L/usr/local/opt/zlib/lib -L/usr/local/opt/bzip2/lib -L${HOMEBREW_OPENSSL_PREFIX}/lib" pyenv install --skip-existing "$@"
        }

        major_minor="$(cut -d. -f1-2 <<<"${ver}")"
        pyenv_install "${ver}"
      else
        pyenv install -s "${ver}"
      fi
      hash -r
    else
      echo "Found Python version $ver already installed"
    fi
  done
}

ensure_pyenv_virtualenvs() {
  latest_python_version="$(cut -d' ' -f1 <<< "${python_versions}")"
  virtualenv_name="{{cookiecutter.project_slug}}-${latest_python_version}"
  if ! [ -d ~/".pyenv/versions/${virtualenv_name}" ]
  then
    pyenv virtualenv "${latest_python_version}" "${virtualenv_name}" || true
  fi
  # You can use this for your global stuff!
  if ! [ -d ~/".pyenv/versions/mylibs" ]
  then
    pyenv virtualenv "${latest_python_version}" mylibs || true
  fi
  # shellcheck disable=SC2086
  pyenv local "${virtualenv_name}" ${python_versions} mylibs
}

ensure_pip_and_wheel() {
  # https://cve.mitre.org/cgi-bin/cvename.cgi?name=2023-5752
  pip_version=$(python -c "import pip; print(pip.__version__)" | cut -d' ' -f2)
  major_pip_version=$(cut -d '.' -f 1 <<< "${pip_version}")
  minor_pip_version=$(cut -d '.' -f 2 <<< "${pip_version}")
  if [[ major_pip_version -lt 23 ]]
  then
      pip install 'pip>=23.3'
  elif [[ major_pip_version -eq 23 ]] && [[ minor_pip_version -lt 3 ]]
  then
      pip install 'pip>=23.3'
  fi
  # wheel is helpful for being able to cache long package builds
  type wheel >/dev/null 2>&1 || pip install wheel
}

ensure_python_requirements() {
  make pip_install
}

ensure_shellcheck() {
  if ! type shellcheck >/dev/null 2>&1
  then
    install_package shellcheck
  fi
}

ensure_overcommit() {
  # don't run if we're in the middle of a cookiecutter child project
  # test, or otherwise don't have a Git repo to install hooks into...
  if [ -d .git ]
  then
    bundle exec overcommit --install
    bundle exec overcommit --sign
    bundle exec overcommit --sign pre-commit
  else
    >&2 echo 'Not in a git repo; not installing git hooks'
  fi
}

ensure_types_built() {
  make build-typecheck
}

ensure_ruby_versions

set_ruby_local_version

ensure_bundle

ensure_pyenv

ensure_python_versions

ensure_pyenv_virtualenvs

ensure_pip_and_wheel

ensure_python_requirements

ensure_shellcheck

ensure_types_built

ensure_overcommit
