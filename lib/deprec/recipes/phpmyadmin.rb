# Copyright 2009 by Torsten Budesheim. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do
  namespace :deprec do
    namespace :phpmyadmin do

        set :phpmyadmin_std_dir, '/usr/share/phpmyadmin'  # can't be changed
        set :phpmyadmin_base_dir, '/usr/share/phpmyadmin.current'  # can't be changed
        set :phpmyadmin_src, 'phpMyAdmin-3.2.2.1-all-languages'
        set :phpmyadmin_port, 8080
        set :phpmyadmin_log_dir, '/var/log'
        set :phpmyadmin_server, 'localhost'
                
        SRC_PACKAGES[:phpmyadmin] = {
          :md5sum => "2433403efdb5347d741846f0c9456773  phpMyAdmin-3.2.2.1-all-languages.tar.bz2", 
          :url => "http://downloads.sourceforge.net/project/phpmyadmin/phpMyAdmin/3.2.2.1/phpMyAdmin-3.2.2.1-all-languages.tar.bz2",
          :configure => "",
          :make => "",
          :install => "cp -r #{src_dir}/#{phpmyadmin_src} #{phpmyadmin_base_dir}; ",
          :post_install => "cp -f #{phpmyadmin_std_dir}/config.inc.php #{phpmyadmin_base_dir}; "
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
          upgrade
          initial_config
        end

        task :initial_config do
          SYSTEM_CONFIG_FILES[:phpmyadmin].each do |file|
            deprec2.render_template(:phpmyadmin, file.merge(:remote => true))
          end
        end

        task :upgrade do
          deprec2.download_src(SRC_PACKAGES[:phpmyadmin], src_dir)
          deprec2.install_from_src(SRC_PACKAGES[:phpmyadmin], src_dir)
        end

    end
  end
end

