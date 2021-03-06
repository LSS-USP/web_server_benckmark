require 'yaml'
require_relative 'common_tasks'
require 'fileutils'

namespace :benchmark do

  include Common

  desc 'Start bench'
  task :run do
    new_path = prepare_results_folder
    last_execution = File.new('.last_execution', 'w')
    last_execution.puts("ENV['LAST_EXECUTION'] = '#{new_path}'")
    last_execution.close

    experiment_path = experiment_folder(new_path, 'small_static_file')
    current_uri = 'http://172.17.0.105/small_files/'
    rate = 10000
    execute_benchmark(experiment_path, current_uri, rate, 'SMALL static file')

    experiment_path = experiment_folder(new_path, 'big_static_file')
    current_uri = 'http://172.17.0.105/big_files/'
    rate = 10000
    execute_benchmark(experiment_path, current_uri, rate, 'BIG static file')

    # Dynamic files
    experiment_path = experiment_folder(new_path, 'small_dynamic_file')
    current_uri = 'http://172.17.0.105/small_dynamic/'
    rate = 10000
    execute_benchmark(experiment_path, current_uri, rate, 'SMALL_dynamic file')

    experiment_path = experiment_folder(new_path, 'big_dynamic_file')
    current_uri = 'http://172.17.0.105/big_dynamic/'
    rate = 10000
    execute_benchmark(experiment_path, current_uri, rate, 'BIG_dynamic file')

    exit 0
  end

  def execute_benchmark(experiment_path, current_uri, rate, label)
    %w(event worker prefork).each do |mpm_module|
      mpm_strategy = "ansible-playbook -i #{$BENCH_ENV} enable_mpm.yml "\
                      "--extra-vars 'mpm_name=#{mpm_module}'"
      system(mpm_strategy)

      flextrace = "ansible-playbook -i #{$BENCH_ENV} monitor.yml "\
                  "--extra-vars 'monitor=Start'"
      system(flextrace)

      execute = "ansible-playbook -i #{$BENCH_ENV} execute_benchmark.yml "\
                "--extra-vars 'target_uri=#{current_uri} label=#{label} rate=#{rate}'"
      system(execute)

      flextrace = "ansible-playbook -i #{$BENCH_ENV} monitor.yml "\
                  "--extra-vars 'monitor=Stop'"
      system(flextrace)

      mpm_data_folder = File.join(experiment_path, mpm_module)
      FileUtils::mkdir_p mpm_data_folder
      FileUtils.copy_entry '/tmp/results/', mpm_data_folder
      Dir.glob('/tmp/stress*.gz') {|f| FileUtils.cp File.expand_path(f), mpm_data_folder}
      Dir.glob('/tmp/stress*.gz') {|f| FileUtils.rm_rf File.expand_path(f)}
      FileUtils.rm_rf '/tmp/results'
    end
  end

  def prepare_results_folder(result_directory='results')
    Dir.mkdir(result_directory) unless File.directory?(result_directory)

    FileUtils.rm_rf '/tmp/results'
    last_collected = Time.now.strftime("%d-%m-%Y_%H-%M_data")
    FileUtils::mkdir_p File.join(result_directory, last_collected)
    return File.join(result_directory, last_collected)
  end

  def experiment_folder(base_path, experiment_name)
    Dir.mkdir(base_path) unless File.directory?(base_path)

    FileUtils::mkdir_p File.join(base_path, experiment_name)
    return File.join(base_path, experiment_name)
  end

end
