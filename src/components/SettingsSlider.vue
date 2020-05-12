<template>
  <div class="grid col-gap-2 mx-2">
    <p
      class="font-display col-span-6  mb-1 text-secondary-200"
      @click="focusOnInput(true)"
    >
      {{ name }}
    </p>

    <div
      class="col-span-1 row-span-1  cursor-text flex bg-primary-700 hover:bg-primary-800 focus-within:bg-primary-800 text-secondary-100 shadow-inner-1 rounded-full px-2"
      @click="focusOnInput(true)"
    >
      <input
        ref="input"
        type="number"
        class="w-8 bg-transparent selection-darker outline-none text-right pr-1"
        :max="max"
        :min="min"
        :value="floorValue"
        :step="step"
        @input="emitChange()"
        @blur="blurInput()"
      />
      <span class="selection-darker">{{ suffix }}</span>
    </div>
    <input
      type="range"
      class="bg-transparent col-span-5"
      :max="max"
      :min="min"
      :value="floorValue"
      :step="step"
      tabindex="-1"
      @input="emitChange()"
      @blur="blurInput()"
    />

    <p class="col-start-2 col-end-4 text-secondary-200">
      {{ min }} {{ suffix }}
    </p>
    <p class="col-start-4 col-end-7 text-right text-secondary-200">
      {{ max }} {{ suffix }}
    </p>
    <p v-if="warning" class="text-sm bg-warn-400 mt-2 px-2 py-1">
      {{ warning }}
    </p>
  </div>
</template>

<script lang="ts">
import Vue, { PropType } from 'vue'
export default Vue.extend({
  props: {
    value: {
      type: Number,
      required: true,
    },
    max: {
      type: Number,
      required: true,
    },
    center: {
      type: Number,
      required: true,
    },
    min: {
      type: Number,
      required: true,
    },
    scale: {
      type: Number,
      default: 1,
    },
    step: {
      type: Number,
      default: 1,
    },
    additionalValidator: {
      type: Function as PropType<(value: number) => boolean>,
      default: () => () => true,
    },
    suffix: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      thumbPosition: { left: '50%', transform: `translate(-50%)` },
      inputFocus: false,
      warning: '',
      mouseDownTabFocusProtected: false,
    }
  },
  computed: {
    floorValue(): number {
      return Math.floor(this.value / this.scale)
    },
    inputLength(): number {
      return this.floorValue.toString().length
    },
  },
  methods: {
    emitChange() {
      const input = this.$refs.input as HTMLInputElement
      this.validateInput(Number(input.value))
    },

    async focusOnInput(allow: boolean) {
      if (!allow) return
      this.inputFocus = true
      await this.$nextTick()
      const input = this.$refs.input as HTMLInputElement
      if (input) {
        input.focus()
      }
    },
    async blurInput() {
      this.inputFocus = false
      await this.$nextTick()

      this.warning = ''
    },
    validateInput(value: number) {
      const { min, max, suffix, scale } = this
      if (value < min)
        return (this.warning = `You can't set less than ${min} ${suffix}`)
      if (value > max)
        return (this.warning = `You can't set more than ${max} ${suffix}`)

      console.log(
        'value',
        value,
        'scale',
        scale,
        '(value * scale)',
        value * scale,
        '(value * scale) % scale',
        (value * scale) % scale
      )
      const customValidatorResult = this.additionalValidator(value)
      if (typeof customValidatorResult === 'string')
        return (this.warning = customValidatorResult)
      this.$emit('input', value * scale)
      this.warning = ''
    },
  },
})
</script>
