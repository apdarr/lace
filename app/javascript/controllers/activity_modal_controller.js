import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "dateInput", "activityInput"]
  static values = {
    date: String
  }

  connect() {
    console.log("dateValue is ⭐", this.dateValue)
  }

  showModal(event) {
    event.preventDefault()
    const cell = event.target.closest('[data-activity-cell]')
    
    // Debug cell object
    console.log("1. Full cell object:", cell)
    console.log("2. cell.dataset:", cell.dataset)
    console.log("3. cell.dataset.date:", cell.dataset.date)
    
    // Debug dateInputTarget
    console.log("4. this.dateInputTarget:", this.dateInputTarget)
    
    if (!cell) return
    
    this.dateInputTarget.value = cell.dataset.date
    console.log("5. Final dateInputTarget.value:", this.dateInputTarget.value)
    
    this.activityInputTarget.value = cell.querySelector('.activity-content').textContent || ''
    this.modalTarget.classList.remove('hidden')
  }

  closeModal(event) {
    event?.preventDefault()
    this.modalTarget.classList.add('hidden')
  }

  async save(event) {
    event.preventDefault()
    const date = this.dateInputTarget.value
    const content = this.activityInputTarget.value
    const url = this.element.querySelector('[data-activity-modal-update-url]').dataset.activityModalUpdateUrl
    console.log("url is ⭐", url)

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector("[name='csrf-token']").content,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          activity: {
            content: content,
            date: date
          }
        })
      })

      if (response.ok) {
        const data = await response.json()
        const cell = document.querySelector(`[data-date="${date}"]`)
        cell.querySelector('.activity-content').textContent = content
        this.closeModal()
      }
    } catch (error) {
      console.error('Error saving activity:', error)
    }
  }
}
