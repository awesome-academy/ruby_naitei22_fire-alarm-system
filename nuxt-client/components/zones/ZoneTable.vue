<template>
    <div class="overflow-x-auto bg-gray-900 border border-gray-700 rounded-lg shadow">
        <table class="min-w-full divide-y divide-gray-700">
            <thead class="bg-gray-800">
                <tr>
                    <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Zone Name
                    </th>
                    <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Description
                    </th>
                    <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Location (City/Coordinates)
                    </th>
                    <th scope="col" class="px-4 py-3 text-center text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Sensor Count
                    </th>
                    <th scope="col" class="px-4 py-3 text-center text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Camera Count
                    </th>
                    <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">
                        Created Date
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
                <tr v-else-if="!zones || zones.length === 0">
                    <td :colspan="7" class="px-4 py-4 text-center text-sm text-gray-500">
                        No zones available.
                    </td>
                </tr>
                <tr v-for="zone in zones" :key="zone.id" class="hover:bg-gray-800 transition-colors duration-150">
                    <td class="px-4 py-4 whitespace-nowrap text-sm font-medium text-white">
                        {{ zone.name }}
                    </td>
                    <td class="px-4 py-4 text-sm text-gray-400 max-w-xs truncate" :title="zone.description || ''">
                        {{ zone.description || '-' }}
                    </td>
                    <td class="px-4 py-4 whitespace-nowrap text-sm text-gray-400">
                        <span v-if="zone.city">{{ zone.city }}</span>
                        <span v-else-if="zone.latitude !== null && zone.longitude !== null">
                            {{ zone.latitude?.toFixed(4) }}, {{ zone.longitude?.toFixed(4) }}
                        </span>
                        <span v-else>-</span>
                    </td>
                    <td class="px-4 py-4 whitespace-nowrap text-center text-sm text-gray-300">
                        {{ zone.sensors?.length ?? 0 }}
                    </td>
                    <td class="px-4 py-4 whitespace-nowrap text-center text-sm text-gray-300">
                        {{ zone.cameras?.length ?? 0 }}
                    </td>
                    <td class="px-4 py-4 whitespace-nowrap text-sm text-gray-400">
                        {{ formatDateTime(zone.createdAt) }}
                    </td>
                    <td class="px-4 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <button @click="$emit('edit', zone)" class="text-blue-500 hover:text-blue-400 mr-3" title="Edit">
                            <PencilSquareIcon class="h-5 w-5 inline-block" />
                        </button>
                        <button @click="$emit('delete', zone)" class="text-red-500 hover:text-red-400" title="Delete">
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
import { PencilSquareIcon, TrashIcon } from '@heroicons/vue/24/outline';
import type { Zone } from '~/types/api';
import AppSpinner from '~/components/ui/AppSpinner.vue';

const props = defineProps({
    zones: {
        type: Array as PropType<Zone[]>,
        required: true,
    },
    loading: {
        type: Boolean,
        default: false,
    },
});

const emit = defineEmits(['edit', 'delete']);

const formatDateTime = (dateTimeString: string | Date | undefined | null): string => {
    if (!dateTimeString) return 'N/A';
    try {
        const date = new Date(dateTimeString);
        if (isNaN(date.getTime())) return 'Invalid Date';
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
        return 'Invalid Date';
    }
};
</script>