#!/usr/bin/env python

import os
import subprocess

PROJECT_DIRECTORY = os.path.realpath(os.path.curdir)

# Parent git push / Overcommit Bundler env must not leak into baked projects.
PARENT_HOOK_ENV_VARS = (
    'GIT_DIR',
    'GIT_WORK_TREE',
    'GIT_INDEX_FILE',
    'BUNDLE_GEMFILE',
    'BUNDLE_PATH',
    'BUNDLE_BIN',
    'BUNDLE_WITHOUT',
    'BUNDLE_DEPLOYMENT',
    'BUNDLE_APP_CONFIG',
    'RUBYOPT',
)


def run(*args, **kwargs):
    if len(kwargs) > 0:
        print('running with kwargs', kwargs, ':', *args, flush=True)
    else:
        print('running', *args, flush=True)
    # keep both streams in the same place so that we can weave
    # together what happened on report instead of having them
    # dumped separately
    subprocess.check_call(*args, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, **kwargs)


def _parent_hook_env_var(var):
    return any((
        var in PARENT_HOOK_ENV_VARS,
        var.startswith('BUNDLER_ORIG_'),
        var.startswith('BUNDLE_'),
        var.startswith('BUNDLER_'),
        var in ('GEM_HOME', 'GEM_PATH'),
    ))


def project_subprocess_env():
    env = os.environ.copy()
    for var in list(env):
        if _parent_hook_env_var(var):
            env.pop(var, None)
    if 'PATH' in env:
        env['PATH'] = os.pathsep.join(
            part for part in env['PATH'].split(os.pathsep)
            if part and '/bundle/ruby/' not in part
        )
    return env


def isolate_hook_env():
    for var in PARENT_HOOK_ENV_VARS:
        os.environ.pop(var, None)


def run_in_project(*args, **kwargs):
    """Run a subprocess in the baked project without parent hook env."""
    env = project_subprocess_env()
    env.update(kwargs.pop('env', {}))
    kwargs['env'] = env
    run(*args, **kwargs)


def git_run(*args, **kwargs):
    """Run git in the baked project, not the invoking repo (e.g. pre-push)."""
    isolate_hook_env()
    run(['git', *args], **kwargs)


def remove_file(filepath):
    os.remove(os.path.join(PROJECT_DIRECTORY, filepath))


if __name__ == '__main__':
    # Add bin directory at start of PATH
    os.environ['PATH'] = os.path.join(PROJECT_DIRECTORY, 'bin') + os.pathsep + os.environ['PATH']

    if 'Not open source' == '{{ cookiecutter.open_source_license }}':
        remove_file('LICENSE')
        remove_file('CONTRIBUTING.rst')

    if os.environ.get('IN_COOKIECUTTER_PROJECT_UPGRADER', '0') == '1':
        os.environ['SKIP_GIT_CREATION'] = '1'
        os.environ['SKIP_EXTERNAL'] = '1'

    if os.environ.get('SKIP_GIT_CREATION', '0') != '1':
        # Don't run these non-idempotent things when in
        # cookiecutter_project_upgrader, which will run this hook
        # multiple times over its lifetime.
        git_run('init')
        git_run('add', '-A')
        git_run('commit', '--allow-empty',
                '--no-verify',
                '-m', 'Initial commit from boilerplate')
    if 'Yes' != '{{ cookiecutter.use_checkoff }}':
        run_in_project(['rm', 'config/annotations_asana.rb'])
    #
    # (any file addition/modification from the outside world goes here)
    #
    run_in_project('./fix.sh')
    run_in_project(['bin/rubocop', '-A', '--disable-uncorrectable'])
    #
    # (commit here if you brought in any files above)
    #
    run_in_project(['make', 'build-typecheck'])  # update from bundle updates
    git_run('add', '-A')
    run_in_project(['bundle', 'exec', 'git', 'commit', '--allow-empty', '-m',
                    'reformat'])

    if os.environ.get('SKIP_EXTERNAL', '0') != '1':
        if 'none' != '{{ cookiecutter.type_of_github_repo }}':
            if 'private' == '{{ cookiecutter.type_of_github_repo }}':
                visibility_flag = '--private'
            elif 'public' == '{{ cookiecutter.type_of_github_repo }}':
                visibility_flag = '--public'
            else:
                raise RuntimeError('Invalid argument to '
                                   'cookiecutter.type_of_github_repo: '
                                   '{{ cookiecutter.type_of_github_repo }}')
            description = "{{ cookiecutter.project_short_description.replace('\"', '\\\"') }}"
            # if repo doesn't already exist
            if subprocess.call(['gh', 'repo', 'view',
                                '{{ cookiecutter.github_username }}/'
                                '{{ cookiecutter.project_slug }}']) != 0:
                run(['gh', 'repo', 'create',
                     visibility_flag,
                     '--description',
                     description,
                     '--source',
                     '.',
                     '{{ cookiecutter.github_username }}/'
                     '{{ cookiecutter.project_slug }}'])
                run(['gh', 'repo', 'edit',
                     '--allow-update-branch',
                     '--enable-auto-merge',
                     '--delete-branch-on-merge'])
            git_run('push')
            run(['circleci', 'follow'])
            git_run('branch', '--set-upstream-to=origin/main', 'main')
