<script setup lang="ts">
// Placeholder shell for the Phase 0 spike. The Vue 2 renderer in legacy-electron/src is being ported here.
import { ref } from "vue";

const route = ref(location.hash);
window.addEventListener("hashchange", () => (route.value = location.hash));
</script>

<template>
  <main v-if="route === '#/menu'" class="page menu">
    <h1>Menu</h1>
    <p>Save My Eyes</p>
  </main>
  <main v-else class="page cover">
    <h1>BREAK</h1>
  </main>
</template>

<style>
html,
body {
  margin: 0;
  height: 100%;
  overflow: hidden;
  background: #121959;
  font-family: system-ui, sans-serif;
}
.page {
  height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #fff;
}
.cover h1 {
  margin: 0;
  font-size: 12rem;
  letter-spacing: 0.1em;
}
.menu {
  /* Overlay title bar: the native traffic lights sit on top of this page. */
  justify-content: flex-start;
  padding-top: 64px;
  box-sizing: border-box;
  background: #f4f4f8;
  color: #121959;
}
.menu h1 {
  margin: 0;
  font-size: 3rem;
}
</style>
