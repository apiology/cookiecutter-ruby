# frozen_string_literal: true

UNDERCOVER_EXCLUDE_FILES =
  "lib/{{ cookiecutter.project_slug }}/version.rb,'test/**/*,test/*,rakelib/*,script/*'"

def origin_main_ref?
  system(
    'git', 'rev-parse', '--verify', '--quiet', 'refs/remotes/origin/main',
    out: File::NULL, err: File::NULL
  )
end

desc 'Ensure PR changes are fully covered by tests'
task :undercover do
  unless origin_main_ref?
    message = 'origin/main is not available; cannot run undercover'
    abort "ERROR: #{message}" if ENV['CIRCLECI']

    warn "Skipping undercover: #{message}"
    next
  end

  sh 'undercover', '--compare', 'origin/main',
     '--exclude-files', UNDERCOVER_EXCLUDE_FILES
end
