module WsdlMapper
  module Generation
    class DefaultFormatter
      def initialize io
        @io = io
        @i = 0
      end

      def next_statement
        append "\n"
      end

      def statement statement
        indent
        @io << statement
        next_statement
      end

      def require path
        # TODO: escape
        statement "require '#{path}'"
      end

      def attr_accessor *attrs
        # TODO: check/escape
        attrs = attrs.map { |a| ":#{a}" } * ", "
        statement "attr_accessor #{attrs}"
      end

      def begin_module name
        statement "module #{name}"
        inc_indent
      end

      def begin_class name
        statement "class #{name}"
        inc_indent
      end

      def begin_def name, args = []
        statement method_definition(name, args)
        inc_indent
      end

      def end
        dec_indent
        statement "end"
      end

      private
      def method_definition name, args
        s = "def #{name}"
        s << "(#{args * ', '})" unless args.empty?
        s
      end

      def append str
        @io << str
        self
      end

      def indent
        @io << "  " * @i
        self
      end

      def inc_indent n = 1
        @i += n
        self
      end

      def dec_indent n = 1
        @i -= n
        self
      end
    end
  end
end