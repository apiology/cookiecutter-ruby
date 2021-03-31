# frozen_string_literal: true

desc 'Rebaseline quality thresholds to last commit'
task :clear_metrics do |_t|
  ret =
    system('git checkout coverage/.last_run.json')
  raise unless ret
end
