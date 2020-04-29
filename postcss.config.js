/* eslint-disable @typescript-eslint/no-var-requires */
const { whitelist } = require('./src/utils/config/tailwind.js')

const purgecss = {
  // Specify the paths to all of the template files in your project.
  content: ['./public/**/*.html', './src/**/*.vue'],
  // Include any special characters you're using in this regular expression.
  // See: https://tailwindcss.com/docs/controlling-file-size/#understanding-the-regex
  defaultExtractor: (content) => content.match(/[\w-/:] (?<!:)/g) || [],
  // Whitelist auto generated classes for transitions and router links.
  // From: https://github.com/ky-is/vue-cli-plugin-tailwind
  whitelistPatterns: [
    /-(leave|enter|appear)(|-(to|from|active))$/,
    /^(?!(|.*?:)cursor-move). -move$/,
    /^router-link(|-exact)-active$/
  ],
  whitelist
}

module.exports = {
  plugins: {
    tailwindcss: {},
    'postcss-preset-env': {
      stage: 0
    },
    ...(process.env.NODE_ENV === 'production'
      ? {
          '@fullhuman/postcss-purgecss': purgecss
        }
      : {})
  }
}

// module.exports = {
//   plugins: {
//     tailwindcss: {},
//     'vue-cli-plugin-tailwind/purgecss': {
//       whitelist,
//       css: ['src/assets/css/main.css']
//     },
//     'postcss-preset-env': {
//       stage: 0
//     }
//   }
// }
