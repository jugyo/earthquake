module Earthquake
  module IdVar
    attr_accessor :id_var

    def id2var(id)
      id_var.id2var(id)
    end

    def var2id(var)
      id_var.var2id(var)
    end

    class Gen
      def initialize(vars = ('aa'..'zz').to_a, prefix = '$')
        if not vars.kind_of?(Array)
          raise ArgumentError, 'vars should be an Array'
        elsif vars.empty?
          raise ArgumentError, 'vars should not be empty'
        end
        @vars = vars.map { |var| prefix + var }
        @table = {}
        @rtable = {}
        @prefix = prefix
      end

      def var2id(var)
        @table[var]
      end

      def id2var(id)
        @rtable[id] || self.next(id)
      end

      def next(id)
        var = @vars.shift
        @vars.push var
        @rtable.delete(@table[var])
        @table[var] = id
        @rtable[id] = var
        var
      end
    end
  end

  extend IdVar

  init do
    self.id_var ||= IdVar::Gen.new
  end
end