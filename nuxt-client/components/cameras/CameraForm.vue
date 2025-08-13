<template>
    <form @submit.prevent="submitForm" class="space-y-5">
        <div v-if="localError || initialError" class="rounded-md bg-red-100 p-3 border border-red-300">
            <p class="text-sm font-medium text-red-800">{{ localError || initialError }}</p>
        </div>

        <div>
            <label for="cam-name" class="input-label">Camera Name <span class="text-red-500">*</span></label>
            <input type="text" id="cam-name" v-model="formData.name" required placeholder="e.g., Hallway Camera A1" class="input-field w-full mt-1" />
        </div>

        <div>
            <label for="cam-url" class="input-label">Stream/Snapshot URL <span class="text-red-500">*</span></label>
            <input type="text" id="cam-url" v-model="formData.url" required placeholder="e.g., rtsp://... or http://.../snapshot" class="input-field w-full mt-1" />
            <p class="mt-1 text-xs text-gray-500">Enter an RTSP or HTTP snapshot URL accessible by the system.</p>
        </div>

        <div>
            <label for="cam-zone" class="input-label">Zone <span class="text-red-500">*</span></label>
            <select id="cam-zone" v-model="formData.zoneId" required class="input-field w-full mt-1">
                <option disabled value="">-- Select Zone --</option>
                <option v-if="availableZones.length === 0" disabled>Loading or no zones available...</option>
                <option v-for="zone in availableZones" :key="zone.id" :value="zone.id">{{ zone.name }}</option>
            </select>
        </div>

        <fieldset class="border border-gray-700 rounded p-4 pt-2">
            <legend class="text-sm font-medium text-gray-400 px-1">Geographical Coordinates (Optional)</legend>
            <p class="text-xs text-gray-500 mb-3">Enter to display accurately on the Leaflet map.</p>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-3">
                <div>
                    <label for="cam-latitude" class="block text-xs font-medium text-gray-300 mb-1">Latitude</label>
                    <input type="number" step="any" id="cam-latitude" v-model.number="formData.latitude" placeholder="e.g., 10.7755" min="-90" max="90" class="input-field w-full" />
                </div>
                <div>
                    <label for="cam-longitude" class="block text-xs font-medium text-gray-300 mb-1">Longitude</label>
                    <input type="number" step="any" id="cam-longitude" v-model.number="formData.longitude" placeholder="e.g., 106.7019" min="-180" max="180" class="input-field w-full" />
                </div>
            </div>
        </fieldset>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
            <div v-if="isEditMode">
                <label for="cam-status" class="input-label">Camera Status</label>
                <select id="cam-status" v-model="formData.status" class="input-field w-full mt-1">
                    <option v-for="status in cameraStatuses" :key="status" :value="status">{{ formatStatus(status) }}</option>
                </select>
                <p class="mt-1 text-xs text-gray-500">Specify the operational status of the camera.</p>
            </div>
            <div>
                <label class="input-label">AI Fire Detection</label>
                <div class="mt-2 flex items-center">
                    <Switch v-model="formData.isDetecting" :class="formData.isDetecting ? 'bg-orange-600' : 'bg-gray-600'" class="relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 focus:ring-offset-gray-800">
                        <span class="sr-only">Toggle fire detection</span>
                        <span aria-hidden="true" :class="formData.isDetecting ? 'translate-x-5' : 'translate-x-0'" class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out" />
                    </Switch>
                    <span class="ml-3 text-sm font-medium" :class="formData.isDetecting ? 'text-orange-300' : 'text-gray-400'">
                        {{ formData.isDetecting ? 'Enabled' : 'Disabled' }}
                    </span>
                </div>
                <p class="mt-1 text-xs text-gray-500">Enable to allow the AI system to scan images from this camera.</p>
            </div>
        </div>

        <div class="pt-5 flex justify-end space-x-3 border-t border-gray-700">
            <button type="button" @click="$emit('cancel')" class="btn-secondary">Cancel</button>
            <button type="submit" :disabled="isSubmitting" class="btn-primary inline-flex items-center">
                <AppSpinner v-if="isSubmitting" class="w-4 h-4 mr-2" />
                {{ isEditMode ? 'Update Camera' : 'Add Camera' }}
            </button>
        </div>
    </form>
</template>

<script setup lang="ts">
import { ref, reactive, watch, computed, defineProps, defineEmits } from 'vue';
import { Switch } from '@headlessui/vue';
import type { Camera, Zone } from '~/types/api';
import { CameraStatus } from '~/types/api';
import AppSpinner from '~/components/ui/AppSpinner.vue';

const props = defineProps({
    initialData: { type: Object as () => Camera | null, default: null },
    availableZones: { type: Array as () => Pick<Zone, 'id' | 'name'>[], default: () => [] },
    isSubmitting: { type: Boolean, default: false },
    initialError: { type: String as () => string | null, default: null }
});

const emit = defineEmits(['submit', 'cancel']);

type CameraFormData = Omit<Partial<Camera>, 'zone' | 'alerts' | 'createdAt'> & { zoneId?: string | null };
const formData = reactive<CameraFormData>({
    id: undefined,
    name: '',
    url: '',
    zoneId: '',
    latitude: null,
    longitude: null,
    status: CameraStatus.ONLINE,
    isDetecting: false,
});
const localError = ref<string | null>(props.initialError);
const cameraStatuses = Object.values(CameraStatus);
const isEditMode = computed(() => !!props.initialData?.id);

watch(() => props.initialData, (newData) => {
    localError.value = props.initialError;
    if (newData) {
        formData.id = newData.id;
        formData.name = newData.name || '';
        formData.url = newData.url || '';
        formData.zoneId = newData.zoneId || '';
        formData.latitude = newData.latitude ?? null;
        formData.longitude = newData.longitude ?? null;
        formData.status = newData.status || CameraStatus.ONLINE;
        formData.isDetecting = newData.isDetecting ?? false;
    } else {
        formData.id = undefined;
        formData.name = '';
        formData.url = '';
        formData.zoneId = '';
        formData.latitude = null;
        formData.longitude = null;
        formData.status = CameraStatus.ONLINE;
        formData.isDetecting = false;
    }
}, { immediate: true, deep: true });

const submitForm = () => {
    localError.value = null;

    if (!formData.name?.trim()) { localError.value = 'Camera name is required.'; return; }
    if (!formData.url?.trim()) { localError.value = 'URL is required.'; return; }
    const urlPattern = /^(rtsp|http|https):\/\/.+/;
    if (!urlPattern.test(formData.url.trim())) { localError.value = 'Invalid URL format (must start with rtsp:// or http(s)://).'; return; }
    if (!formData.zoneId) { localError.value = 'Please select a zone.'; return; }
    if (formData.latitude !== null && formData.latitude !== undefined && (formData.latitude < -90 || formData.latitude > 90)) { localError.value = 'Invalid latitude (-90 to 90).'; return; }
    if (formData.longitude !== null && formData.longitude !== undefined && (formData.longitude < -180 || formData.longitude > 180)) { localError.value = 'Invalid longitude (-180 to 180).'; return; }

    const dataToSubmit: Partial<CameraFormData> = {
        name: formData.name.trim(),
        url: formData.url.trim(),
        zoneId: formData.zoneId,
        latitude: formData.latitude,
        longitude: formData.longitude,
        isDetecting: formData.isDetecting,
        status: formData.status
    };

    if (isEditMode.value) {
        dataToSubmit.id = formData.id;
    } else {
        if (dataToSubmit.status === CameraStatus.ONLINE) {
            delete dataToSubmit.status;
        }
    }

    emit('submit', dataToSubmit);
};

const formatStatus = (status: CameraStatus): string => {
    switch (status) {
        case CameraStatus.ONLINE: return 'Online';
        case CameraStatus.OFFLINE: return 'Offline';
        case CameraStatus.RECORDING: return 'Recording';
        case CameraStatus.ERROR: return 'Error';
        default: return status;
    }
};
</script>

<style scoped>
.input-label {
    display: block;
    font-size: 0.875rem;
    font-weight: 500;
    color: #d1d5db;
    margin-bottom: 0.25rem;
}
.input-field {
    appearance: none;
    position: relative;
    display: block;
    width: 100%;
    padding: 0.5rem 0.75rem;
    border-width: 1px;
    border-color: #4b5563;
    background-color: #374151;
    color: #ffffff;
    border-radius: 0.375rem;
    font-size: 0.875rem;
    line-height: 1.25rem;
    transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;
}
.input-field::placeholder {
    color: #6b7280;
}
.input-field:focus {
    outline: 2px solid transparent;
    outline-offset: 2px;
    --tw-ring-color: #f97316;
    box-shadow: var(--tw-ring-inset) 0 0 0 calc(1px + var(--tw-ring-offset-width)) var(--tw-ring-color);
    border-color: #f97316;
}
select.input-field {
    background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%239ca3af' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8l4 4 4-4'/%3e%3c/svg%3e");
    background-position: right 0.5rem center;
    background-repeat: no-repeat;
    background-size: 1.5em 1.5em;
    padding-right: 2.5rem;
}
.btn-primary {
    background-color: #ea580c;
}
.btn-primary:hover {
    background-color: #c2410c;
}
.btn-primary:disabled {
    background-color: rgba(191, 79, 11, 0.5);
    cursor: not-allowed;
}
.btn-secondary {
    background-color: #374151;
    border-color: #4b5563;
    color: #d1d5db;
}
.btn-secondary:hover {
    background-color: #4b5563;
}
</style>
