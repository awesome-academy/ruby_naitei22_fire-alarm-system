<template>
    <div class="p-4 sm:p-6 lg:p-8">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-semibold text-white">Sensor List</h1>
            <NuxtLink
                to="/sensors/config"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-orange-500"
            >
                <Cog6ToothIcon class="h-5 w-5 mr-2" />
                Manage / Add New
            </NuxtLink>
        </div>

        <div v-if="pending && !sensors" class="text-center py-20">
            <AppSpinner class="w-10 h-10 inline-block" />
            <p class="text-gray-400 mt-3">Loading sensor list...</p>
        </div>
        <div v-else-if="error" class="error-alert mb-6">
            <div class="flex items-center">
                <XCircleIcon class="h-5 w-5 mr-2 flex-shrink-0" />
                <span>{{ 'Unable to load sensor list.' }}</span>
            </div>
            <button @click="() => refresh()" class="text-sm font-medium text-orange-400 hover:underline">Retry</button>
        </div>
        <div v-else>
            <SensorsSensorTable
                :sensors="sensors ?? []"
                :loading="pending"
                @delete="handleDeleteSensor"
                @view-details="handleViewDetails"
            />
        </div>

        <AppModal :is-open="showDeleteConfirm" @close="cancelDelete">
            <template #title>Confirm Sensor Deletion</template>
            <template #content>
                <p class="text-sm text-gray-400">
                    Are you sure you want to delete the sensor <strong class="text-white">{{ sensorToDelete?.name }}</strong>? This action cannot be undone.
                </p>
            </template>
            <template #footer>
                <button @click="confirmDelete" :disabled="deleting" class="btn-danger inline-flex items-center">
                    <AppSpinner v-if="deleting" class="w-4 h-4 mr-2" />
                    {{ deleting ? 'Deleting...' : 'Delete' }}
                </button>
                <button @click="cancelDelete" class="ml-3 btn-secondary">Cancel</button>
            </template>
        </AppModal>

        <SensorsSensorDetailsModal
            :is-open="showDetailsModal"
            :sensor-id="selectedSensorId ?? undefined"
            @close="closeDetailsModal"
        />
    </div>
</template>

<script setup lang="ts">
import { ref, nextTick } from 'vue';
import { useApi } from '~/composables/useApi';
import { useAsyncData } from '#app';
import Swal from 'sweetalert2';
import SensorsSensorTable from '~/components/sensors/SensorTable.vue';
import AppModal from '~/components/ui/AppModal.vue';
import AppSpinner from '~/components/ui/AppSpinner.vue';
import SensorsSensorDetailsModal from '~/components/sensors/SensorDetailsModal.vue';
import { XCircleIcon, Cog6ToothIcon } from '@heroicons/vue/20/solid';
import type { SensorWithDetails } from '~/types/api';

definePageMeta({
    layout: 'default',
    middleware: ['auth'],
});

const api = useApi();
const showDeleteConfirm = ref(false);
const sensorToDelete = ref<SensorWithDetails | null>(null);
const deleting = ref(false);
const showDetailsModal = ref(false);
const selectedSensorId = ref<string | null>(null);

const { data: sensors, pending, error, refresh } = useAsyncData(
    'sensors-list',
    () => api.sensors.getAll(),
    { lazy: true, server: false }
);

const handleDeleteSensor = (sensorId: string) => {
    const sensor = sensors.value?.find((s) => s.id === sensorId);
    if (sensor) {
        sensorToDelete.value = sensor;
        showDeleteConfirm.value = true;
    }
};

const cancelDelete = () => {
    showDeleteConfirm.value = false;
    nextTick(() => { sensorToDelete.value = null; });
};

const confirmDelete = async () => {
    if (!sensorToDelete.value) return;
    deleting.value = true;
    try {
        await api.sensors.delete(sensorToDelete.value.id);
        await refresh();
        cancelDelete();
        Swal.fire({
            toast: true,
            position: 'top-end',
            icon: 'success',
            title: 'Sensor deleted!',
            showConfirmButton: false,
            timer: 2000,
            background: '#1f2937',
            color: '#d1d5db',
        });
    } catch (err: any) {
        Swal.fire({
            icon: 'error',
            title: 'Delete Failed',
            text: err.data?.message || 'Could not delete the sensor.',
            background: '#1f2937',
            color: '#d1d5db',
            confirmButtonColor: '#f97316',
        });
    } finally {
        deleting.value = false;
    }
};

const handleViewDetails = (sensorId: string) => {
    selectedSensorId.value = sensorId;
    showDetailsModal.value = true;
};

const closeDetailsModal = () => {
    showDetailsModal.value = false;
    nextTick(() => { selectedSensorId.value = null; });
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
    font-size: 0.875rem;
    line-height: 1.25rem;
    background-color: rgba(191, 27, 27, 0.1);
    border-color: rgba(220, 38, 38, 0.3);
    color: #fca5a5;
}
.btn-danger {
    display: inline-flex;
    justify-content: center;
    align-items: center;
    padding: 0.5rem 1rem;
    border-radius: 0.375rem;
    background-color: #dc2626;
    color: #ffffff;
    font-size: 0.875rem;
    font-weight: 500;
    transition: background-color 0.2s ease-in-out;
}
.btn-secondary {
    display: inline-flex;
    justify-content: center;
    align-items: center;
    padding: 0.5rem 1rem;
    border-radius: 0.375rem;
    background-color: #4b5563;
    color: #d1d5db;
    font-size: 0.875rem;
    font-weight: 500;
    transition: background-color 0.2s ease-in-out;
}
</style>
