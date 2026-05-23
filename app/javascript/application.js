import "@hotwired/turbo-rails"
Turbo.session.drive = false
import { Application } from "@hotwired/stimulus"
 
import * as bootstrap from "bootstrap"
import SlimSelect from "slim-select"
import "@rails/ujs"
import Rails from "@rails/ujs"
import feather from 'feather-icons'


const application = Application.start()
window.Stimulus = application
window.bootstrap = bootstrap
window.SlimSelect = SlimSelect

Rails.start()

document.addEventListener("turbo:load", () => {
  feather.replace();
});

console.log("✅ Stimulus initialized")
