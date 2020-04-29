<template>
  <div class="flex flex-col mx-16 flex-grow">
    <SettingsCard class="col-start-3 row-start-4" />
  </div>
</template>

<script lang="ts">
import SettingsCard from '../components/SettingsCard.vue'
import { ipcRenderer } from 'electron'
import Vue from 'vue'
export default Vue.extend({
  components: {
    SettingsCard
  },
  data() {
    return {
      startDate: new Date(2020, 3, 1, 10, 10),
      endDate: new Date(2020, 3, 1, 10, 11)
    }
  }
})
</script>
