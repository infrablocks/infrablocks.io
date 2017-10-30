require 'confidante'
require 'rake_terraform'
require 'aws-sdk'
require 'securerandom'
require 'mime/types'

require_relative 'lib/terraform_output'
require_relative 'lib/s3_website'

configuration = Confidante.configuration

configuration.non_standard_mime_types.each do |mime_type, extensions|
  MIME::Types.add(MIME::Type.new(mime_type) {|m|
    m.extensions = extensions
  })
end

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

  [:beta, :live].each do |environment|
    [:plan, :provision, :destroy].each do |action|
      task action do
        Rake::Task["website:#{action}"].invoke(environment)
      end
    end
  end
end

namespace :content do
  desc 'Fetch dependencies'
  task :deps do
    sh 'npm install'
  end

  desc 'Build website locally'
  task :build => [:deps] do
    sh "jekyll build -s src -d #{configuration.content_work_directory}"
  end

  desc 'Build and serve website on localhost:4000'
  task :serve => [:deps] do
    sh "jekyll serve -s src -d #{configuration.content_work_directory}"
  end

  desc 'Publish content for deployment identifier'
  task :publish, [:deployment_identifier] => [:build] do |_, args|
    configuration = configuration.for_overrides(args)

    region = configuration.region
    deployment_identifier = configuration.deployment_identifier
    max_ages = configuration.max_ages
    content_work_directory = configuration.content_work_directory
    bucket = configuration
                 .for_scope(
                     role: 'website',
                     deployment: deployment_identifier)
                 .website_bucket_name

    s3sync = S3Website.new(
        region: region,
        bucket: bucket,
        max_ages: max_ages)

    s3sync.publish_from(content_work_directory)
  end

  task :invalidate, [:deployment_identifier] do |_, args|
    configuration = configuration.for_overrides(args)

    region = configuration.region
    deployment_identifier = configuration.deployment_identifier
    backend_config = configuration
                         .for_scope(
                             role: 'website',
                             deployment: deployment_identifier)
                         .backend_config

    distribution_id =
        TerraformOutput.for(
            name: 'cdn_id',
            source_directory: 'infra/website',
            work_directory: 'build',
            backend_config: backend_config)

    cloudfront = Aws::CloudFront::Client.new(region: region)

    cloudfront.create_invalidation(
        distribution_id: distribution_id,
        invalidation_batch: {
            caller_reference: SecureRandom.uuid,
            paths: {
                quantity: 1,
                items: ['/*'],
            }
        })
  end
end
