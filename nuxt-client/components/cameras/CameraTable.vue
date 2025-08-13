<template>
    <div class="overflow-x-auto bg-gray-900 border border-gray-700 rounded-lg shadow">
        <table class="min-w-full divide-y divide-gray-700">
            <thead class="bg-gray-800">
                <tr>
                    <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Camera Name</th>
                    <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Zone</th>
                    <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">URL</th>
                    <th scope="col" class="px-4 py-3 text-center text-xs font-medium text-gray-400 uppercase tracking-wider">Status</th>
                    <th scope="col" class="px-4 py-3 text-center text-xs font-medium text-gray-400 uppercase tracking-wider">Fire Detection</th>
                    <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-400 uppercase tracking-wider">Coordinates</th>
                    <th scope="col" class="relative px-4 py-3 text-right text-xs font-medium text-gray-400 uppercase tracking-wider">Actions</th>
                </tr>
            </thead>
            <tbody class="bg-gray-900 divide-y divide-gray-700">
                <tr v-if="loading">
                    <td :colspan="7" class="px-4 py-4 text-center text-sm text-gray-500">
                        <AppSpinner class="inline-block mr-2" /> Loading...
                    </td>
                </tr>
                <tr v-else-if="!cameras || cameras.length === 0">
                    <td :colspan="7" class="px-4 py-4 text-center text-sm text-gray-500 italic">No cameras available.</td>
                </tr>
                <tr v-for="cam in cameras" :key="cam.id" class="hover:bg-gray-800/50">
                    <td class="px-4 py-3 whitespace-nowrap text-sm font-medium text-white">{{ cam.name }}</td>
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-400">{{ cam.zone?.name || 'N/A' }}</td>
                    <td class="px-4 py-3 text-sm text-gray-400 max-w-[200px] truncate">
                        <a :href="cam.url" target="_blank" class="hover:text-orange-400" :title="cam.url">{{ cam.url }}</a>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-center text-sm">
                        <CamerasCameraStatusBadge :status="cam.status" />
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-center text-sm">
                        <span class="px-2 py-0.5 rounded text-xs" :class="cam.isDetecting ? 'bg-blue-600/30 text-blue-300 ring-1 ring-inset ring-blue-500/40' : 'bg-gray-600/30 text-gray-400'">
                            {{ cam.isDetecting ? 'Enabled' : 'Disabled' }}
                        </span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-xs text-gray-500">
                        <span v-if="cam.latitude != null && cam.longitude != null">{{ cam.latitude.toFixed(4) }}, {{ cam.longitude.toFixed(4) }}</span>
                        <span v-else>-</span>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-right text-sm font-medium space-x-2">
                        <NuxtLink :to="`/cameras/config?edit=${cam.id}`" class="p-1 text-blue-400 hover:text-blue-300" title="Edit">
                            <PencilSquareIcon class="h-4 w-4" />
                        </NuxtLink>
                        <button @click="$emit('delete', cam)" class="p-1 text-red-500 hover:text-red-400" title="Delete">
                            <TrashIcon class="h-4 w-4" />
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
import type { CameraWithDetails } from '~/types/api';
import CamerasCameraStatusBadge from './CameraStatusBadge.vue';
import AppSpinner from '~/components/ui/AppSpinner.vue';

const props = defineProps({
    cameras: { type: Array as PropType<CameraWithDetails[]>, required: true },
    loading: { type: Boolean, default: false },
});

const emit = defineEmits(['delete', 'edit', 'view']);

const formatDateTime = (dateTimeString: string | Date | undefined | null): string => {
    if (!dateTimeString) return 'N/A';
    try {
        const date = new Date(dateTimeString);
        if (isNaN(date.getTime())) {
            console.warn('Invalid date passed to formatDateTime:', dateTimeString);
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
        console.error('Error formatting date:', e);
        return 'Invalid Date';
    }
};
</script>