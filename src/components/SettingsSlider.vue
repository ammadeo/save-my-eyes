<template>
  <div class="flex flex-col">
    <p class="font-display text-center mx-2 mb-1">{{ name }}</p>
    <div class="flex flex-wrap relative mx-2">
      <div
        ref="track"
        class="w-full self-center cursor-pointer h-2 absolute bg-secondary-100 rounded-full"
      />
      <BaseTile
        ref="thumb"
        class="flex justify-center z-10 px-2 origin-center relative"
        :elevation="2"
        :style="thumbPosition"
      >
        <p
          class="text-secondary-50 cursor-pointer"
          tabindex="0"
          @dblclick="focusOnInput(true)"
          @focus="focusOnInput(!mouseDownTabFocusProtected)"
          @mousedown="mouseDownTabFocusProtected = true"
          @mouseup="mouseDownTabFocusProtected = false"
        >
          <!-- // ! fix scale issue 
        // ? maybe change it to be multiplayer not divider  -->
          <input
            v-if="inputFocus"
            ref="input"
            type="number"
            class="w-6 bg-transparent"
            :class="{ 'w-8': inputLength === 2, 'w-10': inputLength >= 3 }"
            :max="max"
            :min="min"
            :value="floorValue"
            :step="step"
            @input="emitChange()"
            @blur="blurInput()"
          />
          <span v-else>{{ value / scale }} {{ suffix }}</span>
        </p>
      </BaseTile>
    </div>

    <p v-if="warning" class="text-sm bg-warn-400 mt-2 px-2 py-1">
      {{ warning }}
    </p>
  </div>
</template>

<script>
import BaseTile from './BaseTile.vue'

export default {
  components: { BaseTile },
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
      type: Function,
      default: () => true,
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
    floorValue() {
      return Math.floor(this.value / this.scale)
    },
    inputLength() {
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
      this.validateInput(this.$refs.input.value)
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
    async focusOnInput(allow) {
      if (!allow) return
      this.inputFocus = true
      await this.$nextTick()
      const input = this.$refs.input
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
    validateInput(value) {
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
}
</script>
