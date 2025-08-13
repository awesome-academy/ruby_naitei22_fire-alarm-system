<template>
    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-700">
            <thead class="bg-gray-700 sticky top-0">
                <tr>
                    <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Time</th>
                    <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Sensor</th>
                    <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Zone</th>
                    <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Message</th>
                    <th scope="col" class="px-3 py-2 text-center text-xs font-medium text-gray-300 uppercase tracking-wider">Status</th>
                </tr>
            </thead>
            <tbody class="bg-gray-850 divide-y divide-gray-700">
                <tr v-if="alerts.length === 0">
                    <td colspan="5" class="px-3 py-4 text-center text-sm text-gray-500 italic">No pending alerts.</td>
                </tr>
                <tr v-for="alert in alerts" :key="alert.id"
                        class="hover:bg-red-900/20 cursor-pointer"
                        :class="{ 'bg-blue-900/30 ring-1 ring-blue-500/50': alert.sensorId === selectedSensorId }"
                        @click="emitRowClick(alert)">
                    <td class="px-3 py-2 whitespace-nowrap text-sm text-red-300">{{ formatDateTimeShort(alert.createdAt) }}</td>
                    <td class="px-3 py-2 whitespace-nowrap text-sm font-medium text-red-300">{{ alert.sensor?.name || 'N/A' }}</td>
                    <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-400">{{ alert.sensor?.zone?.name || 'N/A' }}</td>
                    <td class="px-3 py-2 text-sm text-gray-200 max-w-xs truncate" :title="alert.message">{{ alert.message }}</td>
                    <td class="px-3 py-2 whitespace-nowrap text-center text-sm">
                        <AlertStatusBadge :status="alert.status" />
                    </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>

<script setup lang="ts">
import { defineProps, defineEmits } from 'vue';
import { type Alert, type AlertWithSensorZone } from '~/types/api'; // Use 'type' for AlertWithSensorZone
import AlertStatusBadge from '~/components/alerts/AlertStatusBadge.vue';

const props = defineProps({
    alerts: {
        type: Array as () => AlertWithSensorZone[],
        default: () => []
    },
    selectedSensorId: {
        type: String as () => string | null,
        default: null
    }
});

const emit = defineEmits(['row-click']);

const emitRowClick = (alert: AlertWithSensorZone) => {
    if (alert.sensor) {
        if (alert.sensor.latitude != null && alert.sensor.longitude != null) {
            emit('row-click', {
                id: alert.sensor.id,
                type: 'Sensor',
                name: alert.sensor.name || 'Unknown Sensor',
                lat: alert.sensor.latitude,
                lon: alert.sensor.longitude,
            });
        } else {
            emit('row-click', {
                id: alert.sensor.id,
                type: 'Sensor',
                name: alert.sensor.name || 'Unknown Sensor',
                lat: null,
                lon: null,
            });
        }
    }
};

const formatDateTimeShort = (dateTimeString: string | Date | undefined | null): string => {
    if (!dateTimeString) return 'N/A';
    try {
        const date = new Date(dateTimeString);
        if (isNaN(date.getTime())) return 'Invalid';
        return date.toLocaleString('en-US', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' });
    } catch (e) {
        return 'Error';
    }
};
</script>

<style scoped>
</style>