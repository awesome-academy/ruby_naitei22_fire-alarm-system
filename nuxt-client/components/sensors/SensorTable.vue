<template>
  <div class="overflow-x-auto bg-gray-900 border border-gray-700 rounded-lg shadow">
    <table class="min-w-full divide-y divide-gray-700">
      <thead class="bg-gray-800">
        <tr>
          <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
            Sensor Name
          </th>
          <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
            Type
          </th>
          <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
            Zone
          </th>
          <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
            Location
          </th>
          <th scope="col" class="px-4 py-3 text-center text-xs font-medium text-gray-400 uppercase tracking-wider">
            Status
          </th>
          <th scope="col" class="px-4 py-3 text-center text-xs font-medium text-gray-400 uppercase tracking-wider">
            Latest Value
          </th>
          <th scope="col" class="px-4 py-3 text-center text-xs font-medium text-gray-400 uppercase tracking-wider">
            Threshold
          </th>
          <th scope="col" class="relative px-4 py-3">
            <span class="sr-only">Actions</span>
          </th>
        </tr>
      </thead>
      <tbody class="bg-gray-900 divide-y divide-gray-700">
        <tr v-if="loading">
          <td :colspan="8" class="px-4 py-4 text-center text-sm text-gray-500">
            <AppSpinner class="inline-block mr-2" /> Loading data...
          </td>
        </tr>
        <tr v-else-if="!sensors || sensors.length === 0">
          <td :colspan="8" class="px-4 py-4 text-center text-sm text-gray-500">
            No sensors available.
          </td>
        </tr>
        <tr v-for="sensor in sensors" :key="sensor.id" class="hover:bg-gray-800 transition-colors duration-150">
          <td class="px-4 py-4 whitespace-nowrap text-sm font-medium text-white">
            {{ sensor.name }}
          </td>
          <td class="px-4 py-4 whitespace-nowrap text-sm text-gray-300">
            {{ sensor.type }}
          </td>
          <td class="px-4 py-4 whitespace-nowrap text-sm text-gray-400">
            {{ sensor.zone?.name || 'N/A' }}
          </td>
          <td class="px-4 py-4 whitespace-nowrap text-sm text-gray-400 max-w-xs truncate" :title="sensor.location">
            {{ sensor.location }}
          </td>
          <td class="px-4 py-4 whitespace-nowrap text-center text-sm">
            <SensorsSensorStatusBadge :status="sensor.status" />
          </td>
          <td class="px-4 py-4 whitespace-nowrap text-center text-sm text-gray-300">
            <span v-if="sensor.latestLog?.temperature !== null && sensor.latestLog?.temperature !== undefined">
              {{ sensor.latestLog.temperature.toFixed(1) }}°C
            </span>
            <span v-if="sensor.latestLog?.humidity !== null && sensor.latestLog?.humidity !== undefined" class="ml-2">
              {{ sensor.latestLog.humidity.toFixed(0) }}%
            </span>
            <span v-if="!sensor.latestLog?.temperature && !sensor.latestLog?.humidity" class="text-gray-600">-</span>
            <div v-if="sensor.latestLog?.createdAt" class="text-xs text-gray-500 mt-1">
              {{ formatDateTime(sensor.latestLog.createdAt) }}
            </div>
          </td>
          <td class="px-4 py-4 whitespace-nowrap text-center text-sm text-gray-400">
            {{ sensor.threshold != null ? sensor.threshold.toFixed(1) : '-' }}
            <span v-if="sensor.threshold !== null">°C</span>
          </td>
          <td class="px-4 py-4 whitespace-nowrap text-right text-sm font-medium">
            <button @click="$emit('view-details', sensor.id)" class="text-orange-500 hover:text-orange-400 mr-3" title="View Details">
              <EyeIcon class="h-5 w-5 inline-block" />
            </button>
            <NuxtLink :to="`/sensors/config?edit=${sensor.id}`" class="text-blue-500 hover:text-blue-400 mr-3" title="Edit">
              <PencilSquareIcon class="h-5 w-5 inline-block" />
            </NuxtLink>
            <button @click="$emit('delete', sensor.id)" class="text-red-500 hover:text-red-400" title="Delete">
              <TrashIcon class="h-5 w-5 inline-block" />
            </button>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
import { defineProps, type PropType, defineEmits } from 'vue';
import { EyeIcon, PencilSquareIcon, TrashIcon } from '@heroicons/vue/24/outline';
import type { SensorWithDetails } from '~/types/api';
import SensorsSensorStatusBadge from './SensorStatusBadge.vue';
import AppSpinner from '~/components/ui/AppSpinner.vue';

const props = defineProps({
  sensors: {
    type: Array as PropType<SensorWithDetails[]>,
    required: true,
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['delete', 'view-details']);

const formatDateTime = (dateTimeString: string | Date | undefined | null): string => {
  if (!dateTimeString) return 'N/A';
  try {
    const date = new Date(dateTimeString);
    if (isNaN(date.getTime())) {
      console.warn('Invalid date passed to formatDateTime:', dateTimeString);
      return 'Invalid Date';
    }
    return date.toLocaleString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    });
  } catch (e) {
    console.error('Error formatting date:', e);
    return 'Invalid Date';
  }
};
</script>

<style scoped>
</style>
