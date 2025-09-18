import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    planId: Number, 
    status: String 
  }
  
  static targets = [
    "processing_indicator", 
    "calendar", 
    "actions",
    "status_text"
  ]

  connect() {
    if (this.statusValue === 'queued' || this.statusValue === 'processing') {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.pollInterval = setInterval(() => {
      this.checkStatus()
    }, 3000) // Poll every 3 seconds
  }

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
  }

  async checkStatus() {
    try {
      const response = await fetch(`/plans/${this.planIdValue}/processing_status.json`)
      const data = await response.json()
      
      this.updateUI(data.processing_status, data.activities_count)
      
      if (data.processing_status === 'completed' || data.processing_status === 'failed') {
        this.stopPolling()
        
        if (data.processing_status === 'completed') {
          // Reload the page to show the activities
          window.location.reload()
        } else {
          this.showError()
        }
      }
    } catch (error) {
      console.error('Error checking processing status:', error)
    }
  }

  updateUI(status, activitiesCount) {
    if (status === 'queued') {
      this.status_textTarget.textContent = 'Your training plan is queued for processing...'
    } else if (status === 'processing') {
      this.status_textTarget.textContent = 'Processing your training plan photos...'
    }
  }

  showError() {
    this.status_textTarget.textContent = 'There was an error processing your photos. Please try uploading them again.'
    this.status_textTarget.className += ' text-red-600'
  }
}