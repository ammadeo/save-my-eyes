<template>
  <div class="flex flex-col mx-16 flex-grow">
    <transition>
      <SettingsContent closeable class="col-start-3 row-start-4" />
    </transition>
  </div>
</template>

<script lang="ts">
import SettingsContent from '../components/SettingsContent.vue'
// import { ipcRenderer } from 'electron'
import Vue from 'vue'
export default Vue.extend({
  components: {
    SettingsContent
  },
  data() {
    return {
      startDate: new Date(2020, 3, 1, 10, 10),
      endDate: new Date(2020, 3, 1, 10, 11)
    }
  },
  mounted() {
    // window.resizeTo()
  }
})
</script>
