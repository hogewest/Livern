$:.unshift File.expand_path(File.join(File.dirname(__FILE__)))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'livern'))

require 'rubygems'
require 'bundler'

Bundler.setup

require 'livern'
run Livern::App
