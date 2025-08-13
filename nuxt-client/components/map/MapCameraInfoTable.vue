<template>
    <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-700">
            <thead class="bg-gray-700 sticky top-0">
                <tr>
                    <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Camera Name</th>
                    <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Zone</th>
                    <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">URL (Link)</th>
                    <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Created Date</th>
                </tr>
            </thead>
            <tbody class="bg-gray-850 divide-y divide-gray-700">
                <tr v-if="cameras.length === 0">
                    <td colspan="4" class="px-3 py-4 text-center text-sm text-gray-500 italic">No cameras available.</td>
                </tr>
                <tr v-for="camera in cameras" :key="camera.id"
                        class="hover:bg-gray-800 cursor-pointer"
                        :class="{ 'bg-blue-900/30 ring-1 ring-blue-500/50': camera.id === selectedId }"
                        @click="emitRowClick(camera)">
                    <td class="px-3 py-2 whitespace-nowrap text-sm font-medium text-white">{{ camera.name }}</td>
                    <td class="px-3 py-2 whitespace-nowrap text-sm text-gray-400">{{ camera.zone?.name || 'N/A' }}</td>
                    <td class="px-3 py-2 whitespace-nowrap text-sm max-w-[150px] truncate">
                        <a :href="camera.url" target="_blank" class="text-orange-400 hover:underline" :title="camera.url" @click.stop>
                            {{ camera.url }}
                        </a>
                    </td>
                    <td class="px-3 py-2 whitespace-nowrap text-xs text-gray-500">{{ formatDateTimeShort(camera.createdAt) }}</td>
                </tr>
            </tbody>
        </table>
    </div>
</template>

<script setup lang="ts">
import { defineProps, defineEmits } from 'vue';
import type { Camera , CameraWithOptionalZone } from '~/types/api';


const props = defineProps({
    cameras: {
        type: Array as () => CameraWithOptionalZone[],
        default: () => []
    },
    selectedId: {
        type: String as () => string | null,
        default: null
    }
});

const emit = defineEmits(['row-click']);

const emitRowClick = (camera: CameraWithOptionalZone) => {
    if (camera.latitude != null && camera.longitude != null) {
        emit('row-click', {
            id: camera.id,
            type: 'Camera',
            name: camera.name || 'Unknown Camera',
            lat: camera.latitude,
            lon: camera.longitude,
        });
    } else {
        emit('row-click', {
            id: camera.id,
            type: 'Camera',
            name: camera.name || 'Unknown Camera',
        });
    }
};

const formatDateTimeShort = (dateTimeString: string | Date | undefined | null): string => {
    if (!dateTimeString) return 'N/A';
    try {
        const date = new Date(dateTimeString);
        if (isNaN(date.getTime())) return 'Invalid';
        return date.toLocaleString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' });
    } catch (e) {
        return 'Err';
    }
};
</script>

<style scoped>
</style>