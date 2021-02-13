#!/usr/bin/env python

import os
import subprocess

PROJECT_DIRECTORY = os.path.realpath(os.path.curdir)


def remove_file(filepath):
    os.remove(os.path.join(PROJECT_DIRECTORY, filepath))


if __name__ == '__main__':
    if 'Not open source' == '{{ cookiecutter.open_source_license }}':
        remove_file('LICENSE')

    subprocess.check_call('./fix.sh')
    subprocess.check_call(['git', 'init'])
    subprocess.check_call(['git', 'add', '-A'])
    subprocess.check_call(['git', 'commit', '-m',
                           'Initial commit from boilerplate'])
    if 'none' != '{{ cookiecutter.type_of_github_repo }}':
        if 'private' == '{{ cookiecutter.type_of_github_repo }}':
            visibility_flag = '--private'
        elif 'public' == '{{ cookiecutter.type_of_github_repo }}':
            visibility_flag = '--public'
        else:
            raise RuntimeError('Invalid argument to '
                               'cookiecutter.type_of_github_repo: '
                               '{{ cookiecutter.type_of_github_repo }}')
        subprocess.check_call(['gh', 'repo', 'create',
                               visibility_flag,
                               '-y',
                               '--description',
                               '{{ cookiecutter.project_short_description }}',
                               '{{ cookiecutter.github_username }}/'
                               '{{ cookiecutter.project_slug }}'])
