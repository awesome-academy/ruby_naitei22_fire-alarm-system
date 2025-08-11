<template>
    <form @submit.prevent="submitForm" class="space-y-4">
        <div v-if="localError" class="rounded-md bg-red-100 p-3 border border-red-300 mb-4">
            <p class="text-sm font-medium text-red-800">{{ localError }}</p>
        </div>

        <div>
            <label for="zone-name" class="block text-sm font-medium text-gray-300 mb-1">
                Zone Name <span class="text-red-500">*</span>
            </label>
            <input
                type="text"
                id="zone-name"
                v-model="formData.name"
                required
                placeholder="Example: Floor 1 - Rack Area A"
                class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent sm:text-sm"
            />
        </div>

        <div>
            <label for="zone-description" class="block text-sm font-medium text-gray-300 mb-1">Description</label>
            <textarea
                id="zone-description"
                v-model="formData.description"
                rows="3"
                placeholder="Detailed description of the area, purpose of use..."
                class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent sm:text-sm"
            ></textarea>
        </div>

        <div>
            <label for="zone-city" class="block text-sm font-medium text-gray-300 mb-1">City</label>
            <input
                type="text"
                id="zone-city"
                v-model="formData.city"
                placeholder="Example: Ho Chi Minh City, Hanoi"
                class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent sm:text-sm"
            />
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
                <label for="zone-latitude" class="block text-sm font-medium text-gray-300 mb-1">Latitude</label>
                <input
                    type="number"
                    step="any"
                    id="zone-latitude"
                    v-model.number="formData.latitude"
                    placeholder="Example: 10.7769"
                    min="-90" max="90"
                    class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent sm:text-sm"
                />
                <p class="mt-1 text-xs text-gray-500">Value must be between -90 and 90.</p>
            </div>
            <div>
                <label for="zone-longitude" class="block text-sm font-medium text-gray-300 mb-1">Longitude</label>
                <input
                    type="number"
                    step="any"
                    id="zone-longitude"
                    v-model.number="formData.longitude"
                    placeholder="Example: 106.7009"
                    min="-180" max="180"
                    class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent sm:text-sm"
                />
                <p class="mt-1 text-xs text-gray-500">Value must be between -180 and 180.</p>
            </div>
        </div>
        <p class="text-xs text-gray-500 -mt-2 px-1">
            Get accurate coordinates from <a href="https://www.google.com/maps" target="_blank" rel="noopener noreferrer" class="text-orange-400 hover:underline">Google Maps</a> or similar tools for correct display on the Leaflet map.
        </p>

        <div class="pt-4 flex justify-end space-x-3">
            <button
                type="button"
                @click="$emit('cancel')"
                class="inline-flex justify-center rounded-md border border-gray-600 bg-gray-700 px-4 py-2 text-sm font-medium text-gray-300 hover:bg-gray-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-gray-500 focus-visible:ring-offset-2 focus-visible:ring-offset-gray-800"
            >
                Cancel
            </button>
            <button
                type="submit"
                :disabled="isSubmitting"
                class="inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-orange-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
                <AppSpinner v-if="isSubmitting" class="w-4 h-4 mr-2"/>
                {{ isEditMode ? 'Update Zone' : 'Add Zone' }}
            </button>
        </div>
    </form>
</template>

<script setup lang="ts">
import { ref, reactive, watch, computed, defineProps, defineEmits } from 'vue';
import type { Zone } from '~/types/api';
import AppSpinner from '~/components/ui/AppSpinner.vue';

const props = defineProps({
    initialData: {
        type: Object as () => Zone | null,
        default: null,
    },
    isSubmitting: {
        type: Boolean,
        default: false,
    },
});

const emit = defineEmits(['submit', 'cancel']);

const formData = reactive<Partial<Zone>>({
    id: undefined,
    name: '',
    description: '',
    city: '',
    latitude: null,
    longitude: null,
});
const localError = ref<string | null>(null);

const isEditMode = computed(() => !!props.initialData?.id);

watch(() => props.initialData, (newData) => {
    if (newData) {
        formData.id = newData.id;
        formData.name = newData.name || '';
        formData.description = newData.description || '';
        formData.city = newData.city || '';
        formData.latitude = newData.latitude ?? null;
        formData.longitude = newData.longitude ?? null;
    } else {
        formData.id = undefined;
        formData.name = '';
        formData.description = '';
        formData.city = '';
        formData.latitude = null;
        formData.longitude = null;
    }
}, {
    immediate: true,
    deep: true
});

const submitForm = () => {
    localError.value = null;

    if (!formData.name || formData.name.trim() === '') {
        localError.value = 'Zone name is required.';
        return;
    }
    if (formData.latitude !== null && formData.latitude !== undefined && (formData.latitude < -90 || formData.latitude > 90)) {
        localError.value = 'Latitude must be between -90 and 90.';
        return;
    }
    if (formData.longitude !== null && formData.longitude !== undefined && (formData.longitude < -180 || formData.longitude > 180)) {
        localError.value = 'Longitude must be between -180 and 180.';
        return;
    }

    const dataToSubmit: Omit<Partial<Zone>, 'createdAt' | 'sensors' | 'cameras' | '_count'> = {
        name: formData.name.trim(),
        description: formData.description?.trim() || null,
        city: formData.city?.trim() || null,
        latitude: formData.latitude,
        longitude: formData.longitude,
    };

    if (isEditMode.value) {
        dataToSubmit.id = formData.id;
    }

    emit('submit', dataToSubmit);
};
</script>

<style scoped>
</style>
