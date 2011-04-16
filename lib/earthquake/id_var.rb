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
      def initialize(vars = "aa".."zz", prefix = "$")
        unless Range === vars and String === vars.first
          raise ArgumentError, "vars should be a Range of String"
        end
        @vars = vars
        @var = @vars.last.dup
        @table = ActiveSupport::Cache::MemoryStore.new
        @prefix = prefix
      end

      def var2id(var)
        @table.read(var)
      end

      def id2var(id)
        @table.read(id) || succ(id)
      end

      private

      def succ(id)
        @var.replace(@vars.first.dup) unless @vars.include?(@var.next!)
        var = @prefix + @var
        @table.delete(@table.read(var))
        @table.write(var, id)
        @table.write(id, var)
        var.dup
      end
    end
  end

  extend IdVar

  init do
    self.id_var ||= IdVar::Gen.new
  end
end
