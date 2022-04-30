#!/usr/local/opt/ruby/bin/ruby

require_relative 'autoformula'

class PathEnv < AutoFormula
  def initialize()
    super(singleton_class.to_s)
    puts("Class: #{@class_name}")
    puts("Formula: #{@formula_name}")
    puts("File: #{@formula_file}")
  end
end

PathEnv.new()
