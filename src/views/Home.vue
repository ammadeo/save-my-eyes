<template>
  <div class="home">
    <img alt="Vue logo" src="../assets/logo.png" />
    <HelloWorld msg="Welcome to Your Vue.js App" />
  </div>
</template>

<script lang="ts">
// @ is an alias to /src
import HelloWorld from "@/components/HelloWorld.vue";

import Vue from 'vue'; export default Vue.extend({
  name: "Home",
  components: {
    HelloWorld
  }
};
</script>
