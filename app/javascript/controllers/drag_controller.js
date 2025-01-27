import { Controller } from "@hotwired/stimulus"
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = ["container", "item"]

  connect() {
    this.initializeSortable()
  }

  initializeSortable() {
    this.sortable = new Sortable(this.containerTarget, {
      animation: 150,
      draggable: "[data-drag-target='item']",
      group: "shared",
      filter: "[contenteditable]", // Prevent drag when clicking editable content
      onStart: (evt) => {
        // Blur any active contenteditable when starting drag
        document.activeElement.blur()
        evt.item.classList.add('scale-105', 'shadow-lg', 'bg-green-100', 'border-2', 'border-green-400')
      },
      onEnd: (evt) => {
        evt.item.classList.remove('scale-105', 'shadow-lg', 'bg-green-100', 'border-2', 'border-green-400')
        evt.item.classList.add('animate-bounce')
        setTimeout(() => {
          evt.item.classList.remove('animate-bounce')
        }, 500)
        this.handleDragEnd(evt)
      }
    })
  }

  handleDragEnd(event) {
    // You can add logic here to handle the new position
    const itemDate = event.item.dataset.date
    const newIndex = event.newIndex
    
    console.log(`Item from ${itemDate} moved to position ${newIndex}`)
    // Add AJAX call here if you need to persist the changes
  }
}