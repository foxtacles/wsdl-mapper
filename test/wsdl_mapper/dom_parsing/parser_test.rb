require 'test_helper'

require 'wsdl_mapper/dom_parsing/parser'

module SchemaTests
  class ParserTest < WsdlMapperTesting::Test
    include WsdlMapper::DomParsing
    include WsdlMapper::Dom

    def test_raise_error_on_invalid_root_node
      assert_raises(Parser::InvalidRootException) { TestHelper.parse_schema 'basic_note_type_with_an_invalid_root_node.xsd' }
    end

    def test_raise_error_on_invalid_root_ns
      assert_raises(Parser::InvalidNsException) { TestHelper.parse_schema 'basic_note_type_with_invalid_xsd_namespace.xsd' }
    end

    def test_raise_error_on_invalid_root_ns_2
      assert_raises(Parser::InvalidNsException) { TestHelper.parse_schema 'basic_note_type_with_missing_xsd_namespace.xsd' }
    end

    def test_example_1_complex_type
      schema = TestHelper.parse_schema 'basic_note_type.xsd'

      assert_equal 1, schema.types.count

      type = schema.each_type.first

      assert_kind_of ComplexType, type
      assert_equal Name.get(nil, 'noteType'), type.name

      refute_nil type.documentation
    end

    def test_root_element
      schema = TestHelper.parse_schema 'basic_note_type_with_element.xsd'

      assert_equal 1, schema.elements.count

      type = schema.each_type.first
      element = schema.each_element.first

      assert_kind_of Element, element
      assert_equal Name.get(nil, 'note'), element.name
      assert_equal Name.get(nil, 'noteType'), element.type_name
      assert_equal type, element.type

      refute_nil element.documentation
    end

    def test_example_with_soap_array
      schema = TestHelper.parse_schema 'basic_note_type_with_soap_array.xsd'

      assert_equal 3, schema.types.count

      array_type = schema.each_type.to_a.last

      assert_equal Name.get(nil, 'attachmentsArray'), array_type.name
      assert_equal Name.get(nil, 'attachment'), array_type.soap_array_type_name
    end

    def test_example_2_complex_type_w_documentation
      schema = TestHelper.parse_schema 'basic_note_type_with_documentation_and_bounds.xsd'
      type = schema.each_type.first

      assert_equal 'This is some documentation for type.', type.documentation.default
    end

    def test_example_1_properties_sequence
      schema = TestHelper.parse_schema 'basic_note_type.xsd'
      type = schema.each_type.first

      assert_equal 4, type.properties.count

      props = type.properties.values

      prop_names = props.map { |p| p.name.name }
      assert_includes prop_names, 'to'
      assert_includes prop_names, 'from'
      assert_includes prop_names, 'heading'
      assert_includes prop_names, 'body'

      assert_equal 0, props[0].sequence
      assert_equal 1, props[1].sequence
      assert_equal 2, props[2].sequence
      assert_equal 3, props[3].sequence

      props.each do |prop|
        assert_equal 1, prop.bounds.min
        assert_equal 1, prop.bounds.max
      end
    end

    def test_example_2_unbounded_property
      schema = TestHelper.parse_schema 'basic_note_type_with_documentation_and_bounds.xsd'
      type = schema.each_type.first

      prop = type.properties.values.first

      assert_equal 1, prop.bounds.min
      assert_nil prop.bounds.max
    end

    def test_example_2_optional_property
      schema = TestHelper.parse_schema 'basic_note_type_with_documentation_and_bounds.xsd'
      type = schema.each_type.first

      prop = type.properties.values[2]

      assert_equal 0, prop.bounds.min
      assert_equal 1, prop.bounds.max
    end

    def test_example_2_property_wo_documentation
      schema = TestHelper.parse_schema 'basic_note_type_with_documentation_and_bounds.xsd'
      type = schema.each_type.first

      prop = type.properties.values[1]

      refute_nil prop.documentation
      assert_nil prop.documentation.default
    end

    def test_example_2_property_w_documentation
      schema = TestHelper.parse_schema 'basic_note_type_with_documentation_and_bounds.xsd'
      type = schema.each_type.first

      prop = type.properties.values[3]

      assert_equal 'This is some documentation.', prop.documentation.default

      app_info = 'This is some appinfo.<link>http://example.com</link>'
      assert_equal app_info, prop.documentation.app_info
    end

    def test_example_4_simple_enum
      schema = TestHelper.parse_schema 'address_type_enumeration.xsd'
      type = schema.each_type.first

      assert_instance_of SimpleType, type

      base_type = schema.get_type Name.get(Xsd::NS, 'token')

      assert_equal base_type, type.base

      assert_equal 2, type.enumeration_values.count

      expected_enums = [EnumerationValue.new('ship'), EnumerationValue.new('bill')]
      assert_includes expected_enums, type.enumeration_values.first
      assert_includes expected_enums, type.enumeration_values.last
    end

    def test_example_5_complex_type_simple_content
      schema = TestHelper.parse_schema 'simple_money_type_with_currency_attribute.xsd'
      type = schema.each_type.first

      assert_instance_of ComplexType, type
      assert type.simple_content?

      base_type = schema.get_type Name.get(Xsd::NS, 'float')

      assert_equal base_type, type.base

      attr = type.attributes.values.first
      assert_equal Name.get(nil, 'currency'), attr.name
    end

    def test_example_6_complex_type_properties_all
      schema = TestHelper.parse_schema 'basic_credentials_type.xsd'
      type = schema.each_type.first

      assert_equal 2, type.properties.count

      props = type.properties.values

      user_name_prop = props.first
      assert_equal 'userName', user_name_prop.name.name
      assert_equal 1, user_name_prop.bounds.min
      assert_equal 1, user_name_prop.bounds.max

      password_prop = props.last
      assert_equal 'password', password_prop.name.name
      assert_equal 0, password_prop.bounds.min
      assert_equal 1, password_prop.bounds.max
    end

    def test_importing_schemas
      schema = TestHelper.parse_schema 'basic_note_type_with_import.xsd'

      assert_equal 1, schema.imports.count
      assert_equal 2, schema.each_type.count
    end

    def test_example_3_simple_extension
      schema = TestHelper.parse_schema 'basic_note_type_and_fancy_note_type_extension.xsd'

      assert_equal 2, schema.types.count

      base_type = schema.each_type.first
      extended_type = schema.each_type.to_a.last

      assert_equal Name.get(nil, 'noteType'), base_type.name
      assert_equal Name.get(nil, 'fancyNoteType'), extended_type.name
      assert_equal base_type, extended_type.base

      assert_equal 1, extended_type.properties.count
    end

    def test_example_3_simple_extension_with_ns
      schema = TestHelper.parse_schema 'basic_note_type_and_fancy_note_type_extension_with_namespace.xsd'
      ns = 'example.org/example_3'

      assert_equal ns, schema.target_namespace

      assert_equal 2, schema.each_type.count

      base_type = schema.each_type.first
      extended_type = schema.each_type.to_a.last

      assert_equal Name.get(ns, 'noteType'), base_type.name
      assert_equal Name.get(ns, 'fancyNoteType'), extended_type.name
      assert_equal base_type, extended_type.base

      assert_equal 1, extended_type.properties.count
      prop = extended_type.properties.values.first

      assert_equal 'attachments', prop.name.name
    end

    def test_ref_attribute
      schema = TestHelper.parse_schema 'basic_note_type_with_ref_attribute.xsd'

      assert_equal 1, schema.each_attribute.count
      attr = schema.each_attribute.first

      assert_equal Name.get(nil, 'uuid'), attr.name

      type = schema.each_type.first

      assert_equal 1, type.each_attribute.count
      assert_equal [attr], type.each_attribute.to_a
    end

    def test_inline_complex_type
      schema = TestHelper.parse_schema 'basic_note_type_with_inline_complex_type.xsd'

      assert_equal 2, schema.each_type.count

      note_type = schema.each_type.first
      inline_type = schema.each_type.to_a.last

      assert_equal 5, note_type.each_property.count

      prop = note_type.each_property.to_a.last
      assert_equal inline_type, prop.type
      assert_equal prop, inline_type.containing_property
    end

    def test_inline_simple_type
      schema = TestHelper.parse_schema 'basic_note_type_with_inline_simple_type.xsd'

      assert_equal 2, schema.each_type.count

      note_type = schema.each_type.first
      inline_type = schema.each_type.to_a.last

      assert_equal 5, note_type.each_property.count

      prop = note_type.each_property.to_a.last
      assert_equal inline_type, prop.type
      assert_equal prop, inline_type.containing_property
    end

    def test_element_inline_complex_type
      schema = TestHelper.parse_schema 'basic_note_type_with_element_inline_complex_type.xsd'

      assert_equal 1, schema.each_type.count

      note_type = schema.each_type.first
      element = schema.each_element.first

      refute_nil element.type
      assert_equal note_type, element.type
      assert_equal element, note_type.containing_element
    end

    def test_element_inline_simple_type
      schema = TestHelper.parse_schema 'element_inline_simple_type.xsd'

      assert_equal 1, schema.each_type.count

      note_type = schema.each_type.first
      element = schema.each_element.first

      refute_nil element.type
      assert_equal note_type, element.type
      assert_equal element, note_type.containing_element
    end
  end
end
