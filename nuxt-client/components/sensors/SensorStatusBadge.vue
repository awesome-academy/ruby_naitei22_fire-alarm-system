<template>
  <span :class="badgeClass" class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border">
    {{ formattedStatus }}
  </span>
</template>

<script setup lang="ts">
import { computed, defineProps, type PropType } from 'vue';
import { SensorStatus } from '~/types/api';

const props = defineProps({
  status: {
    type: String as PropType<SensorStatus>,
    required: true,
  },
});

const badgeClass = computed(() => {
  switch (props.status) {
    case SensorStatus.ACTIVE:
      return 'bg-green-100 text-green-800 border-green-300';
    case SensorStatus.INACTIVE:
      return 'bg-gray-100 text-gray-800 border-gray-300';
    case SensorStatus.ERROR:
      return 'bg-red-100 text-red-800 border-red-300';
    case SensorStatus.MAINTENANCE:
      return 'bg-yellow-100 text-yellow-800 border-yellow-300';
    default:
      return 'bg-gray-100 text-gray-800 border-gray-300';
  }
});

const formattedStatus = computed(() => {
  switch (props.status) {
    case SensorStatus.ACTIVE: return 'Active';
    case SensorStatus.INACTIVE: return 'Inactive';
    case SensorStatus.ERROR: return 'Error';
    case SensorStatus.MAINTENANCE: return 'Maintenance';
    default: return props.status;
  }
});
</script>
