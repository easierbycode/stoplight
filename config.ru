$:.unshift File.dirname(__FILE__)
require 'config/boot'
Logger.class_eval { alias :write :"<<" } unless Logger.instance_methods.include? "write"

run Sinatra::Application
