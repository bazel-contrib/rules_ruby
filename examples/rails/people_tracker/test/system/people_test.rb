require "application_system_test_case"

class PeopleTest < ApplicationSystemTestCase
  setup do
    @john_doe = people(:john_doe)
  end

  test "visiting the index" do
    visit people_url
    assert_selector "h1", text: "People"
  end

  test "should create person" do
    visit people_url
    click_on "New person"

    fill_in "First name", with: "Bob"
    fill_in "Last name", with: "Smith"
    click_on "Create Person"

    assert_text "Person was successfully created"
    click_on "Back"
  end

  test "should update Person" do
    visit person_url(@john_doe)
    click_on "Edit this person", match: :first

    fill_in "First name", with: @john_doe.first_name + "Suffix"
    fill_in "Last name", with: @john_doe.last_name + "Another"
    click_on "Update Person"

    assert_text "Person was successfully updated"
    click_on "Back"
  end

  test "should destroy Person" do
    visit person_url(@john_doe)
    accept_confirm { click_on "Destroy this person", match: :first }

    assert_text "Person was successfully destroyed"
  end
end
