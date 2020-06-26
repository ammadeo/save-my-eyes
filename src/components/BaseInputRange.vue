<template>
  <div class="grid col-gap-2 relative">
    <p
      class="font-display col-span-6 mb-1 text-secondary-200"
      @click="focusOnInput(true)"
    >
      {{ name }}
    </p>

    <div
      class="md:col-span-1 row-span-1 w-24 cursor-text flex justify-center bg-primary-700 hover:bg-primary-800 focus-within:bg-primary-800 text-secondary-100 shadow-inner-1 rounded-full px-2"
      :class="onForceLargeClasses(['col-span-1'], ['col-span-6'])"
      @click="focusOnInput(true)"
    >
      <input
        ref="input"
        type="number"
        class="bg-transparent selection-darker outline-none text-right pr-1"
        :class="[widthInputLenghtClass]"
        :max="max"
        :min="min"
        :value="floorValue"
        :step="step"
        @input="emitChange($event)"
        @blur="blurInput()"
      />
      <span class="selection-darker">{{ suffix }}</span>
    </div>
    <input
      type="range"
      class="bg-transparent col-span-5 md:block"
      :class="onForceLargeClasses([], ['hidden'])"
      :max="max"
      :min="min"
      :value="floorValue"
      :step="step"
      tabindex="-1"
      @input="emitChange($event)"
      @blur="blurInput()"
    />

    <p
      class="col-start-2 col-end-4 text-secondary-200 md:block"
      :class="onForceLargeClasses([], ['hidden'])"
    >
      {{ min }} {{ suffix }}
    </p>
    <p
      class="col-start-4 col-end-7 text-right text-secondary-200 md:block"
      :class="onForceLargeClasses([], ['hidden'])"
    >
      {{ max }} {{ suffix }}
    </p>
    <transition name="fade">
      <p
        v-if="warning"
        class="text-sm w-full shadow top-full absolute rounded-sm bg-warn-400 px-2 py-1 z-10"
      >
        {{ warning }}
      </p>
    </transition>
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
    forceLarge: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      warning: '',
    }
  },
  computed: {
    floorValue(): number {
      return Math.floor(this.value / this.scale)
    },
    inputLength(): number {
      return this.floorValue.toString().length
    },
    widthInputLenghtClass(): string {
      const lenght = this.inputLength
      switch (lenght) {
        case 0:
        case 1:
          return 'w-4'
        case 2:
          return 'w-6'
        default:
          return 'w-8'
      }
    },
  },
  beforeMount() {
    this.$useI18n((t) => ({
      warningToMuch: t("You can't set more than", 'Musi być mniejsza niż'),
      warningToSmall: t("You can't set less than", 'Musi być większa niż'),
    }))
  },
  methods: {
    emitChange(event: Event) {
      const input = event.target as HTMLInputElement
      this.validateInput(Number(input.value))
    },
    onForceLargeClasses(onForce: string[], onRevers: string[] = []): string[] {
      return this.forceLarge ? onForce : onRevers
    },
    async focusOnInput(allow: boolean) {
      if (!allow) return
      await this.$nextTick()
      const input = this.$refs.input as HTMLInputElement
      if (input) {
        input.focus()
      }
    },
    async blurInput() {
      this.warning = ''
    },
    validateInput(value: number) {
      const { min, max, suffix, scale } = this
      if (value < min)
        return (this.warning = `${this.$t('warningToSmall')} ${min} ${suffix}`)
      if (value > max)
        return (this.warning = `${this.$t('warningToMuch')} ${max} ${suffix}`)

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
