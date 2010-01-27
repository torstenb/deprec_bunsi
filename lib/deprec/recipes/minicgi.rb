# Copyright 2009 by Torsten Budesheim. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do
  namespace :deprec do
    namespace :minicgi do

      set :fcgi_pid_name, '/var/run/fastcgi-php.pid'
      set :fcgi_port, 49232
      
        SRC_PACKAGES[:minicgi] = {
          :md5sum => "5db3204d57436a032f899ff9dbce793f  lighttpd-1.4.18.tar.gz", 
          :url => "http://www.lighttpd.net/download/lighttpd-1.4.18.tar.bz2",
          :configure => "./configure;",
          :make => "make;",
          :install => "cp src/spawn-fcgi /usr/bin/spawn-fcgi;"
        }

        SYSTEM_CONFIG_FILES[:minicgi] = [

          {:template => 'php-fcgi-initd.erb',
           :path => '/etc/init.d/php-fastcgi',
           :mode => 0755,
           :owner => 'root:root'},

          {:template => 'php-default-conf.erb',
           :path => "/etc/default/php-fastcgi",
           :mode => 0755,
           :owner => 'root:root'}

        ]

        PROJECT_CONFIG_FILES[:minicgi] = [

           {:template => 'monit.conf.erb',
            :path => "#{deploy_to}/monit/php-fastcgi_monit.conf",
            :mode => 0640,
            :owner => "root:#{group}"}

        ]

        desc "Install minimal FastCGI pckg"
        task :install do
          apps = %w(libfcgi libfcgi-perl libfcgi bzip2 libpcre3-dev php5-cgi)
          apt.install( {:base => apps}, :stable )
          deprec2.download_src(SRC_PACKAGES[:minicgi], src_dir)
          deprec2.install_from_src(SRC_PACKAGES[:minicgi], src_dir)
          push_scripts
          activate
          #start        
        end

        desc "Push mini FastCGI scripts to server"
        task :push_scripts do
          deprec2.push_configs(:minicgi, SYSTEM_CONFIG_FILES[:minicgi])
        end

        desc <<-DESC
        Activate php-fastcgi start scripts on server.
        Setup server to start script on boot.
        DESC
        task :activate do
          activate_system
        end

        task :activate_system do
          sudo("update-rc.d php-fastcgi defaults 19 21")
        end

        desc "Push php-fastcgi configs (project level) to server"
        task :config_project, :roles => :app do
          deprec2.push_configs(:minicgi, PROJECT_CONFIG_FILES[:minicgi])
          symlink_monit_config
        end

        task :symlink_monit_config, :roles => :app do
          sudo "ln -sf #{deploy_to}/monit/php-fastcgi_monit.conf #{monit_confd_dir}/php-fastcgi_#{application}.conf"
        end

        # Control

        desc "Start mini FastCGI"
        task :start do
          sudo("/etc/init.d/php-fastcgi start")
        end

        desc "Stop mini FastCGI"
        task :stop do
          sudo("/etc/init.d/php-fastcgi stop")
        end

        desc "Restart mini FastCGI"
        task :restart do
          sudo("/etc/init.d/php-fastcgi restart")
        end

    end
  end
end

