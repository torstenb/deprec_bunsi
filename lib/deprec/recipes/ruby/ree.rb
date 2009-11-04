# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do     
    namespace :ree do
      set :ree_version, 'ruby-enterprise-1.8.7-20090928'
      set :ree_install_dir, "/opt/#{ree_version}"
      set :ree_short_path, '/opt/ruby-enterprise'
      
      SRC_PACKAGES[:ree] = {
#        :md5sum => "0bf66ee626918464a6eccdd83c99d63a #{ree_version}.tar.gz",
        :url => "http://rubyforge.org/frs/download.php/64475/ruby-enterprise-1.8.7-20090928.tar.gz",
        :configure => '',
        :make => '',
        :install => "./installer --auto /opt/#{ree_version}"
      }
 
      task :install do
        install_from_src
      end
      
      task :install_from_src do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:ree], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:ree], src_dir)
        symlink_ree
        set (:ruby_bin_dir) { "#{ree_short_path}"}
        set (:ruby_lib_dir) { "#{ree_short_path}/lib/ruby" }
      end
      
      task :install_deps do
        apt.install({:base => %w(libssl-dev libmysqlclient15-dev libreadline5-dev)}, :stable)
      end
      
      task :symlink_ree do
        sudo "ln -sf /opt/#{ree_version} #{ree_short_path}"
        sudo "ln -fs #{ree_short_path}/bin/gem /usr/local/bin/gem"
        sudo "ln -fs #{ree_short_path}/bin/irb /usr/local/bin/irb"
        sudo "ln -fs #{ree_short_path}/bin/rake /usr/local/bin/rake"
        sudo "ln -fs #{ree_short_path}/bin/rails /usr/local/bin/rails"
        sudo "ln -fs #{ree_short_path}/bin/ruby /usr/local/bin/ruby"
      end
      
    end
    
  end
end
