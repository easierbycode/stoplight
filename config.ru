$:.unshift File.dirname(__FILE__)
require 'config/boot'
#Logger.class_eval { alias :write :"<<" } unless Logger.instance_methods.include? "write"
Logger.class_eval { def write; ; end }

run Sinatra::Application
