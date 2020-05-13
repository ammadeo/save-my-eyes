<script lang="ts">
import Vue, { VNode } from 'vue'
// import mixins from 'vue-typed-mixins'
import createFocusTrap, { FocusTrap } from 'focus-trap'

export default Vue.extend({
  render(): VNode {
    const slot = this.$slots.default
    if (!slot || !slot.length || slot.length > 1)
      throw new Error('BaseFocusTrap requires exactly one child')

    return slot[0]
  },
  props: {
    active: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      focusTrap: null,
    } as {
      focusTrap: FocusTrap | null
    }
  },
  watch: {
    active: {
      async handler(activate): Promise<void> {
        if (activate) {
          await this.$nextTick()
          const component = this.$el as HTMLElement
          if (component) {
            const trap = createFocusTrap(component, {
              allowOutsideClick: () => true,
              fallbackFocus: component,
            })
            trap.activate()
            this.focusTrap = trap
          } else {
            throw new Error('component not defined')
          }
        } else {
          this.deactivateTrap()
        }
      },
      immediate: true,
    },
  },
  beforeDestroy() {
    this.deactivateTrap()
  },
  methods: {
    deactivateTrap(): void {
      const focusTrap = this.focusTrap
      if (focusTrap) {
        focusTrap.deactivate()
        this.focusTrap = null
      }
    },
  },
})
</script>
