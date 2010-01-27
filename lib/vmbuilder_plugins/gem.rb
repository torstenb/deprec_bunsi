# =gem.rb: Gem Installer library
# Capistrano library to install and manage Ruby Gems.
# 
# ----
# Copyright (c) 2007 Neil Wilson, Aldur Systems Ltd
#
# Licensed under the GNU Public License v2. No warranty is provided.

require 'capistrano'

# = Purpose
# Gem is a Capistrano plugin module providing a set of methods
# that invoke the *gem* package manager.
#
# Installs within Capistrano as the plugin _gem_.
#
# =Usage
#    
#    require 'vmbuilder_plugins/gem'
#
# Prefix all calls to the library with <tt>gem.</tt>
#
module Gem

  # Default install command
  #
  # * doesn't install documentation
  # * installs all required dependencies automatically.
  #
  GEM_INSTALL="gem install --no-rdoc --no-ri"
  GEM_UPDATE=GEM_INSTALL.sub("install", "update")

  # 10/13/2010 - torstenb
  # Always run the Apt commands as sudo - anything else wouldn't really make sense, would it?
  # Yet in order to give back control to :run_method to define the actual way to run the Apt-
  # commands :force_run_method can be set to true
  def lcl_run_method
    if fetch(:force_run_method, false)
      @lcl_run_method = run_method
    else
      @lcl_run_method = 'sudo'
    end
  end
  
  # Upgrade the *gem* system to the latest version. Runs via *sudo*
  def update_system
    send(lcl_run_method, "#{GEM_UPDATE} --system")
  end

  # Updates all the installed gems to the latest version. Runs via *sudo*.
  # Don't use this command if any of the gems require a version selection.
  def upgrade
    send(lcl_run_method, GEM_UPDATE)
  end

  # Removes old versions of gems from installation area.
  def cleanup
    send(lcl_run_method, "gem cleanup")
  end

  # Installs the gems detailed in +packages+, selecting version +version+ if
  # specified.
  #
  # +packages+ can be a single string or an array of strings.
  #  
  def install(packages, version=nil)
    send(lcl_run_method,"#{GEM_INSTALL} #{if version then '-v '+version.to_s end} #{packages.to_a.join(' ')}")
  end

  # Auto selects a gem from a list and installs it.
  #
  # *gem* has no mechanism on the command line of disambiguating builds for
  # different platforms, and instead asks the user. This method has the necessary
  # conversation to select the +version+ relevant to +platform+ (or the one nearest
  # the top of the list if you don't specify +version+).
  def select(package, version=nil, platform='ruby')
    selections={}
    cmd="#{GEM_INSTALL} #{if version then '-v '+version.to_s end} #{package}"
    send lcl_run_method, cmd do |channel, stream, data|
      data.each_line do | line |
	case line
	when /\s(\d+).*\(#{platform}\)/
	  if selections[channel[:host]].nil?
	    selections[channel[:host]]=$1.dup+"\n"
	    logger.info "Selecting #$&", "#{stream} :: #{channel[:host]}"
	  end
	when /\s\d+\./
	  # Discard other selections from data stream
	when /^>/
	  channel.send_data selections[channel[:host]]
	  logger.debug line, "#{stream} :: #{channel[:host]}"
	else
	  logger.info line, "#{stream} :: #{channel[:host]}"
	end
      end
    end
  end

end

Capistrano.plugin :gem2, Gem
# vim: nowrap sw=2 sts=2 ts=8 ff=unix ft=ruby:
