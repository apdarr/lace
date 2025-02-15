import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "dateInput", "distanceInput", "descriptionInput"]
  static values = {
    date: String,
    activity: Object,
    activityId: Number
  }

  connect() {
    console.log("Activity Modal Controller connected")
  }

  showModal(event) {
    event.preventDefault()
    const button = event.currentTarget
    // Set the activity ID from the button's dataset
    this.activityIdValue = button.dataset.activityModalActivityIdValue ? 
                           parseInt(button.dataset.activityModalActivityIdValue) : undefined
    console.log("Activity data:", button.dataset.activityModalActivityValue)
    
    try {
      const activityData = JSON.parse(button.dataset.activityModalActivityValue || '{}')
      console.log("Parsed activity data:", activityData)
      
      // Set form values
      this.dateInputTarget.value = button.dataset.activityModalDateValue
      this.distanceInputTarget.value = activityData.distance || ''
      this.descriptionInputTarget.value = activityData.description || ''
      
      this.modalTarget.classList.remove('hidden')
    } catch (error) {
      console.error("Error parsing activity data:", error)
    }
  }

  closeModal(event) {
    event?.preventDefault()
    this.modalTarget.classList.add('hidden')
  }

  async save(event) {
    event.preventDefault()
    const formData = {
      activity: {
        date: this.dateInputTarget.value,
        distance: this.distanceInputTarget.value,
        description: this.descriptionInputTarget.value,
        plan_id: this.element.dataset.planId
      }
    }

    const baseUrl = this.element.querySelector('[data-activity-modal-update-url]').dataset.activityModalUpdateUrl
    const url = this.activityIdValue ? `${baseUrl}/${this.activityIdValue}` : baseUrl
    const method = this.activityIdValue ? 'PATCH' : 'POST'

    try {
      const response = await fetch(url, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector("[name='csrf-token']").content,
          "Accept": "application/json"
        },
        body: JSON.stringify(formData)
      })

      if (response.ok) {
        const data = await response.json()
        // Update the cell content
        const cell = document.querySelector(`[data-date="${this.dateInputTarget.value}"]`)
        const contentDiv = cell.querySelector('.activity-content')
        contentDiv.innerHTML = `
          <div class="text-sm font-medium">${data.distance} miles</div>
          <div class="text-xs text-gray-600">${data.description}</div>
        `
        cell.classList.add('bg-blue-100')
        
        // Update the edit button with new activity data
        const button = cell.querySelector('button')
        button.dataset.activityModalActivityValue = JSON.stringify(data)
        button.dataset.activityModalActivityIdValue = data.id
        
        this.closeModal()
      }
    } catch (error) {
      console.error('Error saving activity:', error)
    }
  }
}
