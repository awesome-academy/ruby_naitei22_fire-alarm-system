<template>
    <form @submit.prevent="submitForm" class="space-y-4">
        <div v-if="localError" class="rounded-md bg-red-100 p-3 border border-red-300 mb-4">
            <p class="text-sm font-medium text-red-800">{{ localError }}</p>
        </div>

        <div>
            <label for="sensor-name" class="block text-sm font-medium text-gray-300 mb-1">Sensor Name <span class="text-red-500">*</span></label>
            <input type="text" id="sensor-name" v-model="formData.name" required placeholder="Example: Rack A1 Thermometer - Top"
                class="w-full input-style" />
        </div>

        <div>
            <label for="sensor-type" class="block text-sm font-medium text-gray-300 mb-1">Sensor Type <span class="text-red-500">*</span></label>
            <select id="sensor-type" v-model="formData.type" required class="w-full input-style">
                <option disabled value="">-- Select Sensor Type --</option>
                <option value="HUMIDITY">HUMIDITY</option>
                <option value="TEMPERATURE">TEMPERATURE</option>
                <option value="TEMP_HUMID">TEMP_HUMID</option>
            </select>
            <p class="mt-1 text-xs text-gray-500">Select the sensor type (e.g., HUMIDITY, TEMPERATURE, TEMP_HUMID).</p>
        </div>

        <div>
            <label for="sensor-location" class="block text-sm font-medium text-gray-300 mb-1">Location Description <span class="text-red-500">*</span></label>
            <input type="text" id="sensor-location" v-model="formData.location" required placeholder="Example: Top of rack A1, front side"
                class="w-full input-style" />
            <p class="mt-1 text-xs text-gray-500">Provide a specific physical location description.</p>
        </div>

        <div>
            <label for="sensor-zone" class="block text-sm font-medium text-gray-300 mb-1">Zone <span class="text-red-500">*</span></label>
            <select id="sensor-zone" v-model="formData.zoneId" required class="w-full input-style">
                <option disabled value="">-- Select Zone --</option>
                <option v-for="zone in availableZones" :key="zone.id" :value="zone.id">
                    {{ zone.name }}
                </option>
            </select>
            <p v-if="!availableZones || availableZones.length === 0" class="mt-1 text-xs text-yellow-400">Loading or no zones available. Please create a zone first.</p>
        </div>

        <fieldset class="border border-gray-700 rounded p-3 pt-1">
            <legend class="text-sm font-medium text-gray-400 px-1">Geographical Coordinates (Optional)</legend>
            <p class="text-xs text-gray-500 mb-3">Enter to display accurately on the Leaflet map.</p>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                    <label for="sensor-latitude" class="block text-xs font-medium text-gray-300 mb-1">Latitude</label>
                    <input type="number" step="any" id="sensor-latitude" v-model.number="formData.latitude" placeholder="Example: 10.7755" min="-90" max="90"
                        class="w-full input-style" />
                </div>
                <div>
                    <label for="sensor-longitude" class="block text-xs font-medium text-gray-300 mb-1">Longitude</label>
                    <input type="number" step="any" id="sensor-longitude" v-model.number="formData.longitude" placeholder="Example: 106.7019" min="-180" max="180"
                        class="w-full input-style" />
                </div>
            </div>
        </fieldset>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
                <label for="sensor-threshold" class="block text-sm font-medium text-gray-300 mb-1">Threshold</label>
                <input type="number" step="any" id="sensor-threshold" v-model.number="formData.threshold" placeholder="Example: 35.0 (°C)"
                    class="w-full input-style" />
                <p class="mt-1 text-xs text-gray-500">Maximum value before triggering an alert.</p>
            </div>
            <div>
                <label for="sensor-sensitivity" class="block text-sm font-medium text-gray-300 mb-1">Sensitivity</label>
                <input type="number" step="1" id="sensor-sensitivity" v-model.number="formData.sensitivity" placeholder="Example: 5"
                    class="w-full input-style" />
                <p class="mt-1 text-xs text-gray-500">Sensor sensitivity level (if applicable).</p>
            </div>
        </div>

        <div v-if="isEditMode">
            <label for="sensor-status" class="block text-sm font-medium text-gray-300 mb-1">Status</label>
            <select id="sensor-status" v-model="formData.status" class="w-full input-style">
                <option v-for="status in sensorStatuses" :key="status" :value="status">
                    {{ formatStatus(status) }}
                </option>
            </select>
        </div>

        <div class="pt-4 flex justify-end space-x-3">
            <button type="button" @click="$emit('cancel')"
                class="inline-flex justify-center rounded-md border border-gray-600 bg-gray-700 px-4 py-2 text-sm font-medium text-gray-300 hover:bg-gray-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-gray-500 focus-visible:ring-offset-2 focus-visible:ring-offset-gray-800">
                Cancel
            </button>
            <button type="submit" :disabled="isSubmitting"
                class="inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-orange-500 disabled:opacity-50">
                <AppSpinner v-if="isSubmitting" class="w-4 h-4 mr-2" />
                {{ isEditMode ? 'Update Sensor' : 'Add Sensor' }}
            </button>
        </div>
    </form>
</template>

<script setup lang="ts">
import { ref, reactive, watch, computed, defineProps, defineEmits } from 'vue';
import type { Sensor, Zone } from '~/types/api';
import { SensorStatus } from '~/types/api';
import AppSpinner from '~/components/ui/AppSpinner.vue';

const props = defineProps({
    initialData: { type: Object as () => Sensor | null, default: null },
    availableZones: { type: Array as () => Pick<Zone, 'id' | 'name'>[], default: () => [] },
    isSubmitting: { type: Boolean, default: false },
    initialError: { type: String as () => string | null, default: null }
});

const emit = defineEmits(['submit', 'cancel']);

type SensorFormData = Omit<Partial<Sensor>, 'zone' | 'logs' | 'latestLog' | 'activeAlert' | 'createdAt'> & { zoneId?: string | null };
const formData = reactive<SensorFormData>({
    id: undefined,
    name: '',
    type: '',
    location: '',
    threshold: null,
    sensitivity: null,
    status: SensorStatus.ACTIVE,
    latitude: null,
    longitude: null,
    zoneId: ''
});
const localError = ref<string | null>(props.initialError);

const isEditMode = computed(() => !!props.initialData?.id);
const sensorStatuses = Object.values(SensorStatus);

watch(() => props.initialData, (newData) => {
    localError.value = props.initialError;
    if (newData) {
        formData.id = newData.id;
        formData.name = newData.name || '';
        formData.type = newData.type || '';
        formData.location = newData.location || '';
        formData.threshold = newData.threshold ?? null;
        formData.sensitivity = newData.sensitivity ?? null;
        formData.status = newData.status || SensorStatus.ACTIVE;
        formData.latitude = newData.latitude ?? null;
        formData.longitude = newData.longitude ?? null;
        formData.zoneId = newData.zoneId || '';
    } else {
        formData.id = undefined;
        formData.name = '';
        formData.type = '';
        formData.location = '';
        formData.threshold = null;
        formData.sensitivity = null;
        formData.status = SensorStatus.ACTIVE;
        formData.latitude = null;
        formData.longitude = null;
        formData.zoneId = '';
    }
}, { immediate: true, deep: true });

const submitForm = () => {
    localError.value = null;

    if (!formData.name?.trim()) { localError.value = 'Sensor name is required.'; return; }
    if (!formData.type?.trim()) { localError.value = 'Sensor type is required.'; return; }
    if (!formData.location?.trim()) { localError.value = 'Location description is required.'; return; }
    if (!formData.zoneId) { localError.value = 'Please select a zone.'; return; }
    if (formData.latitude !== null && formData.latitude !== undefined && (formData.latitude < -90 || formData.latitude > 90)) { localError.value = 'Invalid latitude.'; return; }
    if (formData.longitude !== null && formData.longitude !== undefined && (formData.longitude < -180 || formData.longitude > 180)) { localError.value = 'Invalid longitude.'; return; }

    const dataToSubmit: Partial<SensorFormData> = {
        name: formData.name.trim(),
        type: formData.type.trim(),
        location: formData.location.trim(),
        threshold: formData.threshold,
        sensitivity: formData.sensitivity,
        status: formData.status,
        latitude: formData.latitude,
        longitude: formData.longitude,
        zoneId: formData.zoneId,
    };

    if (isEditMode.value) {
        dataToSubmit.id = formData.id;
    } else {
        if (dataToSubmit.status === SensorStatus.ACTIVE) {
            delete dataToSubmit.status;
        }
    }

    emit('submit', dataToSubmit);
};

const formatStatus = (status: SensorStatus): string => {
    switch (status) {
        case SensorStatus.ACTIVE: return 'Active';
        case SensorStatus.INACTIVE: return 'Inactive';
        case SensorStatus.ERROR: return 'Error';
        case SensorStatus.MAINTENANCE: return 'Maintenance';
        default: return status;
    }
};
</script>

<style scoped>
.input-style {
    appearance: none;
    position: relative;
    display: block;
    width: 100%;
    padding-left: 0.75rem;
    padding-right: 0.75rem;
    padding-top: 0.5rem;
    padding-bottom: 0.5rem;
    border-width: 1px;
    border-color: #4b5563;
    background-color: #374151;
    color: #ffffff;
    border-radius: 0.375rem;
    font-size: 0.875rem;
    line-height: 1.25rem;
}
.input-style::placeholder {
    color: #6b7280;
}
.input-style:focus {
    outline: 2px solid transparent;
    outline-offset: 2px;
    --tw-ring-color: #f97316;
    box-shadow: var(--tw-ring-inset) 0 0 0 calc(1px + var(--tw-ring-offset-width)) var(--tw-ring-color);
    border-color: #f97316;
}
select.input-style {
    background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e");
    background-position: right 0.5rem center;
    background-repeat: no-repeat;
    background-size: 1.5em 1.5em;
    padding-right: 2.5rem;
}
</style>
