# Copyright 2009 by Torsten Budesheim. All rights reserved.
Capistrano::Configuration.instance(:must_exist).load do
  namespace :deprec do
    namespace :pcre do

        set :pcre_install_dir, '/opt/local'
                
        SRC_PACKAGES[:pcre] = {
          :url => "http://downloads.sourceforge.net/project/pcre/pcre/8.00/pcre-8.00.tar.gz",
          :configure => "./configure --prefix=#{pcre_install_dir}",
        }

        desc "Install PCRE"
        task :install do
          deprec2.download_src(SRC_PACKAGES[:pcre], src_dir)
          deprec2.install_from_src(SRC_PACKAGES[:pcre], src_dir)
        end

    end
  end
end

