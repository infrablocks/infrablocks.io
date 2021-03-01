require 'confidante'
require 'rake_terraform'
require 'ruby_terraform/output'
require 'aws-sdk'
require 'securerandom'
require 'mime/types'

require_relative 'lib/s3_website'

configuration = Confidante.configuration

configuration.non_standard_mime_types.each do |mime_type, extensions|
  MIME::Types.add(MIME::Type.new(mime_type.to_s) { |m|
    m.extensions = extensions
  })
end

RakeTerraform.define_installation_tasks(
  path: File.join(Dir.pwd, 'vendor', 'terraform'),
  version: '0.14.5')

task :default => [
  :'content:build'
]

namespace :bootstrap do
  RakeTerraform.define_command_tasks(
    configuration_name: 'bootstrap',
    argument_names: [
      :deployment_group,
      :deployment_type,
      :deployment_label
    ]
  ) do |t, args|
    configuration = configuration
      .for_scope(args.to_h.merge(role: 'bootstrap'))

    vars = configuration.vars
    deployment_identifier = configuration.deployment_identifier

    t.source_directory = 'infra/bootstrap'
    t.work_directory = 'build'

    t.state_file = File.join(
      Dir.pwd, "state/bootstrap/#{deployment_identifier}.tfstate")
    t.vars = vars
  end
end

namespace :website do
  RakeTerraform.define_command_tasks(
    configuration_name: 'website',
    argument_names: [
      :deployment_group,
      :deployment_type,
      :deployment_label
    ]
  ) do |t, args|
    configuration = configuration
      .for_scope(args.to_h.merge(role: 'website'))

    t.source_directory = 'infra/website'
    t.work_directory = 'build'

    t.backend_config = configuration.backend_config
    t.vars = configuration.vars
  end
end

namespace :content do
  desc 'Fetch dependencies'
  task :deps do
    sh 'npm install'
  end

  desc 'Clean built content'
  task :clean do
    rm_rf 'build/content'
  end

  desc 'Build website locally'
  task :build, [
    :deployment_group,
    :deployment_type,
    :deployment_label
  ] => [:clean, :deps] do |_, args|
    args.with_defaults(
      deployment_group: "ifbk",
      deployment_type: "local",
      deployment_label: "default")

    configuration = configuration.for_scope(args.to_h)

    environment = configuration.environment
    content_work_directory = configuration.content_work_directory

    sh({
      "JEKYLL_ENV" => environment
    }, "jekyll", "build",
      "-s", "src",
      "-c", "src/_config.yaml,src/_config.#{environment}.yaml",
      "-d", content_work_directory)
  end

  desc 'Build and serve website on localhost:4000'
  task :serve, [
    :deployment_group,
    :deployment_type,
    :deployment_label
  ] => [:deps] do |_, args|
    args.with_defaults(
      deployment_group: "ifbk",
      deployment_type: "local",
      deployment_label: "default")

    configuration = configuration.for_scope(args.to_h)

    environment = configuration.environment
    content_work_directory = configuration.content_work_directory

    sh({
      "JEKYLL_ENV" => environment
    }, "jekyll", "serve",
      "-s", "src",
      "-c", "src/_config.yaml,src/_config.#{environment}.yaml",
      "-d", content_work_directory,
      "-l")
  end

  desc 'Publish content for deployment identifier'
  task :publish, [
    :deployment_group,
    :deployment_type,
    :deployment_label
  ] do |_, args|
    configuration = configuration
      .for_scope(args.to_h.merge(role: 'website'))

    region = configuration.region
    max_ages = configuration.max_ages
    content_work_directory = configuration.content_work_directory
    bucket = configuration.website_bucket_name

    s3sync = S3Website.new(
      region: region,
      bucket: bucket,
      max_ages: max_ages)

    s3sync.publish_from(content_work_directory)
  end

  task :invalidate, [
    :deployment_group,
    :deployment_type,
    :deployment_label
  ] do |_, args|
    configuration = configuration
      .for_scope(args.to_h.merge(role: 'website'))

    region = configuration.region
    backend_config = configuration.backend_config

    distribution_id = JSON.parse(
      RubyTerraform::Output.for(
        name: 'cdn_id',
        source_directory: 'infra/website',
        work_directory: 'build',
        backend_config: backend_config))

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

  task :deploy, [
    :deployment_group,
    :deployment_type,
    :deployment_label
  ] do |_, args|
    Rake::Task['content:build'].invoke(*args)
    Rake::Task['content:publish'].invoke(*args)
    Rake::Task['content:invalidate'].invoke(*args)
  end
end
