<template>
    <AppModal :is-open="isOpen" @close="$emit('close')">
        <template #title>
            Sensor Details: {{ sensorDetail?.name }}
        </template>

        <template #content>
            <div v-if="pending" class="text-center py-10">
                <AppSpinner class="inline-block w-8 h-8" />
                <p class="text-gray-400 mt-2">Loading details...</p>
            </div>
            <div v-else-if="error" class="error-alert">
                <span>{{ error.data?.message || 'Unable to load sensor details.' }}</span>
                <button @click="fetchSensorDetails" class="ml-auto underline text-sm">Retry</button>
            </div>
            <div v-else-if="sensorDetail" class="space-y-4 text-sm">
                <div class="grid grid-cols-3 gap-x-4 gap-y-2">
                    <dt class="text-gray-400">ID:</dt>
                    <dd class="col-span-2 text-gray-200 font-mono text-xs">{{ sensorDetail.id }}</dd>

                    <dt class="text-gray-400">Type:</dt>
                    <dd class="col-span-2 text-gray-200">{{ sensorDetail.type }}</dd>

                    <dt class="text-gray-400">Location:</dt>
                    <dd class="col-span-2 text-gray-200">{{ sensorDetail.location }}</dd>

                    <dt class="text-gray-400">Zone:</dt>
                    <dd class="col-span-2 text-gray-200">{{ sensorDetail.zone?.name || 'N/A' }}</dd>

                    <dt class="text-gray-400">Status:</dt>
                    <dd class="col-span-2">
                        <SensorsSensorStatusBadge :status="sensorDetail.status" />
                    </dd>

                    <dt class="text-gray-400">Threshold:</dt>
                    <dd class="col-span-2 text-gray-200">
                        {{ sensorDetail.threshold != null ? sensorDetail.threshold.toFixed(1) : '-' }}
                        <span v-if="sensorDetail.threshold !== null">°C</span>
                    </dd>

                    <dt class="text-gray-400">Sensitivity:</dt>
                    <dd class="col-span-2 text-gray-200">{{ sensorDetail.sensitivity ?? 'Not set' }}</dd>

                    <dt class="text-gray-400">Created At:</dt>
                    <dd class="col-span-2 text-gray-200">{{ formatDateTime(sensorDetail.createdAt) }}</dd>
                </div>

                <div class="mt-6 pt-4 border-t border-gray-700">
                    <h4 class="text-base font-medium text-white mb-3">Recent Logs</h4>
                    <div class="overflow-x-auto max-h-60 border border-gray-700 rounded">
                        <table class="min-w-full divide-y divide-gray-600">
                            <thead class="bg-gray-700 sticky top-0">
                                <tr>
                                    <th scope="col" class="px-3 py-2 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Time</th>
                                    <th scope="col" class="px-3 py-2 text-center text-xs font-medium text-gray-300 uppercase tracking-wider">Temp (°C)</th>
                                    <th scope="col" class="px-3 py-2 text-center text-xs font-medium text-gray-300 uppercase tracking-wider">Humidity (%)</th>
                                </tr>
                            </thead>
                            <tbody class="bg-gray-800 divide-y divide-gray-600">
                                <tr v-if="!sensorDetail.logs || sensorDetail.logs.length === 0">
                                    <td colspan="3" class="px-3 py-3 text-center text-sm text-gray-500">No logs available.</td>
                                </tr>
                                <tr v-for="log in sensorDetail.logs" :key="log.id">
                                    <td class="px-3 py-2 whitespace-nowrap text-xs text-gray-400">{{ formatDateTime(log.createdAt) }}</td>
                                    <td class="px-3 py-2 whitespace-nowrap text-xs text-center" :class="{'text-white': log.temperature !== null, 'text-gray-600': log.temperature === null}">
                                        {{ log.temperature?.toFixed(1) ?? '-' }}
                                    </td>
                                    <td class="px-3 py-2 whitespace-nowrap text-xs text-center" :class="{'text-white': log.humidity !== null, 'text-gray-600': log.humidity === null}">
                                        {{ log.humidity?.toFixed(0) ?? '-' }}
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <div v-else class="text-center py-10 text-gray-500">Sensor information not found.</div>
        </template>

        <template #footer>
            <button
                type="button"
                class="inline-flex justify-center rounded-md border border-gray-600 bg-gray-700 px-4 py-2 text-sm font-medium text-gray-300 hover:bg-gray-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-gray-500 focus-visible:ring-offset-2 focus-visible:ring-offset-gray-800"
                @click="$emit('close')"
            >
                Close
            </button>
        </template>
    </AppModal>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';
import { useApi } from '~/composables/useApi';
import AppModal from '~/components/ui/AppModal.vue';
import AppSpinner from '~/components/ui/AppSpinner.vue';
import SensorsSensorStatusBadge from '~/components/sensors/SensorStatusBadge.vue';
import type { SensorWithDetails } from '~/types/api';

const props = defineProps({
    isOpen: { type: Boolean, required: true },
    sensorId: { type: String, default: null },
});
defineEmits(['close']);

const api = useApi();

const sensorDetail = ref<SensorWithDetails | null>(null);
const pending = ref(false);
const error = ref<any | null>(null);

const fetchSensorDetails = async () => {
    if (!props.sensorId || pending.value) return;
    pending.value = true;
    error.value = null;
    try {
        sensorDetail.value = await api.sensors.getById(props.sensorId);
    } catch (err: any) {
        error.value = err;
    } finally {
        pending.value = false;
    }
};

const resetState = () => {
    sensorDetail.value = null;
    error.value = null;
    pending.value = false;
};

watch(() => props.isOpen, (newIsOpen) => {
    if (newIsOpen && props.sensorId) {
        fetchSensorDetails();
    } else if (!newIsOpen) {
        resetState();
    }
});

const formatDateTime = (dateTimeString: string | Date): string => {
    if (!dateTimeString) return 'N/A';
    try {
        return new Date(dateTimeString).toLocaleString('en-US', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: false,
        });
    } catch {
        return 'Invalid Date';
    }
};
</script>

<style scoped>
.error-alert {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.75rem;
    border-radius: 0.375rem;
    border-width: 1px;
    background-color: rgba(191, 27, 27, 0.1);
    border-color: rgba(220, 38, 38, 0.3);
    color: #fca5a5;
}
.max-h-60 {
    max-height: 15rem;
}
.max-h-60::-webkit-scrollbar { width: 6px; }
.max-h-60::-webkit-scrollbar-track { background: #4a5568; border-radius: 3px; }
.max-h-60::-webkit-scrollbar-thumb { background: #718096; border-radius: 3px; }
.max-h-60::-webkit-scrollbar-thumb:hover { background: #a0aec0; }
</style>
