# Copyright 2009 by Torsten Budesheim. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :mod_rails do
          
      set(:passenger_install_dir) { "#{ruby_lib_dir}/gems/1.8/gems" }
      
      set(:passenger_document_root) { "#{current_path}/public" }
      set :passenger_rails_allow_mod_rewrite, 'off'
      # Default settings for Passenger config files
      set :passenger_log_level, 0
      set(:passenger_log_dir) { "#{shared_path}/log"} 
      set :passenger_user_switching, 'on'
      set :passenger_default_user, 'nobody'
      set :passenger_max_pool_size, 6
      set :passenger_max_instances_per_app, 0
      set :passenger_pool_idle_time, 300
      set :passenger_rails_autodetect, 'on'
      set :passenger_rails_spawn_method, 'smart' # smart | conservative

      set :nginx_server_name, nil
      set :nginx_user,  'www-data'
      set :nginx_group, 'adm'
      set :nginx_install_dir, '/usr/local/nginx' 
      set(:nginx_vhost_dir) { "#{nginx_install_dir}/conf/vhosts" }
      set :nginx_client_max_body_size, '100M'
      set :nginx_worker_processes, 4

      desc "Install passenger"
      task :install, :roles => :app do
        install_deps
        rem_apache
        gem2.install 'passenger'
        run "#{sudo} passenger-install-nginx-module --auto --prefix=#{nginx_install_dir} --auto-download"
        
        create_nginx_user
        initial_config
        activate
        #start        
      end
      
      task :create_nginx_user, :roles => :web do
        deprec2.groupadd(nginx_group) unless nginx_group == 'adm'
        deprec2.useradd(nginx_user, :group => nginx_group, :homedir => false) unless nginx_user == 'www-data'
      end

      # Install dependencies for Passenger specific to Nginx
      task :install_deps, :roles => :app do
        gem2.install 'fastthread'
        gem2.install 'rack'
        gem2.install 'rake'
        # These are more Rails than Passenger - Mike
        # gem2.install 'rails'
        # gem2.install "mysql -- --with-mysql-config='/usr/bin/mysql_config'"
        # gem2.install 'sqlite3-ruby'
        # gem2.install 'postgres'
      end
      
      # Remove Apache dependencies when using Nginx
      task :rem_apache do
        apps = "apache2-mpm-prefork apache2-utils apache2.2-common libapache2-mod-php5"

        # Default apt-get command - reduces any interactivity to the minimum.
        lcl_apt_get = "DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND=noninteractive apt-get" 

        send(run_method, %{ sh -c "#{lcl_apt_get} -qyu --force-yes remove #{apps}" })
      end

      SYSTEM_CONFIG_FILES[:mod_rails] = [

        {:template => 'nginx-init-script.erb',
          :path => '/etc/init.d/nginx',
          :mode => 0755,
          :owner => 'root:root'},

        {:template => 'nginx.conf.erb',
          :path => nginx_install_dir + "/conf/nginx.conf",
          :mode => 0644,
          :owner => 'www-data:adm'},

        {:template => 'nothing.conf',
          :path => nginx_vhost_dir + "/nothing.conf",
          :mode => 0644,
          :owner => 'www-data:adm'}

#        {:template => 'empty.log',
#          :path => nginx_install_dir + "/logs/error.log",
#          :mode => 0644,
#          :owner => 'www-data:adm'}

      ]

      task :initial_config, :roles => :web do
        SYSTEM_CONFIG_FILES[:mod_rails].each do |file|
          deprec2.render_template(:mod_rails, file.merge(:remote => true))
        end
      end
      
      desc <<-DESC
      Generate nginx config from template. Note that this does not
      push the config to the server, it merely generates required
      configuration files. These should be kept under source control.            
      The can be pushed to the server with the :config task.
      DESC
      task :config_gen do
        SYSTEM_CONFIG_FILES[:mod_rails].each do |file|
          deprec2.render_template(:mod_rails, file)
        end
      end

      task :symlink_logrotate_config, :roles => :app do
        sudo "ln -sf #{deploy_to}/passenger/logrotate.conf /etc/logrotate.d/passenger-#{application}"
      end
      
      # Passenger runs Rails as the owner of this file.
      task :set_owner_of_environment_rb, :roles => :app do
        sudo "chown  #{app_user} #{current_path}/config/environment.rb"
      end
      
      desc "Restart Application"
      task :restart_app, :roles => :app do
        run "#{sudo} touch #{current_path}/tmp/restart.txt"
      end
      
      desc <<-DESC
      Activate nginx start scripts on server.
      Setup server to start nginx on boot.
      DESC
      task :activate, :roles => :web do
        activate_system
      end

      task :activate_system, :roles => :web do
        send(run_method, "update-rc.d nginx defaults")
      end

      desc <<-DESC
      Dectivate nginx start scripts on server.
      Setup server to start nginx on boot.
      DESC
      task :deactivate, :roles => :web do
        send(run_method, "update-rc.d -f nginx remove")
      end

      # Control

      desc "Start Nginx"
      task :start, :roles => :web do
        # Nginx returns error code if you try to start it when it's already running
        # We don't want this to kill Capistrano.
        #top.deprec.minicgi.stop
        sudo("/etc/init.d/nginx start; exit 0")  
        #top.deprec.minicgi.start
      end

      desc "Stop Nginx"
      task :stop, :roles => :web do
        # Nginx returns error code if you try to stop when it's not running
        # We don't want this to kill Capistrano. 
        sudo("/etc/init.d/nginx stop; exit 0")  
        #top.deprec.minicgi.stop
      end

      desc "Restart Nginx"
      task :restart, :roles => :web do
        stop
        start
      end

      desc "Reload Nginx"
      task :reload, :roles => :web do
        # Nginx returns error code if you try to reload when it's not running
        # We don't want this to kill Capistrano.
        send(run_method, "/etc/init.d/nginx reload; exit 0")
      end
      
      # Helper task to get rid of pesky "it works" page - not called by deprec tasks
      task :rename_index_page, :roles => :web do
        index_file = nginx_install_dir + '/html/index.html'
        sudo "test -f #{index_file} && sudo mv #{index_file} #{index_file}.orig || exit 0"
      end

    end
    
  end
end
