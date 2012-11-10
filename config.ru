$: << File.join(File.dirname(__FILE__), "lib")
require 'codely/app'

run Codely::App.new
