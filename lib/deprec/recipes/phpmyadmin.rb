# Copyright 2009 by Torsten Budesheim. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do

  require File.join(File.dirname(__FILE__), '/app/mod_rails.rb')
  
  namespace :deprec do
    namespace :phpmyadmin do

        set :phpmyadmin_std_dir, '/usr/share/phpmyadmin'  # can't be changed
        set :phpmyadmin_base_dir, '/usr/share/phpmyadmin.current'  # can't be changed
        set :phpmyadmin_src, 'phpMyAdmin-3.2.4-all-languages'
        set :phpmyadmin_port, 8080
        set(:phpmyadmin_log_dir) { "#{nginx_install_dir}/logs" }
        set :phpmyadmin_server, 'localhost'
        set :phpmyadmin_user, exists?(:runner) ? fetch(:runner) : 'www-data'
        set :phpmyadmin_group, exists?(:group) ? fetch(:group) : 'adm'
                
        SRC_PACKAGES[:phpmyadmin] = {
          :md5sum => "b927655abd701d8e35079f9e5ec24ee2  phpMyAdmin-3.2.4-all-languages.tar.bz2", 
          :url => "http://downloads.sourceforge.net/project/phpmyadmin/phpMyAdmin/3.2.4/phpMyAdmin-3.2.4-all-languages.tar.bz2",
          :configure => "",
          :make => "",
          :install => "cp -r #{src_dir}/#{phpmyadmin_src} #{phpmyadmin_base_dir}; ",
          :post_install => "cp -f #{phpmyadmin_std_dir}/config.inc.php #{phpmyadmin_base_dir}; "
        }

        SYSTEM_CONFIG_FILES[:phpmyadmin] = [

          {:template => 'phpmyadmin.erb',
            :path => nginx_vhost_avail + '/phpmyadmin.conf',
            :mode => 0644,
            :owner => "#{phpmyadmin_user}:#{phpmyadmin_group}"}

          #{:template => 'empty.log',
          #  :path => phpmyadmin_log_dir + '/access.log',
          #  :mode => 0644,
          #  :owner => "#{phpmyadmin_user}:#{phpmyadmin_group}"},

          #{:template => 'empty.log',
          #  :path => phpmyadmin_log_dir + '/error.log',
          #  :mode => 0644,
          #  :owner => "#{phpmyadmin_user}:#{phpmyadmin_group}"}
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

        desc "Deactivate phpmyadmin on Nginx+Passenger"
        task :deactivate, :roles => :web do
          if app_server_type == :mod_rails then
            sudo "test -f #{nginx_vhost_dir}/phpmyadmin.conf && #{sudo} rm #{nginx_vhost_dir}/phpmyadmin.conf || exit 0"
          else
            puts 'Sorry, this task doesn\'t work with your configuration'
          end
        end

        desc "Activate phpmyadmin on Nginx+Passenger"
        task :activate, :roles => :web do
          if app_server_type == :mod_rails then
            sudo "test -f #{nginx_vhost_dir}/phpmyadmin.conf || #{sudo} ln -sf #{nginx_vhost_avail}/phpmyadmin.conf #{nginx_vhost_dir}/phpmyadmin.conf"
          else
            puts 'Sorry, this task doesn\'t work with your configuration'
          end
        end

    end
  end
end

