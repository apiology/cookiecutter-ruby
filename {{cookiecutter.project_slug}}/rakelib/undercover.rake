# frozen_string_literal: true

desc 'Ensure PR changes are fully covered by tests'
task :undercover do |_t|
  ret =
    system("if git branch -r | grep origin/main; then bundle exec undercover --compare origin/main --exclude-files " \
           "'test/unit/**/*,test/unit/*,rakelib/*';" \
           "fi")
  raise unless ret
end
