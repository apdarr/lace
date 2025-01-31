import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "dateInput", "activityInput"]

  connect() {
    // No need for delegated events anymore
  }

  showModal(event) {
    event.preventDefault()
    const cell = event.target.closest('[data-activity-cell]')
    if (!cell) return
    
    this.dateInputTarget.value = cell.dataset.date
    this.activityInputTarget.value = cell.querySelector('.activity-content').textContent || ''
    this.modalTarget.classList.remove('hidden')
  }

  closeModal(event) {
    event?.preventDefault()
    this.modalTarget.classList.add('hidden')
  }

  // Click outside modal to close
  clickOutside(event) {
    if (event.target === this.modalTarget) {
      this.closeModal()
    }
  }

  async save(event) {
    event.preventDefault()
    const date = this.dateInputTarget.value
    const content = this.activityInputTarget.value

    try {
      const response = await fetch(this.element.dataset.updateUrl, {
        method: 'PATCH',
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
