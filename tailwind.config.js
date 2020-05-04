/* eslint-disable @typescript-eslint/no-var-requires */
const { colors } = require('tailwindcss/defaultTheme')
const plugin = require('tailwindcss/plugin')
/*
 ** TailwindCSS Configuration File
 **
 ** Docs: https://tailwindcss.com/docs/configuration
 ** Default: https://github.com/tailwindcss/tailwindcss/blob/master/stubs/defaultConfig.stub.js
 */

// const cardBottomMargin = 'spacing.2'

module.exports = {
  theme: {
    colors: {
      black: colors.black,
      white: colors.white,
      gray: colors.gray,
      transparent: colors.transparent,
      warn: colors.orange,
      secondary: {
        50: '#f5faff',
        ...colors.indigo,
        1000: '#28276b',
      },
      primary: colors.orange,
    },
    fontFamily: {
      display: ['Oxanium', 'roboto', 'sans-serif'],
      body: ['Source Sans Pro', 'roboto', 'sans-serif'],
    },
    fontWeight: {
      normal: 400,
      bold: 600,
    },
    borderWidth: {
      default: '1px',
      '0': '0',
      '2': '2px',
      '4': '4px',
      '6': '6px',
      '8': '8px',
    },
    gridTemplateColumns: {
      base:
        'minmax(min-content, 3fr) minmax(2rem, 4rem) minmax(min-content, 1fr)',
    },
    gridTemplateRows: {
      base: 'auto auto 1fr auto auto',
    },
    extend: {
      translate: (theme) => ({
        '-card-40': `calc(${theme('spacing.40')} - ${theme(
          'spacing.2'
        )} - 100%)`,
        '-card-48': `calc(${theme('spacing.48')} - ${theme(
          'spacing.2'
        )} - 100%)`,
        '-card-56': `calc(${theme('spacing.56')} - ${theme(
          'spacing.2'
        )} - 100%)`,
        '-card-64': `calc(${theme('spacing.64')} - ${theme(
          'spacing.2'
        )} - 100%)`,
      }),
      minHeight: (theme) => ({
        12: theme('spacing.12'),
      }),
      maxHeight: (theme) => ({
        'screen-card': `calc(100vh - ${theme('spacing.2')} * 2)`,
      }),
      borderRadius: {
        inherit: 'inherit',
      },
      boxShadow: (theme) => ({
        'inner-1': `inset 0 -${theme('spacing.px')} ${theme(
          'spacing.1'
        )} 0 rgba(0, 0, 0, 0.2)`,
      }),
    },
  },
  variants: {
    borderWidth: ['responsive', 'hover', 'focus', 'active'],
    overflow: [
      'responsive',
      'hover',
      'focus',
      // 'focus-within'
    ],
    textTransform: ['first-letter'],
    translate: [
      'responsive',
      'hover',
      'focus',
      'active',
      'group-active',
      // 'focus-within',
      // todo fix focus within or add support by js
    ],
    backgroundColor: [
      'responsive',
      'hover',
      'focus',
      'group-hover',
      'group-focus',
    ],
  },
  plugins: [
    require('tailwindcss-interaction-variants'),
    plugin(function({ addVariant, e }) {
      addVariant('first-letter', ({ modifySelectors, separator }) => {
        modifySelectors(({ className }) => {
          return `.${e(`first-letter${separator}${className}`)}::first-letter`
        })
      })
    }),
  ],
  corePlugins: {},
}
