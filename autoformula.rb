require_relative 'formula'

class AutoFormula < Formula
  def initialize(class_name)
    @formula_file = method(:initialize).source_location[0]
    super(class_name)
  end
end
