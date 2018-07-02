# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'enum_ext/version'

Gem::Specification.new do |spec|
  spec.name          = "enum_ext"
  spec.version       = EnumExt::VERSION
  spec.authors       = ["alekseyl"]
  spec.email         = ["leshchuk@gmail.com"]

  spec.summary       = %q{Enum extension, ads enum sets, mass-assign, localization, and some sugar helpers.}
  spec.description   = %q{Enum extension, ads enum sets, mass-assign, localization, and some sugar helpers.}
  spec.homepage      = "https://github.com/alekseyl/enum_ext"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord', '>=4.2'

  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rails-i18n', '>=4'
  spec.add_development_dependency 'sqlite3'
end
