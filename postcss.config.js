import { whitelist } from '@/utils/config/tailwind.js'

module.exports = {
  plugins: {
    tailwindcss: {},
    'vue-cli-plugin-tailwind/purgecss': {
      whitelist,
      css: ['src/assets/css/main.css']
    }
  }
}
