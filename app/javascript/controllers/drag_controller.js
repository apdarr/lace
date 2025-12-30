import { Controller } from "@hotwired/stimulus"
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = ["container", "item"]

  connect() {
    console.log('Drag controller connected')
    
    if (this.hasContainerTarget) {
      this.containerTargets.forEach(container => {
        this.initializeSortable(container)
      })
    }
  }

  initializeSortable(container) {
    console.log('Initializing sortable for:', container)
    
    return new Sortable(container, {
      group: 'workouts', // Allow moving between different day containers
      animation: 150,
      draggable: '[data-drag-target="item"]',
      handle: '.cursor-grab',
      delay: 100,
      delayOnTouchOnly: true,
      touchStartThreshold: 5,
      forceFallback: true,
      fallbackClass: 'opacity-50',
      onStart: (evt) => {
        console.log('Drag started')
        evt.item.classList.add('scale-105', 'shadow-lg', 'ring-2', 'ring-blue-400')
        // Highlight all drop zones
        document.querySelectorAll('[data-drag-target="container"]').forEach(zone => {
          zone.classList.add('border-blue-300', 'bg-blue-50/50')
        })
      },
      onEnd: (evt) => {
        console.log('Drag ended')
        evt.item.classList.remove('scale-105', 'shadow-lg', 'ring-2', 'ring-blue-400')
        // Remove highlight from all drop zones
        document.querySelectorAll('[data-drag-target="container"]').forEach(zone => {
          zone.classList.remove('border-blue-300', 'bg-blue-50/50')
        })
        
        // Update placeholders for both source and destination containers
        this.updatePlaceholder(evt.to)
        this.updatePlaceholder(evt.from)
        
        // Update the activity's date based on which day container it was dropped into
        const newDay = evt.to.dataset.day
        const activityId = evt.item.dataset.activityId
        
        if (newDay && activityId) {
          console.log(`Moving activity ${activityId} to ${newDay}`)
          
          // Get CSRF token
          const csrfToken = document.querySelector("meta[name='csrf-token']").content
          
          fetch(`/activities/${activityId}`, {
            method: 'PATCH',
            headers: { 
              'Content-Type': 'application/json',
              'X-CSRF-Token': csrfToken,
              'Accept': 'application/json'
            },
            body: JSON.stringify({ activity: { start_date_local: newDay } })
          })
          .then(response => {
            if (response.ok) {
              console.log('Activity updated successfully')
            } else {
              console.error('Failed to update activity')
              // Ideally revert the drag here if it failed
            }
          })
        }
      }
    })
  }

  updatePlaceholder(container) {
    const placeholder = container.querySelector('.placeholder-message')
    if (placeholder) {
      // Check if there are any draggable items in the container
      const hasItems = container.querySelectorAll('[data-drag-target="item"]').length > 0
      if (hasItems) {
        placeholder.classList.add('hidden')
      } else {
        placeholder.classList.remove('hidden')
      }
    }
  }
}