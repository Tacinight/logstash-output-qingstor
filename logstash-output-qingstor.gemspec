Gem::Specification.new do |s|
  s.name          = 'logstash-output-qingstor'
  s.version       = '0.3.1'
  s.licenses      = ['Apache License (2.0)']
  s.summary       = 'logstash output plugin for qingstor'
  s.description   = 'Collect the outputs of logstash and store into QingStor'
  s.homepage      = 'https://github.com/yunify/logstash-output-qingstor'
  s.authors       = ['Evan Zhao']
  s.email         = 'tacingiht@gmail.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*', 'spec/**/*', 'vendor/**/*', '*.gemspec', '*.md', 'CONTRIBUTORS', 'Gemfile', 'LICENSE', 'NOTICE.TXT']
  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { 'logstash_plugin' => 'true', 'logstash_group' => 'output' }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core-plugin-api', '~> 2.0'
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'qingstor-sdk', '>= 1.9.3'
  s.add_runtime_dependency 'concurrent-ruby'

  s.add_development_dependency 'stud', '~> 0.0.22'
  s.add_development_dependency 'logstash-devutils'
end
