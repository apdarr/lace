import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="plan-view-toggle"
export default class extends Controller {
  static targets = ["monthView", "weekView", "monthBtn", "weekBtn"]
  static values = { currentView: { type: String, default: "month" } }

  connect() {
    this.updateButtons()
  }

  showMonth() {
    this.currentViewValue = "month"
    this.updateButtons()
    this.updateViews()
  }

  showWeek() {
    this.currentViewValue = "week"
    this.updateButtons()
    this.updateViews()
  }

  updateButtons() {
    if (this.hasMonthBtnTarget && this.hasWeekBtnTarget) {
      this.monthBtnTarget.classList.toggle('nav-pill-active', this.currentViewValue === 'month')
      this.weekBtnTarget.classList.toggle('nav-pill-active', this.currentViewValue === 'week')
    }
  }

  updateViews() {
    if (this.hasMonthViewTarget && this.hasWeekViewTarget) {
      this.monthViewTarget.classList.toggle('hidden', this.currentViewValue !== 'month')
      this.weekViewTarget.classList.toggle('hidden', this.currentViewValue !== 'week')
    }
  }
}