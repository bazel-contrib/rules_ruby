# frozen_string_literal: true

module HelloWorld
  class Speaker
    attr_reader :name

    def initialize(name = "world")
      @name = name
    end

    def message
      "Hello, #{@name}"
    end

    def hi
      puts message
    end
  end
end
