import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selector", "week"]

  connect() {
    console.log('Week selector controller connected')
    this.showInitialWeek()
  }

  showInitialWeek() {
    // Show week 0 by default
    this.showWeek(0)
  }

  selectorChanged(event) {
    const selectedWeek = parseInt(event.target.value)
    this.showWeek(selectedWeek)
  }

  showWeek(weekNumber) {
    // Hide all week views
    this.weekTargets.forEach(weekView => {
      weekView.classList.add('hidden')
    })
    
    // Show the selected week
    const selectedWeekView = this.weekTargets.find(weekView => 
      parseInt(weekView.dataset.week) === weekNumber
    )
    
    if (selectedWeekView) {
      selectedWeekView.classList.remove('hidden')
      console.log(`Showing week ${weekNumber}`)
    } else {
      console.warn(`Week ${weekNumber} not found`)
    }
  }
}