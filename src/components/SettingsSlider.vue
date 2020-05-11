<template>
  <div class="grid grid-cols-6 grid-rows-3 col-gap-2 mx-2">
    <p
      class="font-display col-span-6  mb-1 text-secondary-200"
      @click="focusOnInput(true)"
    >
      {{ name }}
    </p>

    <div
      class="col-span-1 row-span-1 flex bg-secondary-800 text-secondary-100 shadow-inner-1 rounded-full px-2"
    >
      <input
        ref="input"
        type="number"
        class="w-8 bg-transparent text-right pr-1"
        :max="max"
        :min="min"
        :value="floorValue"
        :step="step"
        @input="emitChange()"
        @blur="blurInput()"
      />
      <span @click="focusOnInput(true)">min.</span>
    </div>
    <input
      ref="input"
      type="range"
      class="bg-transparent col-span-5"
      :max="max"
      :min="min"
      :value="floorValue"
      :step="step"
      @input="emitChange()"
      @blur="blurInput()"
    />

    <p class="col-start-2 col-end-3 text-secondary-200">min</p>
    <p class="col-start-6 col-end-7 text-secondary-200">max</p>
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
  watch: {
    value() {
      this.setThumbPosition()
    },
    scale() {
      this.setThumbPosition()
    },
  },
  beforeMount() {
    this.setThumbPosition()
  },
  methods: {
    emitChange() {
      const input = this.$refs.input as HTMLInputElement
      this.validateInput(Number(input.value))
    },
    setThumbPosition() {
      // console.log(
      //   track,
      //   thumb,
      //   (this.value - this.min * this.scale) / this.max / this.scale
      // )
      // console.log(
      //   '---getThumbPosition START---',
      //   'value',
      //   this.value,
      //   'min',
      //   this.min,
      //   'max',
      //   this.max,
      //   'scale',
      //   this.scale
      // )

      const value = this.value
      const scale = this.scale
      const scaledMin = this.min * scale
      const scaledCenter = this.center * scale
      const scaledMax = this.max * scale

      const percentageFirstPart =
        ((value - scaledMin) / (scaledCenter - scaledMin)) * 100 || 0
      const percentageSecondPart =
        ((value - scaledCenter) / (scaledMax - scaledCenter)) * 100 || 0

      const percentage =
        scaledCenter < value
          ? percentageSecondPart / 2 + 50
          : percentageFirstPart / 2

      // console.log(
      //   'percentage',
      //   percentage,
      //   'percentageFirstPart',
      //   percentageFirstPart,
      //   'percentageSecondPart',
      //   percentageSecondPart
      // )

      this.thumbPosition = {
        left: `${percentage}%`,
        transform: `translate(-${percentage}%)`,
      }
    },
    async focusOnInput(allow: boolean) {
      if (!allow) return
      this.inputFocus = true
      await this.$nextTick()
      const input = this.$refs.input as HTMLInputElement
      if (input) {
        input.focus()
        this.setThumbPosition()
      }
    },
    async blurInput() {
      this.inputFocus = false
      await this.$nextTick()

      this.setThumbPosition()
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
