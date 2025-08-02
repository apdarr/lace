import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="workout-editor"
export default class extends Controller {
  connect() {
    this.addKeyboardShortcuts()
  }

  addKeyboardShortcuts() {
    this.element.addEventListener("keydown", (event) => {
      // Save with Ctrl+S or Cmd+S
      if ((event.ctrlKey || event.metaKey) && event.key === "s") {
        event.preventDefault()
        this.saveWorkouts()
      }
    })
  }

  saveWorkouts() {
    const submitButton = this.element.querySelector('input[type="submit"]')
    if (submitButton) {
      submitButton.click()
    }
  }

  // Auto-suggest common workout descriptions
  suggestDescription(event) {
    const input = event.target
    const value = input.value.toLowerCase()
    
    const suggestions = [
      "Easy run",
      "Rest day",
      "Tempo run", 
      "Long run",
      "Interval training",
      "Cross training",
      "Recovery run",
      "Speed work",
      "Hill repeats",
      "Fartlek"
    ]
    
    // Simple auto-complete logic could be added here
    // For now, just ensure proper capitalization
    if (value && !value.match(/^[A-Z]/)) {
      input.value = value.charAt(0).toUpperCase() + value.slice(1)
    }
  }
}