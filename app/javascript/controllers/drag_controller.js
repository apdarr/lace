import { Controller } from "@hotwired/stimulus"
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = ["container", "item"]

  connect() {
    this.sortableInstances = []
    this.containerTargets.forEach(container => {
      this.sortableInstances.push(this.initializeSortable(container))
    })

    // Listen for edit mode changes
    this.element.addEventListener("editModeChanged", (event) => {
      this.sortableInstances.forEach(instance => {
        instance.option("disabled", event.detail.editMode)
      })
    })
  }

  initializeSortable(container) {
    return new Sortable(container, {
      animation: 150,
      draggable: "[data-drag-target='item']",
      group: {
        name: 'shared',
        pull: true,
        put: (to, from) => {
          // Only allow drops if the target container has less than 7 items
          return to.el.children.length < 7
        }
      },
      filter: "[contenteditable]",
      onStart: (evt) => {
        document.activeElement.blur()
        evt.item.classList.add('scale-105', 'shadow-lg', 'bg-green-100', 'border-2', 'border-green-400')
      },
      onEnd: (evt) => {
        evt.item.classList.remove('scale-105', 'shadow-lg', 'bg-green-100', 'border-2', 'border-green-400')
        
        // If the target container now has more than 7 items, move the item back
        if (evt.to.children.length > 7) {
          evt.from.appendChild(evt.item)
          return
        }
        
        evt.item.classList.add('animate-bounce')
        setTimeout(() => {
          evt.item.classList.remove('animate-bounce')
        }, 500)
        this.handleDragEnd(evt)
      }
    })
  }

  handleDragEnd(event) {
    const itemDate = event.item.dataset.date
    const newIndex = event.newIndex
    const weekContainer = event.to
    
    console.log(`Item from ${itemDate} moved to position ${newIndex} in week ${weekContainer.dataset.week}`)
  }
}