<template>
    <div class="mb-6 p-4 bg-gray-800 border border-gray-700 rounded-lg shadow">
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div>
          <label for="status" class="block text-sm font-medium text-gray-300 mb-1">Status</label>
          <select
            id="status"
            v-model="filterParams.status"
            class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
          >
            <option value="">All</option>
            <option v-for="status in alertStatuses" :key="status" :value="status">
              {{ formatStatus(status) }}
            </option>
          </select>
        </div>
  
        <div>
          <label for="startDate" class="block text-sm font-medium text-gray-300 mb-1">From Date</label>
          <input
            type="date"
            id="startDate"
            v-model="filterParams.startDate"
            class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
            :max="filterParams.endDate"
          />
        </div>
        <div>
          <label for="endDate" class="block text-sm font-medium text-gray-300 mb-1">To Date</label>
          <input
            type="date"
            id="endDate"
            v-model="filterParams.endDate"
            class="w-full px-3 py-2 border border-gray-600 bg-gray-700 text-white rounded-md focus:outline-none focus:ring-orange-500 focus:border-orange-500 sm:text-sm"
            :min="filterParams.startDate"
          />
        </div>
  
        <div class="flex items-end space-x-2 col-span-1 lg:col-span-1">
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
    </div>
  </template>
  
  <script setup lang="ts">
  import { ref, reactive, defineEmits } from 'vue';
  import { FunnelIcon, XMarkIcon } from '@heroicons/vue/20/solid';
  enum AlertStatus {
    PENDING = 'PENDING',
    RESOLVED = 'RESOLVED',
    IGNORED = 'IGNORED',
  }
  
  const alertStatuses = Object.values(AlertStatus) as AlertStatus[];
  const emit = defineEmits(['filter']);
  
  const filterParams = reactive({
    status: '' as AlertStatus | '',
    startDate: '',
    endDate: '',
    sensorId: '',
  });
  
  const formatStatus = (status: AlertStatus): string => {
     switch (status) {
      case AlertStatus.PENDING: return 'Pending';
      case AlertStatus.RESOLVED: return 'Resolved';
      case AlertStatus.IGNORED: return 'Ignored';
      default: return status;
    }
  };
  
  const applyFilters = () => {
    const activeFilters: Record<string, string> = {};
    if (filterParams.status) activeFilters.status = filterParams.status;
    if (filterParams.startDate) activeFilters.startDate = filterParams.startDate;
    if (filterParams.endDate) activeFilters.endDate = filterParams.endDate;
    emit('filter', activeFilters);
  };
  
  const resetFilters = () => {
    filterParams.status = '';
    filterParams.startDate = '';
    filterParams.endDate = '';
    filterParams.sensorId = '';
    emit('filter', {});
  };
  </script>
