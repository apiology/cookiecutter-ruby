"""Tests for cookiecutter bake and build quality."""

from contextlib import contextmanager
import datetime
import os
import shlex
import subprocess
import sys

from cookiecutter.utils import rmtree
import jinja2


@contextmanager
def inside_dir(dirpath):
    """Execute code from inside the given directory.

    :param dirpath: Path of the directory the command is being run in.
    """
    old_path = os.getcwd()
    try:
        os.chdir(dirpath)
        yield
    finally:
        os.chdir(old_path)


@contextmanager
def suppressed_github_and_circleci_creation():
    """Suppress GitHub and CircleCI creation during hooks.

    Set SKIP_EXTERNAL so hooks do not create repos or push to CircleCI.
    """
    os.environ['SKIP_EXTERNAL'] = '1'
    try:
        yield
    finally:
        del os.environ['SKIP_EXTERNAL']


def errmsg(exception):
    """Format a cookiecutter or Jinja exception for assertion messages."""
    if isinstance(exception, jinja2.exceptions.TemplateSyntaxError):
        return f'Found error at {exception.filename}:{exception.lineno}'
    return str(exception)


@contextmanager
def bake_in_temp_dir(cookies, *args, **kwargs):
    """Bake a cookiecutter in a temporary directory.

    :param cookies: pytest_cookies.Cookies instance.
    :param args: Positional arguments passed to cookies.bake.
    :param kwargs: Keyword arguments passed to cookies.bake.
    """
    with suppressed_github_and_circleci_creation():
        result = cookies.bake(*args, **kwargs)
        assert result is not None, result
        assert result.exception is None, errmsg(result.exception)
        assert result.exit_code == 0
        assert hasattr(result, 'project_path'), result
    try:
        yield result
    finally:
        if '--keep-baked-projects' not in sys.argv:
            rmtree(str(result.project_path))


def run_inside_dir(command, dirpath):
    """Run a command inside a directory and return the exit status.

    :param command: Command to execute.
    :param dirpath: Working directory for the command.
    """
    with inside_dir(dirpath):
        return subprocess.check_call(shlex.split(command))


def check_output_inside_dir(command, dirpath):
    """Run a command inside a directory and return command output.

    :param command: Command to execute.
    :param dirpath: Working directory for the command.
    """
    with inside_dir(dirpath):
        return subprocess.check_output(shlex.split(command))


def project_info(result):
    """Return toplevel dir, project_slug, and project dir from baked cookies."""
    project_path = str(result.project_path)
    project_slug = os.path.split(project_path)[-1]
    project_dir = os.path.join(project_path, project_slug)
    return project_path, project_slug, project_dir


def test_bake_and_run_build(cookies):
    """Bake the template and run make test, typecheck, and quality."""
    with bake_in_temp_dir(cookies,
                          extra_context={
                              'full_name': 'name "quote" O\'connor',
                              'project_short_description':
                              'The greatest project ever created by name "quote" O\'connor.',
                          }) as result:
        assert result.project_path.is_dir()
        assert result.exit_code == 0
        assert result.exception is None

        found_toplevel_files = [f.name for f in result.project_path.iterdir()]
        assert 'README.md' in found_toplevel_files
        assert 'LICENSE' in found_toplevel_files
        assert 'fix.sh' in found_toplevel_files

        assert run_inside_dir('make test', str(result.project_path)) == 0
        assert run_inside_dir('make typecheck', str(result.project_path)) == 0
        assert run_inside_dir('make quality', str(result.project_path)) == 0
        # The supplied Makefile does not support win32
        if sys.platform != 'win32':
            output = check_output_inside_dir(
                'make help',
                str(result.project_path)
            )
            assert b'run precommit quality checks' in \
                output
        license_file_path = result.project_path / 'LICENSE'
        now = datetime.datetime.now()
        assert str(now.year) in license_file_path.open().read()
        print('test_bake_and_run_build path', str(result.project_path))
