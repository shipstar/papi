# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "papi/version"

Gem::Specification.new do |s|
  s.name        = "papi"
  s.version     = Papi::VERSION
  s.authors     = ["Kyle Shipley"]
  s.email       = ["kshipley@giggil.com"]
  s.homepage    = ""
  s.summary     = %q{A direct port of the ruby-aaws gem into a rational gem structure.}
  s.description = %q{Forthcoming.}

  s.rubyforge_project = "papi"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
