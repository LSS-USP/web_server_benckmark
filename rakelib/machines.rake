require_relative 'common_tasks'

include Common

desc 'Login into the machine'
task :login do
  row = get_configuration_from('row')
  puts row
  err = "Please, inform a machine name:\n\t#{row.keys.join("\n\t")}"
  verify_argv(err)
  port = row[ARGV[1]][0]['port']
  system("ssh #{ENV['USER']}@localhost -p #{port}")
  exit 0
end
