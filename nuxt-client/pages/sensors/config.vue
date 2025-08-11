<template>
    <div class="p-4 sm:p-6 lg:p-8">
        <div class="mb-6">
            <NuxtLink to="/sensors" class="text-sm text-orange-400 hover:underline flex items-center">
                <ArrowLeftIcon class="h-4 w-4 mr-1" />
                Back to Sensor List
            </NuxtLink>
            <h1 class="text-2xl font-semibold text-white mt-2">
                {{ isEditMode ? 'Edit Sensor' : 'Add New Sensor' }}
            </h1>
            <p v-if="isEditMode && sensorData" class="text-sm text-gray-400">
                ID: <span class="font-mono text-xs">{{ sensorId }}</span>
            </p>
        </div>

        <div v-if="pending" class="text-center py-10">
            <AppSpinner class="w-8 h-8 inline-block" />
            <p class="text-gray-400 mt-2">
                {{ isEditMode ? 'Loading sensor data...' : 'Loading required data...' }}
            </p>
        </div>

        <div v-else-if="error" class="error-alert mb-6">
            <div class="flex items-center">
                <XCircleIcon class="h-5 w-5 mr-2" />
                <span>{{ 'Failed to load data.' }}</span>
            </div>
            <button @click="() => refresh()" class="text-sm font-medium text-orange-300 hover:underline">
                Retry
            </button>
        </div>

        <div v-else class="max-w-2xl">
            <SensorsSensorForm
                :initial-data="sensorData"
                :available-zones="availableZones"
                :is-submitting="isSubmitting"
                :initial-error="submitError"
                @submit="handleSubmit"
                @cancel="navigateTo('/sensors')"
            />
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRoute, navigateTo, useAsyncData } from '#app';
import { useApi } from '~/composables/useApi';
import SensorsSensorForm from '~/components/sensors/SensorForm.vue';
import AppSpinner from '~/components/ui/AppSpinner.vue';
import { ArrowLeftIcon, XCircleIcon } from '@heroicons/vue/20/solid';
import type { Sensor } from '~/types/api';
import Swal from 'sweetalert2';

definePageMeta({
    layout: 'default',
    middleware: ['auth'],
});

const api = useApi();
const route = useRoute();
const sensorId = computed(() => route.query.edit as string | undefined);
const isEditMode = computed(() => !!sensorId.value);

const isSubmitting = ref(false);
const submitError = ref<string | null>(null);

const { data, pending, error, refresh } = useAsyncData(
    'sensor-config-data',
    async () => {
        const fetchZonesPromise = api.zones.getAll({ fields: 'id,name' });
        const fetchSensorPromise = isEditMode.value
            ? api.sensors.getById(sensorId.value!)
            : Promise.resolve(null);
        const [zones, sensor] = await Promise.all([fetchZonesPromise, fetchSensorPromise]);
        return { zones, sensor };
    },
    { server: false, lazy: true }
);

const availableZones = computed(() => data.value?.zones || []);
const sensorData = computed(() => data.value?.sensor || null);

const handleSubmit = async (formData: Partial<Sensor>) => {
    isSubmitting.value = true;
    submitError.value = null;
    const successMessage = isEditMode.value ? 'Sensor updated successfully!' : 'Sensor added successfully!';
    const failureMessage = `Error while ${isEditMode.value ? 'updating' : 'creating'} sensor.`;

    try {
        if (isEditMode.value && sensorId.value) {
            await api.sensors.update(sensorId.value, formData);
        } else {
            await api.sensors.create(formData);
        }

        Swal.fire({
            icon: 'success',
            title: 'Success!',
            text: successMessage,
            timer: 2000,
            showConfirmButton: false,
            background: '#1f2937',
            color: '#d1d5db',
        });

        navigateTo('/sensors');
    } catch (err: any) {
        submitError.value = err.data?.message || failureMessage;
    } finally {
        isSubmitting.value = false;
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
    font-size: 0.875rem;
    line-height: 1.25rem;
    background-color: rgba(191, 27, 27, 0.1);
    border-color: rgba(220, 38, 38, 0.3);
    color: #fca5a5;
}
</style>
