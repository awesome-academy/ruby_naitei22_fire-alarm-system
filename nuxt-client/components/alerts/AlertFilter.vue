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
            <option value="0">Pending</option>
            <option value="1">Resolved</option>
            <option value="2">Ignored</option>
          </select>
        </div>
        <div>
          <label for="startDate" class="block text-sm font-medium text-gray-300 mb-1">From Date</label>
          <input
            type="date"
            id="startDate"
            v-model="filterParams.created_at_gteq"
            class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
            :max="filterParams.created_at_lteq"
          />
        </div>
        <div>
          <label for="endDate" class="block text-sm font-medium text-gray-300 mb-1">To Date</label>
          <input
            type="date"
            id="endDate"
            v-model="filterParams.created_at_lteq"
            class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
            :min="filterParams.created_at_gteq"
          />
        </div>
        <div class="flex items-end space-x-2">
          <button
            @click="applyFilters"
            class="w-full sm:w-auto inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-orange-500"
          >
            <FunnelIcon class="h-4 w-4 mr-2" />
            Filter
          </button>
          <button
            @click="resetFilters"
            class="w-full sm:w-auto inline-flex justify-center items-center px-4 py-2 border border-gray-600 text-sm font-medium rounded-md shadow-sm text-gray-300 bg-gray-700 hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-gray-500"
          >
            <XMarkIcon class="h-4 w-4 mr-2" />
            Clear
          </button>
        </div>
      </div>
      <div class="relative">
        <label for="message" class="sr-only">Search Message</label>
        <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
          <MagnifyingGlassIcon class="h-5 w-5 text-gray-400" aria-hidden="true" />
        </div>
        <input
          type="text"
          id="message"
          v-model="filterParams.message_cont"
          placeholder="Search by alert message..."
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
  message_cont: '',
  status_eq: null as number | null,
  created_at_gteq: '',
  created_at_lteq: '',
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
  filterParams.message_cont = '';
  filterParams.status_eq = null;
  filterParams.created_at_gteq = '';
  filterParams.created_at_lteq = '';
  emit('filter', {});
};
</script>
