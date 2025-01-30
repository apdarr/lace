require "application_system_test_case"

class PlansTest < ApplicationSystemTestCase
  setup do
    @plan = plans(:one)
  end

  test "visiting the index" do
    visit plans_url
    assert_selector "h1", text: "Plans"
  end

  test "should create plan" do
    visit plans_url
    click_on "New plan"

    fill_in "Length", with: @plan.length
    fill_in "Race date", with: @plan.race_date
    click_on "Create Plan"

    assert_text "Plan was successfully created"
    click_on "Back"
  end

  test "should update Plan" do
    visit plan_url(@plan)
    click_on "Edit this plan", match: :first

    fill_in "Length", with: @plan.length
    fill_in "Race date", with: @plan.race_date
    click_on "Update Plan"

    assert_text "Plan was successfully updated"
    click_on "Back"
  end

  test "should show Plan" do
    visit plan_url(@plan)
    assert_text "Length"

    # Verify calendar elements
    assert_selector "div[data-controller='edit-mode']"
    assert_selector "button[data-edit-mode-target='button']", text: "Enable Edit Mode"

    # Verify calendar grid headers
    assert_selector "div.font-semibold", text: "M"
    assert_selector "div.font-semibold", text: "Tu"
    assert_selector "div.font-semibold", text: "W"
    assert_selector "div.font-semibold", text: "Th"
    assert_selector "div.font-semibold", text: "F"
    assert_selector "div.font-semibold", text: "Sa"
    assert_selector "div.font-semibold", text: "Su"

    # Verify calendar cells exist
    assert_selector "div[data-drag-target='container']"
    assert_selector "div[data-cell-target='wrapper']"
    assert_selector "div[data-cell-target='content']"
  end

  test "should destroy Plan" do
    visit plan_url(@plan)
    click_on "Destroy this plan", match: :first

    assert_text "Plan was successfully destroyed"
  end
end
