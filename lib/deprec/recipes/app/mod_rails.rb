# Copyright 2009 by Torsten Budesheim. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do 
  namespace :deprec do 
    namespace :mod_rails do
          
      set :passenger_version, '2.2.9'
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
      # set :nginx_user,  'www-data'
      set :nginx_user, exists?(:runner) ? fetch(:runner) : 'www-data'
      # set :nginx_group, 'adm'
      set :nginx_group, exists?(:group) ? fetch(:group) : 'adm'
      set :nginx_install_dir, '/usr/local/nginx' 
      set(:nginx_vhost_dir) { "#{nginx_install_dir}/conf/vhosts_active" }
      set(:nginx_vhost_avail) { "#{nginx_install_dir}/conf/vhosts" }
      set :nginx_client_max_body_size, '100M'
      set :nginx_worker_processes, 2
      set :nginx_beta_opt, " --auto-download"
      set :install_nginx_beta, true
            
      NGINX_INST_OPTS = "--auto --prefix=#{nginx_install_dir}"
      
      desc "Install Passenger+Nginx."
      task :install, :roles => [:web, :app] do
        download_beta if install_nginx_beta

        apt.install({:base => %w(libgcrypt11-dev libpcre3 libpcre3-dev libpcrecpp0 libssl-dev)}, :stable)
        if ruby_vm_type == :ree
          run "#{sudo} #{ruby_bin_dir}/passenger-install-nginx-module #{NGINX_INST_OPTS}#{nginx_beta_opt}"
        else
          install_deps
          rem_apache
          gem2.install 'passenger'
          run "#{sudo} passenger-install-nginx-module #{NGINX_INST_OPTS}#{nginx_beta_opt}"
        end
        create_nginx_user
        initial_config
      end
      
      task :download_beta, :roles => :web do
        SRC_PACKAGES[:nginx_beta] = {
          :url => "http://nginx.org/download/nginx-0.8.32.tar.gz",
          :configure => './configure --sbin-path=/usr/local/sbin --with-http_ssl_module;'
        }

        deprec2.download_src(SRC_PACKAGES[:nginx_beta], src_dir)
        deprec2.unpack_src(SRC_PACKAGES[:nginx_beta], src_dir)
        deprec2.set_package_defaults(SRC_PACKAGES[:nginx_beta])
        set(:nginx_beta_opt) { " --nginx-source-dir=#{File.join(src_dir, SRC_PACKAGES[:nginx_beta][:dir])} --extra-configure-flags=none" }
      end
      
      task :create_nginx_user, :roles => :web do
        deprec2.groupadd(nginx_group) unless nginx_group == 'adm'
        deprec2.useradd(nginx_user, :group => nginx_group, :homedir => false) unless nginx_user == 'www-data'
      end

      # Install dependencies for Passenger specific to Nginx
      task :install_deps, :roles => [:app, :web] do
        #apt.install({:base => %w(libgcrypt11-dev libpcre3 libpcre3-dev libpcrecpp0 libssl-dev)}, :stable)

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
      task :rem_apache, :roles => :web do
        apps = "apache2-mpm-prefork apache2-utils apache2.2-common libapache2-mod-php5"

        # Default apt-get command - reduces any interactivity to the minimum.
        lcl_apt_get = "DEBCONF_TERSE='yes' DEBIAN_PRIORITY='critical' DEBIAN_FRONTEND=noninteractive apt-get" 

        sudo(%{ sh -c "#{lcl_apt_get} -qyu --force-yes remove #{apps}" })
      end

      SYSTEM_CONFIG_FILES[:mod_rails] = [

        {:template => 'nginx-init-script.erb',
          :path => '/etc/init.d/nginx',
          :mode => 0755,
          :owner => 'root:root'},

        {:template => 'nginx.conf.erb',
          :path => nginx_install_dir + "/conf/nginx.conf",
          :mode => 0644,
          :owner => "#{nginx_user}:#{nginx_group}"},

          {:template => 'welcome_vhost.conf.erb',
           :path => "#{nginx_vhost_avail}/welcome.conf",
           :mode => 0640,
           :owner => "root:#{group}"}

#        {:template => 'empty.log',
#          :path => nginx_install_dir + "/logs/error.log",
#          :mode => 0644,
#          :owner => 'www-data:adm'}
      ]

      PROJECT_CONFIG_FILES[:mod_rails] = [
           
        {:template => 'logrotate.conf.erb',
         :path => "#{deploy_to}/logrotate/#{application}_logrotate.conf", 
         :mode => 0644,
         :owner => "root:#{group}"},  
        
         {:template => 'monit.conf.erb',
          :path => "#{deploy_to}/monit/nginx_monit.conf",
          :mode => 0640,
          :owner => "root:#{group}"}        
      ]

      task :initial_config, :roles => :web do
        deprec2.mkdir(nginx_vhost_dir, :via => :sudo )
        config_system
        #SYSTEM_CONFIG_FILES[:mod_rails].each do |file|
        # deprec2.render_template(:mod_rails, file.merge(:remote => true))
        #end
      end
      
# TODO: check!
      desc <<-DESC
      Locally generate Nginx+Passenger configurations from template. 
      This generates both system and project specific configuration files
      locally. These could be e.g kept under source control.
      Note: this does not push the config to the server. 
      DESC
      task :config_gen do
        config_gen_system
        cofig_gen_project
      end

      desc "Locally generate Passenger+Nginx system configs (from template)."
      task :config_gen_system do
        SYSTEM_CONFIG_FILES[:mod_rails].each do |file|
          deprec2.render_template(:mod_rails, file)
        end
      end

      desc "Locally generate Passenger+Nginx project configs (from template)."
      task :config_gen_project do
        PROJECT_CONFIG_FILES[:mod_rails].each do |file|
          deprec2.render_template(:mod_rails, file)
        end
      end

      desc "Push Passenger+Nginx system configs to server."
      task :config_system, :roles => :app do
        deprec2.push_configs(:mod_rails, SYSTEM_CONFIG_FILES[:mod_rails])
        enable_autostart
        enable_welcome_page if :stage == "staging" 
      end

      desc <<-DESC
      Push non-sytem configs to server.
      Pushes project level configs, monit & logrotate configs.
      DESC
      task :config_project, :roles => :app do
        deprec2.push_configs(:mod_rails, PROJECT_CONFIG_FILES[:mod_rails])
        symlink_logrotate_config
        symlink_monit_config
      end

      task :symlink_logrotate_config, :roles => :app do
        sudo "ln -fs #{deploy_to}/logrotate/#{application}_logrotate.conf /etc/logrotate.d/nginx-#{application}"
      end
      
      task :symlink_monit_config, :roles => :app do
        sudo "ln -fs #{deploy_to}/monit/nginx_monit.conf /etc/monit.d/nginx-#{application}"
      end
      
      # Passenger runs Rails as the owner of this file.
      task :set_owner_of_environment_rb, :roles => :app do
        sudo "chown  #{app_user} #{current_path}/config/environment.rb"
      end
      
      desc <<-DESC
      Enable Nginx autostart upon boot.
      Activates Nginx start script on server.
      DESC
      task :enable_autostart, :roles => :web do
        sudo("update-rc.d nginx defaults")
      end

      task :activate, :roles => :web do
        enable_autostart
      end

      desc <<-DESC
      Disable Nginx autostart upon boot.
      Dectivates Nginx start script on server.
      DESC
      task :disable_autostart, :roles => :web do
        sudo("update-rc.d -f nginx remove")
      end

      # Control

      desc "Start Nginx"
      task :start, :roles => :web do
        # Nginx returns error code if you try to start it when it's already running
        # We don't want this to kill Capistrano.
        sudo("/etc/init.d/nginx start; exit 0")
      end

      desc "Stop Nginx"
      task :stop, :roles => :web do
        # Nginx returns error code if you try to stop when it's not running
        # We don't want this to kill Capistrano. 
        sudo("/etc/init.d/nginx stop; exit 0")
      end

      desc "Restart Nginx"
      task :restart, :roles => :web do
        sudo("/etc/init.d/nginx restart; exit 0")
      end

      desc "Reload Nginx"
      task :reload, :roles => :web do
        # Nginx returns error code if you try to reload when it's not running
        # We don't want this to kill Capistrano.
        sudo("/etc/init.d/nginx reload; exit 0")
      end
      
      # Helper task to get rid of pesky "it works" page - not called by deprec tasks
      task :disable_welcome_page, :roles => :web do
        sudo "test -f #{nginx_vhost_dir}/welcome.conf && rm #{nginx_vhost_dir}/welcome.conf || exit 0"
      end

      # Helper to enable the "it works" page
      task :enable_welcome_page, :roles => :web do
        sudo "test -f #{nginx_vhost_dir}/welcome.conf || #{sudo} ln -sf #{nginx_vhost_avail}/welcome.conf #{nginx_vhost_dir}/welcome.conf"
      end

    end
    
  end
end
