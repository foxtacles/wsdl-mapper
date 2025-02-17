require 'test_helper'

require 'wsdl_mapper/type_mapping/decimal'

module TypeMappingTests
  class DecimalTest < ::WsdlMapperTesting::Test
    include WsdlMapper::TypeMapping

    def test_to_ruby
      assert_equal BigDecimal.new('-123.45'), Decimal.to_ruby('-123.45')
    end

    def test_to_xml
      assert_equal '-123.45', Decimal.to_xml(BigDecimal.new('-123.45'))
    end

    def test_ruby_type
      assert_equal BigDecimal, Decimal.ruby_type
    end
  end
end
