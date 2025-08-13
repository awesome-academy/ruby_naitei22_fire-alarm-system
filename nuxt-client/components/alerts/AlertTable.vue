<template>
    <div class="overflow-x-auto bg-gray-900 border border-gray-700 rounded-lg shadow">
        <table class="min-w-full divide-y divide-gray-700">
            <thead class="bg-gray-800">
                <tr>
                    <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Time
                    </th>
                    <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Sensor
                    </th>
                    <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Zone
                    </th>
                    <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Alert Message
                    </th>
                    <th scope="col" class="px-4 py-3 text-center text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Status
                    </th>
                    <th scope="col" class="px-4 py-3 text-center text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Image
                    </th>
                    <th scope="col" class="relative px-4 py-3">
                        <span class="sr-only">Actions</span>
                    </th>
                </tr>
            </thead>
            <tbody class="bg-gray-900 divide-y divide-gray-700">
                <tr v-if="loading">
                    <td :colspan="7" class="px-4 py-4 text-center text-sm text-gray-500">
                        <AppSpinner class="inline-block mr-2" /> Loading data...
                    </td>
                </tr>
                <tr v-else-if="!alerts || alerts.length === 0">
                    <td :colspan="7" class="px-4 py-4 text-center text-sm text-gray-500">
                        No alerts available.
                    </td>
                </tr>
                <tr v-for="alert in alerts" :key="alert.id" class="hover:bg-gray-800 transition-colors duration-150">
                    <td class="px-4 py-4 whitespace-nowrap text-sm text-gray-300">
                        {{ formatDateTime(alert.createdAt) }}
                    </td>
                    <td class="px-4 py-4 whitespace-nowrap text-sm text-gray-300">
                        {{ alert.sensor?.name || 'N/A' }}
                        <div class="text-xs text-gray-500">{{ alert.sensor?.location }}</div>
                    </td>
                    <td class="px-4 py-4 whitespace-nowrap text-sm text-gray-400">
                        {{ alert.sensor?.zone?.name || 'N/A' }}
                    </td>
                    <td class="px-4 py-4 text-sm text-gray-200 max-w-xs truncate" :title="alert.message">
                        {{ alert.message }}
                    </td>
                    <td class="px-4 py-4 whitespace-nowrap text-center text-sm">
                        <AlertStatusBadge :status="alert.status" />
                    </td>
                    <td class="px-4 py-4 whitespace-nowrap text-center">
                        <a v-if="alert.imageUrl" :href="alert.imageUrl" target="_blank" title="View image"
                            class="text-orange-500 hover:text-orange-400">
                            <PhotoIcon class="h-5 w-5 inline-block" />
                        </a>
                        <span v-else class="text-gray-600">-</span>
                    </td>
                    <td class="px-4 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
            <button @click="$emit('view-details', alert.id)" class="text-orange-500 hover:text-orange-400" title="Xem chi tiết">
              <EyeIcon class="h-5 w-5 inline-block" />
            </button>
            <button
                v-if="alert.status === AlertStatus.PENDING"
                @click="$emit('update-status', { id: alert.id, status: AlertStatus.RESOLVED })"
                class="text-green-500 hover:text-green-400" title="Đánh dấu Đã xử lý">
              <CheckCircleIcon class="h-5 w-5 inline-block" />
            </button>
            <button
                v-if="alert.status === AlertStatus.PENDING"
                @click="$emit('update-status', { id: alert.id, status: AlertStatus.IGNORED })"
                class="text-yellow-500 hover:text-yellow-400" title="Bỏ qua">
              <ArchiveBoxXMarkIcon class="h-5 w-5 inline-block" />
            </button>
          </td>
                </tr>
            </tbody>
        </table>
    </div>
</template>

<script setup lang="ts">
import { defineProps, type PropType } from 'vue';
import { EyeIcon, PhotoIcon } from '@heroicons/vue/24/outline';
import type { AlertWithRelations } from '~/types/api';
import AlertStatusBadge from './AlertStatusBadge.vue';
import AppSpinner from '~/components/ui/AppSpinner.vue';
import { AlertStatus } from '~/types/api';

const props = defineProps({
    alerts: {
        type: Array as PropType<AlertWithRelations[]>,
        required: true,
    },
    loading: {
        type: Boolean,
        default: false,
    },
});
const emit = defineEmits(['view-details', 'update-status']);

const formatDateTime = (dateTimeString: string | Date): string => {
    if (!dateTimeString) return 'N/A';
    try {
        const date = new Date(dateTimeString);
        if (isNaN(date.getTime())) {
            console.warn(`Invalid date string received: ${dateTimeString}`);
            return 'Invalid Date';
        }
        return date.toLocaleString('en-US', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: false,
        });
    } catch (e) {
        console.error(`Error formatting date: ${dateTimeString}`, e);
        return 'Invalid Date';
    }
};
</script>

<style scoped>
</style>
