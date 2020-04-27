<template>
  <div class="flex flex-col mx-16 flex-grow">
    <SettingsCard class="col-start-3 row-start-4" />
  </div>
</template>

<script>
import SettingsCard from '../components/SettingsCard.vue'
import { ipcRenderer } from 'electron'
export default {
  components: {
    SettingsCard,
  },
  asyncData({ req }) {
    return {
      name: process.static ? 'static' : process.server ? 'server' : 'client',
    }
  },
  data() {
    return {
      startDate: new Date(2020, 3, 1, 10, 10),
      endDate: new Date(2020, 3, 1, 10, 11),
    }
  },
  mounted() {
    ipcRenderer.on('console', (data) =>
      console.log('log from background', data)
    )
  },
}
</script>
