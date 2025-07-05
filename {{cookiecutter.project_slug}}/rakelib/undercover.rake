# frozen_string_literal: true

desc 'Ensure PR changes are fully covered by tests'
task :undercover do |_t|
  ret =
    system("if git branch -r | grep origin/main; then undercover --compare origin/main --exclude-files " \
           "lib/checkoff/version.rb," \
           "'test/**/*,test/*,rakelib/*';" \
           "fi")
  raise unless ret
end
