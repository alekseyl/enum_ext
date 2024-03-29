# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'enum_ext/version'

Gem::Specification.new do |spec|
  spec.name          = "enum_ext"
  spec.version       = EnumExt::VERSION
  spec.authors       = ["alekseyl"]
  spec.email         = ["leshchuk@gmail.com"]

  spec.summary       = %q{Enum extension introduces: enum supersets, enum mass-assign, easy localization, and more sweetness to Active Record enums.}
  spec.description   = %q{Enum extension introduces: enum supersets, enum mass-assign, easy localization, and more sweetness to Active Record enums.}
  spec.homepage      = "https://github.com/alekseyl/enum_ext"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activerecord', ">= 5.2.4.3"

  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'bundler', '>= 1.11'
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'rails-i18n', '>=4'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'stubberry'
  spec.add_development_dependency 'rails_sql_prettifier'
  spec.add_development_dependency 'amazing_print'
end
