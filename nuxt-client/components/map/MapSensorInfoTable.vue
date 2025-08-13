<template>
  <div class="overflow-x-auto">
    <table class="min-w-full divide-y divide-gray-700">
      <thead class="bg-gray-700 sticky top-0">
        <tr>
          <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Tên</th>
          <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Khu vực</th>
          <th scope="col" class="px-3 py-2 text-center text-xs font-medium text-gray-300 uppercase tracking-wider">Trạng thái</th>
          <th scope="col" class="px-3 py-2 text-center text-xs font-medium text-gray-300 uppercase tracking-wider">Nhiệt độ</th>
          <th scope="col" class="px-3 py-2 text-center text-xs font-medium text-gray-300 uppercase tracking-wider">Độ ẩm</th>
          <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Log cuối</th>
        </tr>
      </thead>
      <tbody class="bg-gray-850 divide-y divide-gray-700">
        <tr v-if="sensors.length === 0">
          <td colspan="6" class="px-3 py-4 text-center text-sm text-gray-500 italic">Không có cảm biến nào.</td>
        </tr>
        <tr
          v-for="sensor in sortedSensors"
          :key="sensor.id"
          class="hover:bg-gray-800 cursor-pointer"
          :class="{ 'bg-blue-900/30 ring-1 ring-blue-500/50': sensor.id === selectedId, '!bg-red-900/30 hover:!bg-red-800/40': alertedIds.has(sensor.id) }"
          @click="emitRowClick(sensor)"
        >
          <td class="px-3 py-2 whitespace-nowrap text-sm font-medium" :class="alertedIds.has(sensor.id) ? 'text-red-300' : 'text-white'">{{ sensor.name }}</td>
          <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-400">{{ sensor.zone?.name || 'N/A' }}</td>
          <td class="px-3 py-2 whitespace-nowrap text-center text-sm">
            <SensorsSensorStatusBadge :status="sensor.status" />
          </td>
          <td class="px-3 py-2 whitespace-nowrap text-sm text-center" :class="getTempColor(sensor.latestLog?.temperature, sensor.threshold)">
            {{ sensor.latestLog?.temperature?.toFixed(1) ?? '-' }}<span v-if="sensor.latestLog?.temperature !== null">°C</span>
          </td>
          <td class="px-3 py-2 whitespace-nowrap text-sm text-center text-gray-300">
            {{ sensor.latestLog?.humidity?.toFixed(0) ?? '-' }}<span v-if="sensor.latestLog?.humidity !== null">%</span>
          </td>
          <td class="px-3 py-2 whitespace-nowrap text-xs text-gray-500">{{ formatDateTimeShort(sensor.latestLog?.createdAt) }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
import { defineProps, defineEmits, computed } from 'vue';
import { SensorStatus, type SensorWithOptionalZone } from '~/types/api';
import SensorsSensorStatusBadge from '~/components/sensors/SensorStatusBadge.vue';

const props = defineProps({
  sensors: {
    type: Array as () => SensorWithOptionalZone[],
    default: () => [],
  },
  alertedIds: {
    type: Set as unknown as () => Set<string>,
    default: () => new Set(),
  },
  selectedId: {
    type: String as () => string | null,
    default: null,
  },
});

const emit = defineEmits(['row-click']);

const sortedSensors = computed(() => {
  return [...props.sensors].sort((a, b) => {
    const aAlert = props.alertedIds.has(a.id);
    const bAlert = props.alertedIds.has(b.id);
    const aError = a.status === SensorStatus.ERROR;
    const bError = b.status === SensorStatus.ERROR;

    if (aAlert !== bAlert) return aAlert ? -1 : 1;
    if (aError !== bError) return aError ? -1 : 1;
    return a.name.localeCompare(b.name);
  });
});

const emitRowClick = (sensor: SensorWithOptionalZone) => {
  if (sensor.latitude != null && sensor.longitude != null){
    emit('row-click', {
      id: sensor.id,
      type: 'Sensor',
      name: sensor.name,
      lat: sensor.latitude,
      lon: sensor.longitude,
    });
  } else {
    emit('row-click', {
      id: sensor.id,
      type: 'Sensor',
      name: sensor.name,
      lat: null,
      lon: null,
    });
  }
};

const getTempColor = (temp: number | null | undefined, threshold: number | null | undefined): string => {
  if (temp === null || temp === undefined) return 'text-gray-600';
  if (threshold !== null && threshold !== undefined && temp >= threshold) return 'text-red-400 font-bold';
  return 'text-gray-300';
};

const formatDateTimeShort = (dateTimeString: string | Date | undefined | null): string => {
  if (!dateTimeString) return 'N/A';
  try {
    const date = new Date(dateTimeString);
    if (isNaN(date.getTime())) return 'Invalid';
    return date.toLocaleString('vi-VN', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  } catch (e) {
    return 'Err';
  }
};
</script>