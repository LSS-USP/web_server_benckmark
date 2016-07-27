require 'yaml'
require_relative 'common_tasks'

namespace :benchmark do

  include Common

  desc 'Start bench'
  task :run do
    vm_define = "config/#{$BENCH_ENV}/basic/machine_define.yml"
    hw_httpd, hw_request, machines_names = get_configuration_from
    port = hw_request['port']
    host = hw_request['host']
    command = "ssh #{ENV['USER']}@#{host} -p #{port} "
    command += "'bash -s' < scripts/stress_test.sh event http://192.168.33.49:8080/"

    system(command)

    last_collected = Time.now.strftime("%d-%m-%Y_%H-%M")
    last_collected = "results/#{last_collected}_data"
    system("mkdir #{last_collected}")

    command = "scp -rp -P #{port} #{ENV['USER']}@#{host}:"
    command += "/home/siqueira/results/* #{last_collected}"

    system(command)

    exit 0
  end

end
