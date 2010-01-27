# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do     
    namespace :ree do
      set :ree_version, 'ruby-enterprise-1.8.7-2009.10'
      set :ree_install_dir, "/opt/#{ree_version}"
      set :ree_short_path, '/opt/ruby-enterprise'
      
      SRC_PACKAGES[:ree] = {
#        :md5sum => "0bf66ee626918464a6eccdd83c99d63a #{ree_version}.tar.gz",
        :url => "http://rubyforge.org/frs/download.php/66162/ruby-enterprise-1.8.7-2009.10.tar.gz",
        :configure => '',
        :make => '',
        :install => "./installer --auto #{ree_install_dir}"
      }
 
      task :install do
        install_from_src
      end
      
      task :install_from_src do
        install_deps
        deprec2.download_src(SRC_PACKAGES[:ree], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:ree], src_dir)
        symlink_ree
        add_to_path
        set (:ruby_bin_dir) { "#{ree_short_path}/bin"}
        set (:ruby_lib_dir) { "#{ree_short_path}/lib/ruby" }
      end
      
      task :install_deps do
        apt.install({:base => %w(libmcrypt-dev mcrypt libssl-dev libmysqlclient15-dev libreadline5-dev)}, :stable)
      end
      
      task :symlink_ree do
        sudo "ln -sf /opt/#{ree_version} #{ree_short_path}"
        sudo "ln -fs #{ree_short_path}/bin/gem /usr/local/bin/gem"
        sudo "ln -fs #{ree_short_path}/bin/irb /usr/local/bin/irb"
        sudo "ln -fs #{ree_short_path}/bin/rake /usr/local/bin/rake"
        sudo "ln -fs #{ree_short_path}/bin/rails /usr/local/bin/rails"
        sudo "ln -fs #{ree_short_path}/bin/ruby /usr/local/bin/ruby"
      end
      
      task :add_to_path do
        deprec2.replace_in_file('/etc/environment', "^PATH=\"", "PATH=\"#{ree_install_dir}/bin:")
      end
      
    end
    
  end
end
