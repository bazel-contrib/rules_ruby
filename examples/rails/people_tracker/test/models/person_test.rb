require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    person = Person.new(first_name: "John", last_name: "Doe")
    assert person.valid?
  end

  test "full_name returns concatenated first and last name" do
    person = people(:john_doe)
    assert_equal "John Doe", person.full_name
  end

  test "full_name handles nil first_name" do
    person = Person.new(first_name: nil, last_name: "Doe")
    assert_equal "Doe", person.full_name
  end

  test "full_name handles nil last_name" do
    person = Person.new(first_name: "John", last_name: nil)
    assert_equal "John", person.full_name
  end

  test "full_name handles both names being nil" do
    person = Person.new(first_name: nil, last_name: nil)
    assert_equal "", person.full_name
  end

  test "full_name handles empty strings" do
    person = Person.new(first_name: "", last_name: "")
    assert_equal "", person.full_name
  end

  test "should have timestamps" do
    person = people(:john_doe)
    assert_not_nil person.created_at
    assert_not_nil person.updated_at
  end

  test "can create person with minimal attributes" do
    person = Person.create(first_name: "Test", last_name: "User")
    assert_not_nil person.id
    assert_equal "Test", person.first_name
    assert_equal "User", person.last_name
  end
end
