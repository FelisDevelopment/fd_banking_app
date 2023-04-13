import { createPinia } from "pinia";
import { createApp } from "vue";
import "./style.css";
import App from "./App.vue";
import { EventBus } from "./event-bus";

import "./string.extension";

const app = createApp(App).use(createPinia());

window.addEventListener("message", (event) => {
  EventBus.emit(event.data.action, event.data.data || {});
});

app.mount("#app");
