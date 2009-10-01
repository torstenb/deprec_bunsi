# Copyright 2009 by Torsten Budesheim. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do
  namespace :deprec do
    namespace :phpmyadmin do

        set :phpmyadmin_base_dir, '/usr/share/phpmyadmin'  # can't be changed

        set :phpmyadmin_port, 8080
        set :phpmyadmin_log_dir, '/var/log'
        set :phpmyadmin_server, 'localhost'
                
        SRC_PACKAGES[:phpmyadmin] = {
          :md5sum => "5db3204d57436a032f899ff9dbce793f  lighttpd-1.4.18.tar.gz", 
          :url => "http://www.lighttpd.net/download/lighttpd-1.4.18.tar.bz2",
          :configure => "./configure;",
          :make => "make;",
          :install => "cp src/spawn-fcgi /usr/bin/spawn-fcgi;"
        }

        SYSTEM_CONFIG_FILES[:phpmyadmin] = [

          {:template => 'phpmyadmin.erb',
            :path => nginx_vhost_dir + '/phpmyadmin.conf',
            :mode => 0644,
            :owner => 'www-data:adm'},

          {:template => 'empty.log',
            :path => phpmyadmin_log_dir + '/access.log',
            :mode => 0644,
            :owner => 'www-data:adm'},

          {:template => 'empty.log',
            :path => phpmyadmin_log_dir + '/error.log',
            :mode => 0644,
            :owner => 'www-data:adm'}
        ]

        desc "Install phpmyadmin"
        task :install do
          apt.install( {:base => 'phpmyadmin'}, :stable )
          top.deprec.mod_rails.rem_apache unless web_server_type == :apache
          initial_config
        end

        task :initial_config do
          SYSTEM_CONFIG_FILES[:phpmyadmin].each do |file|
            deprec2.render_template(:phpmyadmin, file.merge(:remote => true))
          end
        end

    end
  end
end

