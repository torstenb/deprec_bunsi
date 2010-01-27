require 'rubygems' 

SPEC = Gem::Specification.new do |s|
  s.name = 'deprec_bunsi'
  s.version = '2.2.0'
  
  s.authors = ['Mike Bailey', 'Torsten Budesheim']
  s.description = <<-EOF
      This project provides libraries of Capistrano tasks and extensions to 
      remove the repetative manual work associated with installing services 
      on linux servers.
  EOF
  s.email = 'torstenb@gmail.com'
  s.homepage = 'http://www.bunsi.net/'
  s.rubyforge_project = ''
  s.summary = 'deployment recipes for capistrano tailored to bunsi.net'

  s.require_paths = ['lib']
  s.add_dependency('capistrano', '> 2.5.14')
  candidates = Dir.glob("{bin,docs,lib}/**/*") 
  candidates.concat(%w(CHANGELOG COPYING LICENSE README THANKS))
  s.files = candidates.delete_if do |item| 
    item.include?("CVS") || item.include?("rdoc") 
  end
  s.default_executable = "depify"
  s.executables = ["depify"]
end
