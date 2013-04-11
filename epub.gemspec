# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'epub/version'
 
Gem::Specification.new do |s|
  s.name        = "epub"
  s.version     = Epub::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Orange Mug"]
  #s.email       = ["example@example.com"]
  s.homepage    = "http://github.com/completelynovel/epub"
  s.summary     = "Access and modify the contents of an EPUB"
  s.description = "Access and modify the contents of an EPUB"
 
  s.required_rubygems_version = ">= 1.3.6"
  #s.rubyforge_project         = "example"
 
  # No tests yet
  s.add_development_dependency "rspec"
  s.add_development_dependency "yard"

  s.add_dependency "rubyzip"
  s.add_dependency "mime-types"
  s.add_dependency "sass"
  s.add_dependency "nokogiri"
  s.add_dependency "sanitize"
  s.add_dependency "fastimage"
  s.add_dependency "ruby-filemagic"
  s.add_dependency "activesupport"

  s.files        = Dir.glob("{bin,lib}/**/*") + %w(README.md)
  s.executables  = ['epub']
  s.require_path = 'lib'
end