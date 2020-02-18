require 'confidante'
require 'rake_terraform'
require 'aws-sdk'
require 'securerandom'
require 'mime/types'

require_relative 'lib/terraform_output'
require_relative 'lib/s3_website'

configuration = Confidante.configuration

configuration.non_standard_mime_types.each do |mime_type, extensions|
  MIME::Types.add(MIME::Type.new(mime_type.to_s) { |m|
    m.extensions = extensions
  })
end

RakeTerraform.define_installation_tasks(
    path: File.join(Dir.pwd, 'vendor', 'terraform'),
    version: '0.12.17')

task :default => [
    :'content:build',
    :'bootstrap:plan',
    :'dns_zones:plan',
    :'website:beta:plan'
]

namespace :bootstrap do
  RakeTerraform.define_command_tasks(
      configuration_name: 'bootstrap'
  ) do |t|
    deployment_configuration = configuration.for_scope(role: 'bootstrap')

    t.source_directory = 'infra/bootstrap'
    t.work_directory = 'build'

    t.state_file = File.join(Dir.pwd, "state/bootstrap/default.tfstate")
    t.vars = deployment_configuration.vars
  end
end

namespace :dns_zones do
  RakeTerraform.define_command_tasks(
      configuration_name: 'dns-zones'
  ) do |t|
    deployment_configuration = configuration.for_scope(role: 'dns-zones')

    t.source_directory = 'infra/dns-zones'
    t.work_directory = 'build'

    t.backend_config = deployment_configuration.backend_config
    t.vars = deployment_configuration.vars
  end
end

namespace :website do
  RakeTerraform.define_command_tasks(
      configuration_name: 'website',
      argument_names: [:deployment_identifier]
  ) do |t, args|
    runtime_configuration = configuration.for_overrides(args)
    deployment_identifier = runtime_configuration.deployment_identifier
    deployment_configuration = runtime_configuration
        .for_scope(
            role: 'website',
            deployment: deployment_identifier)

    t.source_directory = 'infra/website'
    t.work_directory = 'build'

    t.backend_config = deployment_configuration.backend_config
    t.vars = deployment_configuration.vars
  end

  [:beta, :live].each do |environment|
    namespace environment do
      [:plan, :provision, :destroy].each do |action|
        task action do
          Rake::Task["website:#{action}"].invoke(environment)
        end
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
    runtime_configuration = configuration.for_overrides(args)
    deployment_identifier = runtime_configuration.deployment_identifier
    deployment_configuration = runtime_configuration
        .for_scope(
            role: 'website',
            deployment: deployment_identifier)

    region = deployment_configuration.region
    max_ages = deployment_configuration.max_ages
    content_work_directory = deployment_configuration.content_work_directory
    bucket = deployment_configuration.website_bucket_name

    s3sync = S3Website.new(
        region: region,
        bucket: bucket,
        max_ages: max_ages)

    s3sync.publish_from(content_work_directory)
  end

  task :invalidate, [:deployment_identifier] do |_, args|
    runtime_configuration = configuration.for_overrides(args)
    deployment_identifier = runtime_configuration.deployment_identifier
    deployment_configuration = runtime_configuration
        .for_scope(
            role: 'website',
            deployment: deployment_identifier)

    region = deployment_configuration.region
    backend_config = deployment_configuration.backend_config

    distribution_id = TerraformOutput.for(
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
