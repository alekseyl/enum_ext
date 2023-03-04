module Tally
  def tally_by(&function)
    function ||= -> v { v }

    each_with_object(Hash.new(0)) do |value, hash|
      hash[function.call(value)] += 1
    end
  end

  def tally
    tally_by(&:itself)
  end
end

Enumerable.include Tally unless Enumerable.instance_methods.include?(:tally)