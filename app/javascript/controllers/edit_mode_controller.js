import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "cell"]
  static values = { mode: Boolean }

  connect() {
    this.modeValue = false
    this.updateUI()
    this.updateCells()
  }

  toggle() {
    this.modeValue = !this.modeValue
    this.updateUI()
    this.updateCells()
  }

  updateUI() {
    this.buttonTarget.textContent = this.modeValue ? "Turn Edit Mode Off" : "Enable Edit Mode"
    // Note that toggle here is a from the DOM API, and is distinct from the above toggle defintion
    this.buttonTarget.classList.toggle("bg-yellow-100", this.modeValue)
    this.buttonTarget.classList.toggle("bg-blue-100", !this.modeValue)
  }

  updateCells() {
    this.cellTargets.forEach(cell => {
      const contentDiv = cell.querySelector("[data-cell-target='content']")
      contentDiv.setAttribute("contenteditable", this.modeValue.toString())
      
      // Dispatch custom event for drag controller
      const event = new CustomEvent("editModeChanged", {
        detail: { editMode: this.modeValue },
        bubbles: true
      })
      cell.dispatchEvent(event)
    })
  }
}
