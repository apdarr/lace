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

    # Only fill in race_date as that's the main field we need
    fill_in "plan[race_date]", with: @plan.race_date
    click_on "Create Plan"

    assert_text "Plan was successfully created"
  end

  test "should update Plan" do
    visit plan_url(@plan)
    click_on "Edit this plan", match: :first

    fill_in "plan[race_date]", with: @plan.race_date + 1.week
    click_on "Update Plan"

    assert_text "Plan was successfully updated"
  end

  test "should show Plan" do
    visit plan_url(@plan)

    # Verify calendar components exist
    assert_selector ".grid-cols-8" # Main calendar grid
    assert_selector "[data-activity-cell]" # Activity cells

    # Verify calendar headers
    assert_text "Week"
    assert_text "M"
    assert_text "Tu"
    assert_text "W"
    assert_text "Th"
    assert_text "F"
    assert_text "Sa"
    assert_text "Su"
  end

  test "should destroy Plan" do
    visit plan_url(@plan)
    click_on "Destroy this plan", match: :first
    assert_text "Plan was successfully destroyed"
  end
end
