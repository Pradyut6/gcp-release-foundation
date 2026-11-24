require 'yaml'

folder = ARGV.fetch(0)
config = YAML.load_file(File.join(folder, 'skaffold.yaml'))
profiles = config.fetch('profiles')
abort 'Unexpected release stages' unless profiles.map { |profile| profile.fetch('name') } == %w[staging production]

accounts = profiles.map do |profile|
  path = profile.dig('manifests', 'rawYaml').fetch(0)
  service = YAML.load_file(File.join(folder, path))
  spec = service.dig('spec', 'template', 'spec')
  abort "Public service in #{path}" unless service.dig('metadata', 'annotations', 'run.googleapis.com/ingress') == 'internal'
  abort "Missing replaceable image in #{path}" unless spec.fetch('containers').any? { |container| container['image'] == 'app' }
  spec.fetch('serviceAccountName')
end

abort 'Runtime accounts must be separate' unless accounts.uniq.length == profiles.length
