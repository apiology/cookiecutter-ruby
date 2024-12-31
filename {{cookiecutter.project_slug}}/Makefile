.PHONY: build-typecheck bundle_install cicoverage citypecheck citest citypecoverage clean clean-coverage clean-typecheck clean-typecoverage coverage default feature gem_dependencies help localtest overcommit quality repl report-coverage rubocop rubocop-ratchet spec test typecheck typecoverage update_from_cookiecutter
.DEFAULT_GOAL := default

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

default: clean-typecoverage typecheck typecoverage clean-coverage test coverage quality rubocop-ratchet ## run default typechecking, tests and quality

SOURCE_FILES = $(shell find lib -name '*.rb' -type f)


rbi/{{cookiecutter.project_slug}}.rbi: yardoc.installed ## Generate YARD documentation ## Generate RBS files
	rm -f rbi/{{cookiecutter.project_slug}}.rbi
	bundle exec sord --replace-errors-with-untyped --exclude-messages OMIT --no-regenerate rbi/{{cookiecutter.project_slug}}.rbi

types.installed: tapioca.installed Gemfile.lock Gemfile.lock.installed rbi/{{cookiecutter.project_slug}}.rbi sorbet/tapioca/require.rb sorbet/config ## Install Ruby dependencies
	bundle exec yard gems 2>&1 || bundle exec yard gems --safe 2>&1 || bundle exec yard gems 2>&1
	# bundle exec solargraph scan 2>&1
	touch types.installed

sorbet/machine_specific_config:
	echo "--cache-dir=$$HOME/.sorbet-cache" > sorbet/machine_specific_config

build-typecheck: Gemfile.lock.installed types.installed  ## Fetch information that type checking depends on

sorbet/tapioca/require.rb: sorbet/machine_specific_config
	bin/tapioca init

tapioca.installed: sorbet/machine_specific_config rbi/{{cookiecutter.project_slug}}.rbi sorbet/tapioca/require.rb Gemfile.lock.installed ## Install Tapioca-generated type information
	bin/tapioca gems
	bin/tapioca annotations
#	bin/tapioca dsl
	bin/tapioca todo
	bin/spoom srb bump
	touch tapioca.installed

yardoc.installed: $(wildcard config/annotations_*.rb) $(SOURCE_FILES) ## Generate YARD documentation
	bin/yard doc \{config,lib,app,script\}/**/*.rb ext/**/*.\{c,rb}
	touch yardoc.installed

clean-typecheck: ## Refresh the easily-regenerated information that type checking depends on
	bin/solargraph clear || true
	rm -fr .yardoc/ rbi/{{cookiecutter.project_slug}}.rbi types.installed yardoc.installed
{% if cookiecutter.use_checkoff %}	rm -fr ../checkoff/.yardoc || true
{% endif %}	echo all clear

realclean-typecheck: clean-typecheck ## Remove all type checking artifacts
	rm -fr ~/.cache/solargraph
	rm tapioca.installed

realclean: clean realclean-typecheck
	rm -fr vendor .bundle
	rm .make/*
	rm *.installed

typecheck: build-typecheck ## validate types in code and configuration
	bin/srb tc
	bin/solargraph typecheck --level strong

citypecheck: typecheck ## Run type check from CircleCI

typecoverage: typecheck ## Run type checking and then ratchet coverage in metrics/

clean-typecoverage: ## Clean out type-related coverage previous results to avoid flaky results

citypecoverage: typecoverage ## Run type checking, ratchet coverage, and then complain if ratchet needs to be committed

requirements_dev.txt.installed: requirements_dev.txt
	pip install -q --disable-pip-version-check -r requirements_dev.txt
	touch requirements_dev.txt.installed

pip_install: requirements_dev.txt.installed ## Install Python dependencies

Gemfile.lock: Gemfile
	make .bundle/config
	bundle lock

gem_dependencies: .bundle/config

# Ensure any Gemfile.lock changes, even pulled form git, ensure a
# bundle is installed.
Gemfile.lock.installed: Gemfile vendor/.keep
	touch Gemfile.lock.installed

vendor/.keep: Gemfile.lock
	make gem_dependencies
	bundle install
	touch vendor/.keep

.bundle/config:
	touch .bundle/config

bundle_install: Gemfile.lock.installed ## Install Ruby dependencies

clear_metrics: ## remove or reset result artifacts created by tests and quality tools
	bundle exec rake clear_metrics || true

clean: clear_metrics clean-typecoverage clean-typecheck clean-coverage  ## remove all built artifacts

test: spec ## run tests quickly

citest: test ## Run unit tests from CircleCI

overcommit: ## run precommit quality checks
	bundle exec overcommit --run

quality: overcommit ## run precommit quality checks

rubocop: ## Run rubocop
	@bundle exec rubocop

rubocop-ratchet: rubocop ## Run rubocop and then ratchet numbers of errors in todo file
	@bundle exec rubocop --regenerate-todo --no-exclude-limit --auto-gen-only-exclude --no-auto-gen-timestamp
	@if [ -f .rubocop_todo.yml ]; \
	  then \
	    git diff --exit-code .rubocop.yml; \
	    git diff --exit-code .rubocop_todo.yml; \
	fi

test: spec ## run tests quickly

spec: ## Run lower-level tests
	@bundle exec rake spec

feature: ## Run higher-level tests
	@bundle exec rake feature

localtest: clear_metrics spec undercover overcommit_branch ## run default local actions

repl: bundle_install
	@bundle exec rake repl

clean-coverage: clear_metrics

coverage: test report-coverage ## check code coverage
	@bundle exec rake undercover

report-coverage: test ## Report summary of coverage to stdout, and generate HTML, XML coverage report

update_apt: .make/apt_updated

.make/apt_updated:
	sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
	touch .make/apt_updated

cicoverage: coverage ## check code coverage

update_from_cookiecutter: ## Bring in changes from template project used to create this repo
	bundle exec overcommit --uninstall
	# cookiecutter_project_upgrader does its work in
	# .git/cookiecutter/{{cookiecutter.project_slug}}, but RuboCop wants to inherit
	# config from all directories above it - avoid config
	# mismatches by moving this out of the way
	mv .rubocop.yml .rubocop-renamed.yml || true
	cookiecutter_project_upgrader --help >/dev/null
	IN_COOKIECUTTER_PROJECT_UPGRADER=1 cookiecutter_project_upgrader || true
	mv .rubocop-renamed.yml .rubocop.yml
	git checkout cookiecutter-template && git push --no-verify
	git checkout main; overcommit --sign && overcommit --sign pre-commit && git checkout main && git pull && git checkout -b update-from-cookiecutter-$$(date +%Y-%m-%d-%H%M)
	git merge cookiecutter-template || true
	git checkout --ours Gemfile.lock || true
	# update frequently security-flagged gems while we're here
	bundle update --conservative json rexml yard || true
	make build-typecheck
	bundle install || true
	git add Gemfile.lock || true
	bundle exec overcommit --install || true
	@echo
	@echo "Please resolve any merge conflicts below and push up a PR with:"
	@echo
	@echo '   gh pr create --title "Update from cookiecutter" --body "Automated PR to update from cookiecutter boilerplate"'
	@echo
	@echo
