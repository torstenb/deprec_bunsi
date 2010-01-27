# Copyright 2006-2008 by Mike Bailey. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :sphinx do
      
      SRC_PACKAGES[:sphinx] = {
        :filename => 'sphinx-0.9.9.tar.gz',   
        :dir => 'sphinx-0.9.9',  
        :url => "http://www.sphinxsearch.com/downloads/sphinx-0.9.9.tar.gz",
        :unpack => "tar zxf sphinx-0.9.9.tar.gz;",
        :configure => %w(
          ./configure
          ;
          ).reject{|arg| arg.match '#'}.join(' '),
        :make => 'make;',
        :install => 'make install;'
      }
      
      desc "Install Sphinx Search Engine"
      task :install, :roles => [:app, :sphinx] do
        install_deps
        download_and_install
      end
    
      task :download_and_install, :roles => :sphinx do
        deprec2.download_src(SRC_PACKAGES[:sphinx], src_dir)
        deprec2.install_from_src(SRC_PACKAGES[:sphinx], src_dir)
      end
      
      # install dependencies for sphinx
      # note: aspell is required on both the app server and the sphinx server!
      task :install_deps, roles => [:app, :sphinx] do
        apt.install( {:base => %w(aspell libaspell-dev aspell-en)}, :stable )
      end

      SYSTEM_CONFIG_FILES[:sphinx] = []
      
      PROJECT_CONFIG_FILES[:sphinx] = [

        {:template => 'monit.conf.erb',
         :path => "#{deploy_to}/monit/sphinx_monit.conf",
         :mode => 0640,
         :owner => "root:#{group}"}
      ]

      desc <<-DESC
      Generate sphinx config from template. Note that this does not
      push the config to the server, it merely generates required
      configuration files. These should be kept under source control.            
      The can be pushed to the server with the :config task.
      DESC
      task :config_gen do
        PROJECT_CONFIG_FILES[:sphinx].each do |file|
          deprec2.render_template(:sphinx, file)
        end
      end

      desc "Push sphinx config files to server"
      task :config, :roles => :sphinx do
        config_project
      end
      
      desc "Push sphinx config files to server"
      task :config_project, :roles => :sphinx do
        deprec2.push_configs(:sphinx, PROJECT_CONFIG_FILES[:sphinx])
        symlink_monit_config
      end
      
      task :symlink_monit_config, :roles => :sphinx do
        sudo "ln -sf #{deploy_to}/monit/sphinx_monit.conf #{monit_confd_dir}/sphinx_#{application}.conf"
      end


      # Control
      
      desc "Restart the sphinx searchd daemon"
      task :restart, :roles => :sphinx do
        run("cd #{deploy_to}/current; rake us:restart RAILS_ENV=#{stage}")
      end

      desc "Regenerate / Rotate the search index."
      task :reindex, :roles => :sphinx do
        run("cd #{deploy_to}/current; rake us:in RAILS_ENV=#{stage}")
      end

    end 
  end
end

# ultrasphinx deployment notes
# http://blog.evanweaver.com/files/doc/fauna/ultrasphinx/files/DEPLOYMENT_NOTES.html