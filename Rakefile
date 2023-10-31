# frozen_string_literal: true

require 'aws-sdk'
require 'confidante'
require 'mime/types'
require 'rake_circle_ci'
require 'rake_git'
require 'rake_git_crypt'
require 'rake_gpg'
require 'rake_terraform'
require 'rubocop/rake_task'
require 'ruby_terraform/output'
require 'securerandom'

require_relative 'lib/s3_website'

configuration = Confidante.configuration

configuration.non_standard_mime_types.each do |mime_type, extensions|
  MIME::Types.add(MIME::Type.new(mime_type.to_s) do |m|
    m.extensions = extensions
  end)
end

RakeTerraform.define_installation_tasks(
  path: File.join(Dir.pwd, 'vendor', 'terraform'),
  version: '1.1.7'
)

task default: %i[
  build:code:fix
  content:build
]

RakeGitCrypt.define_standard_tasks(
  namespace: :git_crypt,

  provision_secrets_task_name: :'secrets:provision',
  destroy_secrets_task_name: :'secrets:destroy',

  install_commit_task_name: :'git:commit',
  uninstall_commit_task_name: :'git:commit',

  gpg_user_key_paths: %w[
    config/gpg
    config/secrets/ci/gpg.public
  ]
)

namespace :git do
  RakeGit.define_commit_task(
    argument_names: [:message]
  ) do |t, args|
    t.message = args.message
  end
end

namespace :encryption do
  namespace :directory do
    desc 'Ensure CI secrets directory exists.'
    task :ensure do
      FileUtils.mkdir_p('config/secrets/ci')
    end
  end

  namespace :passphrase do
    desc 'Generate encryption passphrase for CI GPG key'
    task generate: ['directory:ensure'] do
      File.write('config/secrets/ci/encryption.passphrase',
                 SecureRandom.base64(36))
    end
  end
end

namespace :keys do
  namespace :secrets do
    namespace :gpg do
      RakeGPG.define_generate_key_task(
        output_directory: 'config/secrets/ci',
        name_prefix: 'gpg',
        owner_name: 'InfraBlocks Maintainers',
        owner_email: 'maintainers@infrablocks.io',
        owner_comment: 'infrablocks.io CI Key'
      )
    end

    task generate: ['gpg:generate']
  end
end

namespace :secrets do
  namespace :directory do
    desc 'Ensure secrets directory exists and is set up correctly'
    task :ensure do
      FileUtils.mkdir_p('config/secrets')
      unless File.exist?('config/secrets/.unlocked')
        File.write('config/secrets/.unlocked', 'true')
      end
    end
  end

  desc 'Generate all generatable secrets.'
  task generate: %w[
    encryption:passphrase:generate
    keys:secrets:generate
  ]

  desc 'Provision all secrets.'
  task provision: [:generate]

  desc 'Delete all secrets.'
  task :destroy do
    rm_rf 'config/secrets'
  end

  desc 'Rotate all secrets.'
  task rotate: [:'git_crypt:reinstall']
end

RuboCop::RakeTask.new

namespace :build do
  namespace :code do
    desc 'Run all checks of the build code'
    task check: [:rubocop]

    desc 'Attempt to automatically fix issues with the build code'
    task fix: [:'rubocop:autocorrect']
  end
end

namespace :bootstrap do
  RakeTerraform.define_command_tasks(
    configuration_name: 'bootstrap',
    argument_names: %i[
      deployment_group
      deployment_type
      deployment_label
    ]
  ) do |t, args|
    configuration = configuration
                    .for_scope(args.to_h.merge(role: 'bootstrap'))

    vars = configuration.vars
    deployment_identifier = configuration.deployment_identifier

    t.source_directory = 'infra/bootstrap'
    t.work_directory = 'build'

    t.state_file = File.join(
      Dir.pwd, "state/bootstrap/#{deployment_identifier}.tfstate"
    )
    t.vars = vars
  end
end

namespace :prerequisites do
  desc 'Ensure all deployment prerequisites are available'
  task :ensure, [
    :deployment_group,
    :deployment_type,
    :deployment_label
  ] do |_, args|
    Rake::Task['terraform:ensure'].invoke(*args)
    Rake::Task['aws:session:ensure'].invoke(*args)
  end
end

namespace :website do
  RakeTerraform.define_command_tasks(
    configuration_name: 'website',
    argument_names: %i[
      deployment_group
      deployment_type
      deployment_label
    ],
    ensure_task_name: 'prerequisites:ensure'
  ) do |t, args|
    configuration = configuration
                    .for_scope(args.to_h.merge(role: 'website'))

    t.source_directory = 'infra/website'
    t.work_directory = 'build'

    t.backend_config = configuration.backend_config
    t.vars = configuration.vars
  end
end

# rubocop:disable Metrics/BlockLength
namespace :aws do
  namespace :session do
    desc 'Ensure aws session is available'
    task :ensure, [
      :deployment_group,
      :deployment_type,
      :deployment_label
    ] do |_, args|
      unless ENV['AWS_SESSION_TOKEN']
        configuration = configuration.for_scope(args.to_h)
        provisioning_role_arn = configuration.provisioning_role_arn
        region = configuration.region

        aws_access_key_id = configuration.aws_access_key_id
        aws_secret_access_key = configuration.aws_secret_access_key

        client = Aws::STS::Client.new(
          region:,
          access_key_id: aws_access_key_id,
          secret_access_key: aws_secret_access_key
        )
        response = client.assume_role(
          role_arn: provisioning_role_arn,
          role_session_name: 'CI'
        )

        credentials = response.credentials

        ENV['AWS_ACCESS_KEY_ID'] = credentials.access_key_id
        ENV['AWS_SECRET_ACCESS_KEY'] = credentials.secret_access_key
        ENV['AWS_SESSION_TOKEN'] = credentials.session_token
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength

namespace :dependencies do
  desc 'Fetch dependencies'
  task :install do
    sh('npm', 'install')
  end
end

# rubocop:disable Metrics/BlockLength
namespace :content do
  desc 'Clean built content'
  task :clean do
    rm_rf 'src/dist'
    rm_rf 'src/_data/manifest.yml'
    rm_rf 'build/content'
  end

  namespace :webpack do
    desc 'Build webpack content for deployment identifier, by default ' \
         'ifbk-local-default'
    task :build, %i[
      deployment_group
      deployment_type
      deployment_label
    ] => [:'dependencies:install'] do |_, args|
      default_deployment_identifier(args)

      configuration = configuration.for_scope(args.to_h)

      environment = configuration.environment
      content_work_directory = configuration.content_work_directory

      sh({
           'NODE_ENV' => environment
         }, 'npx', 'webpack',
         '--config', "config/webpack/webpack.#{environment}.js",
         '--env', environment,
         '--env', "CONTENT_WORK_DIRECTORY=#{content_work_directory}",
         '--progress',
         '--color')
    end

    desc 'Run webpack on change for deployment identifier, by default ' \
         'ifbk-local-default'
    task :serve, %i[
      deployment_group
      deployment_type
      deployment_label
    ] => [:'dependencies:install'] do |_, args|
      default_deployment_identifier(args)

      configuration = configuration.for_scope(args.to_h)

      environment = configuration.environment
      content_work_directory = configuration.content_work_directory

      sh({
           'NODE_ENV' => environment
         }, 'npx', 'webpack',
         '--config', "config/webpack/webpack.#{environment}.js",
         '--env', environment,
         '--env', "CONTENT_WORK_DIRECTORY=#{content_work_directory}",
         '--progress',
         '--color',
         '--watch')
    end
  end

  namespace :jekyll do
    desc 'Build jekyll content for deployment identifier, by default ' \
         'ifbk-local-default'
    task :build, %i[
      deployment_group
      deployment_type
      deployment_label
    ] => [:'dependencies:install'] do |_, args|
      default_deployment_identifier(args)

      configuration = configuration.for_scope(args.to_h)

      environment = configuration.environment
      deployment_identifier = configuration.deployment_identifier
      content_work_directory = configuration.content_work_directory

      sh({
           'JEKYLL_ENV' => environment
         }, 'jekyll', 'build',
         '-s', 'src',
         '-c', 'config/jekyll/defaults.yaml,' \
               "config/jekyll/#{deployment_identifier}.yaml",
         '-d', content_work_directory)
    end

    desc 'Serve jekyll website on localhost:4000 for deployment identifier, ' \
         'by default ifbk-local-default'
    task :serve, %i[
      deployment_group
      deployment_type
      deployment_label
    ] => [:'dependencies:install'] do |_, args|
      default_deployment_identifier(args)

      configuration = configuration.for_scope(args.to_h)

      environment = configuration.environment
      deployment_identifier = configuration.deployment_identifier
      content_work_directory = configuration.content_work_directory

      sh({
           'JEKYLL_ENV' => environment
         }, 'jekyll', 'serve',
         '-s', 'src',
         '-c', 'config/jekyll/defaults.yaml,' \
               "config/jekyll/#{deployment_identifier}.yaml",
         '-d', content_work_directory,
         '-l')
    end
  end

  desc 'Build content for deployment identifier, by default ' \
       'ifbk-local-default'
  task :build, %i[
    deployment_group
    deployment_type
    deployment_label
  ] => [:clean] do |_, args|
    default_deployment_identifier(args)

    Rake::Task[:'content:webpack:build'].invoke(*args)
    Rake::Task[:'content:jekyll:build'].invoke(*args)
  end

  desc 'Publish content for deployment identifier'
  task :publish, %i[
    deployment_group
    deployment_type
    deployment_label
  ] => ['aws:session:ensure'] do |_, args|
    configuration = configuration
                    .for_scope(args.to_h.merge(role: 'website'))

    region = configuration.region
    max_ages = configuration.max_ages
    content_work_directory = configuration.content_work_directory
    bucket = configuration.website_bucket_name

    s3sync = S3Website.new(
      region:,
      bucket:,
      max_ages:
    )

    s3sync.publish_from(content_work_directory)
  end

  desc 'Invalidate content caches for deployment identifier'
  task :invalidate, %i[
    deployment_group
    deployment_type
    deployment_label
  ] => ['aws:session:ensure'] do |_, args|
    configuration = configuration
                    .for_scope(args.to_h.merge(role: 'website'))

    region = configuration.region
    backend_config = configuration.backend_config

    distribution_id = JSON.parse(
      RubyTerraform::Output.for(
        name: 'cdn_id',
        source_directory: 'infra/website',
        work_directory: 'build',
        backend_config:
      )
    )

    cloudfront = Aws::CloudFront::Client.new(region:)

    cloudfront.create_invalidation(
      distribution_id:,
      invalidation_batch: {
        caller_reference: SecureRandom.uuid,
        paths: {
          quantity: 1,
          items: ['/*']
        }
      }
    )
  end

  desc 'Deploy the website'
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
# rubocop:enable Metrics/BlockLength

RakeCircleCI.define_project_tasks(
  namespace: :circle_ci,
  project_slug: 'github/infrablocks/infrablocks.io'
) do |t|
  circle_ci_config =
    YAML.load_file('config/secrets/circle_ci/config.yaml')

  t.api_token = circle_ci_config['circle_ci_api_token']
  t.environment_variables = {
    ENCRYPTION_PASSPHRASE:
      File.read('config/secrets/ci/encryption.passphrase')
          .chomp
  }
  t.checkout_keys = []
end

namespace :pipeline do
  desc 'Prepare CircleCI Pipeline'
  task prepare: %i[
    circle_ci:env_vars:ensure
    circle_ci:checkout_keys:ensure
  ]
end

def default_deployment_identifier(args)
  args.with_defaults(
    deployment_group: 'ifbk',
    deployment_type: 'local',
    deployment_label: 'default'
  )
end
