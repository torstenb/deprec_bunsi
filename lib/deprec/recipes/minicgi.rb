# Copyright 2009 by Torsten Budesheim. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do
  namespace :deprec do
    namespace :minicgi do

      set :fcgi_pid_name, '/var/run/fastcgi-php.pid'

        SRC_PACKAGES[:minicgi] = {
          :md5sum => "5db3204d57436a032f899ff9dbce793f  lighttpd-1.4.18.tar.gz", 
          :url => "http://www.lighttpd.net/download/lighttpd-1.4.18.tar.bz2",
          :configure => "./configure;",
          :make => "make;",
          :install => "cp src/spawn-fcgi /usr/bin/spawn-fcgi;"
        }

        SYSTEM_CONFIG_FILES[:minicgi] = [

          {:template => 'php5-fcgi-initd-script',
           :path => '/etc/init.d/php5-fcgi',
           :mode => 0755,
           :owner => 'root:root'},

          {:template => 'php5-fcgi.erb',
           :path => "/usr/bin/php5-fcgi",
           :mode => 0755,
           :owner => 'root:root'}

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
        Activate php5-fcgi start scripts on server.
        Setup server to start script on boot.
        DESC
        task :activate do
          activate_system
        end

        task :activate_system do
          send(run_method, "update-rc.d php5-fcgi defaults")
        end

        # Control

        desc "Start mini FastCGI"
        task :start do
          send(run_method, "/etc/init.d/php5-fcgi start; exit 0")
          #sudo("/etc/init.d/php5-fcgi start > /dev/null ; exit 0")  
        end

        desc "Stop mini FastCGI"
        task :stop do
          send(run_method, "/etc/init.d/php5-fcgi stop; exit 0")
          #sudo("/etc/init.d/php5-fcgi stop > /dev/null ; exit 0")  
        end

        desc "Restart mini FastCGI"
        task :restart do
          stop
          start
        end

    end
  end
end

