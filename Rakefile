require 'confidante'
require 'rake_terraform'

configuration = Confidante.configuration

RakeTerraform.define_installation_tasks(
    path: File.join(Dir.pwd, 'vendor', 'terraform'),
    version: '0.10.6')

task :default => [
    :'content:build',
    :'bootstrap:plan',
    :'dns_zones:plan',
    :'website:beta:plan'
]

namespace :bootstrap do
  RakeTerraform.define_command_tasks do |t|
    t.configuration_name = 'bootstrap'
    t.source_directory = 'infra/bootstrap'
    t.work_directory = 'build'

    t.state_file = lambda do
      File.join(Dir.pwd, "state/bootstrap/default.tfstate")
    end

    t.vars = lambda do
      configuration
          .for_scope(role: 'bootstrap')
          .vars
    end
  end
end

namespace :dns_zones do
  RakeTerraform.define_command_tasks do |t|
    t.configuration_name = 'dns-zones'
    t.source_directory = 'infra/dns-zones'
    t.work_directory = 'build'

    t.backend_config = lambda do
      configuration
          .for_scope(role: 'dns-zones')
          .backend_config
    end

    t.vars = lambda do
      configuration
          .for_scope(role: 'dns-zones')
          .vars
    end
  end
end

namespace :website do
  RakeTerraform.define_command_tasks do |t|
    t.argument_names = [:deployment_identifier]

    t.configuration_name = 'website'
    t.source_directory = 'infra/website'
    t.work_directory = 'build'

    t.backend_config = lambda do |args|
      deployment_identifier =
          configuration
              .for_overrides(args)
              .deployment_identifier

      configuration
          .for_overrides(args)
          .for_scope(
              role: 'website',
              deployment: deployment_identifier)
          .backend_config
    end

    t.vars = lambda do |args|
      deployment_identifier =
          configuration
              .for_overrides(args)
              .deployment_identifier

      configuration
          .for_overrides(args)
          .for_scope(
              role: 'website',
              deployment: deployment_identifier)
          .vars
    end
  end

  namespace :beta do
    task :plan do
      Rake::Task['website:plan'].invoke('beta')
    end
    task :provision do
      Rake::Task['website:provision'].invoke('beta')
    end
    task :destroy do
      Rake::Task['website:destroy'].invoke('beta')
    end
  end

  namespace :live do
    task :plan do
      Rake::Task['website:plan'].invoke('live')
    end
    task :provision do
      Rake::Task['website:provision'].invoke('live')
    end
    task :destroy do
      Rake::Task['website:destroy'].invoke('live')
    end
  end
end

namespace :content do
  desc 'Local dev build of website to _site'
  task :build do
    sh 'jekyll build -s src'
  end

  desc 'Local dev build and serve on localhost:4000'
  task :serve do
    sh 'jekyll serve -s src'
  end
end