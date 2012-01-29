require File.join([File.dirname(__FILE__),'lib','rtypist','version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'rtypist'
  s.version = Rtypist::VERSION
  s.author = 'Ben Griffiths'
  s.email = 'bengriffiths@gmail.com'
  s.homepage = 'http://techbelly.com'
  s.platform = Gem::Platform::RUBY
#TODO: Project needs a summary
  s.summary = 'Port of gnu typist to ruby. Probably ill-advised.'
  s.files = %w(
bin/rtypist
  )
  s.require_paths << 'lib'
  s.has_rdoc = false
  s.extra_rdoc_files = ['README.rdoc']
  s.rdoc_options << '--title' << 'rtypist' << '--main' << 'README.rdoc' << '-ri'
  s.bindir = 'bin'
  s.executables << 'rtypist'
  s.add_dependency('ncursesw')

  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
end
