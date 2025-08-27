<template>
    <div class="mb-6 p-4 bg-gray-800 border border-gray-700 rounded-lg shadow">
        <div class="flex flex-col gap-4">
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                <div>
                    <label for="status" class="block text-sm font-medium text-gray-300 mb-1">Status</label>
                    <select
                        id="status"
                        v-model="filterParams.status_eq"
                        class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
                    >
                        <option :value="null">All</option>
                        <option value="0">Active</option>
                        <option value="1">Inactive</option>
                        <option value="2">Error</option>
                    </select>
                </div>
                <div>
                    <label for="threshold_gt" class="block text-sm font-medium text-gray-300 mb-1">Threshold Above</label>
                    <input
                        type="number"
                        id="threshold_gt"
                        v-model.number="filterParams.threshold_gt"
                        placeholder="e.g., 50"
                        class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
                    />
                </div>
                <div class="hidden lg:block"></div>
                <div class="flex items-end space-x-2">
                    <button @click="applyFilters" class="btn-primary w-full">
                        <FunnelIcon class="h-4 w-4 mr-2" />
                        Filter
                    </button>
                    <button @click="resetFilters" class="btn-secondary w-full">
                        <XMarkIcon class="h-4 w-4 mr-2" />
                        Clear
                    </button>
                </div>
            </div>
            <div class="relative">
                <label for="name_or_location_cont" class="sr-only">Search by Name or Location</label>
                <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                    <MagnifyingGlassIcon class="h-5 w-5 text-gray-400" aria-hidden="true" />
                </div>
                <input
                    type="text"
                    id="name_or_location_cont"
                    v-model="filterParams.name_or_location_cont"
                    placeholder="Search by sensor name or location..."
                    class="w-full pl-10 pr-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
                    @keyup.enter="applyFilters"
                />
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { reactive, defineEmits } from 'vue';
import { FunnelIcon, XMarkIcon, MagnifyingGlassIcon } from '@heroicons/vue/20/solid';

const emit = defineEmits(['filter']);

const filterParams = reactive({
    name_or_location_cont: '',
    status_eq: null as number | null,
    threshold_gt: '' as number | '',
});

const applyFilters = () => {
    const activeFilters: Record<string, any> = {};
    for (const key in filterParams) {
        const value = filterParams[key as keyof typeof filterParams];
        if (value !== '' && value !== null) {
            activeFilters[key] = value;
        }
    }
    emit('filter', activeFilters);
};

const resetFilters = () => {
    filterParams.name_or_location_cont = '';
    filterParams.status_eq = null;
    filterParams.threshold_gt = '';
    emit('filter', {});
};
</script>

<style scoped>
.btn-primary {
    display: inline-flex;
    justify-content: center;
    align-items: center;
    padding: 0.5rem 1rem;
    border-radius: 0.375rem;
    background-color: #ea580c;
    color: #ffffff;
    font-size: 0.875rem;
    font-weight: 500;
    transition: background-color 0.2s;
}
.btn-primary:hover {
    background-color: #c2410c;
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
    transition: background-color 0.2s;
}
.btn-secondary:hover {
    background-color: #374151;
}
</style>
