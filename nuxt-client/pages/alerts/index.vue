<template>
  <div>
    <AlertsAlertFilter @filter="applyFilters" />

    <div class="mt-6">
      <div v-if="pending && !paginatedResponse" class="text-center py-10">
        <AppSpinner class="inline-block w-8 h-8" />
        <p class="text-gray-400 mt-2">Loading alerts...</p>
      </div>
      
      <div v-else-if="error" class="error-alert">
        <div class="flex items-center">
          <XCircleIcon class="h-5 w-5 mr-2" />
          <span>{{ 'An unknown error occurred.' }}</span>
        </div>
        <button @click="() => refresh()" class="text-sm font-medium text-orange-300 hover:underline ml-4">Retry</button>
      </div>

      <div v-else>
        <AlertsAlertTable
          :alerts="alerts"
          :loading="pending"
          @view-details="handleViewDetails"
          @update-status="handleUpdateStatusRequest"
        />

        <UiPaginationControls
          v-if="totalAlerts > (queryParams.limit || 10)"
          class="mt-4"
          :current-page="queryParams.page"
          :items-per-page="queryParams.limit || 10"
          :total-items="totalAlerts"
          @page-change="handlePageChange"
        />
      </div>
    </div>

    <AlertsAlertDetailsModal
      :is-open="showDetailsModal"
      :alert-id="selectedAlertId ?? undefined"
      @close="closeDetailsModal"
      @updated="handleAlertUpdated"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRoute, useRouter } from '#app';
import { useApi } from '~/composables/useApi';
import { useAsyncData } from '#app';
import AlertsAlertTable from '~/components/alerts/AlertTable.vue';
import AlertsAlertFilter from '~/components/alerts/AlertFilter.vue';
import UiPaginationControls from '~/components/ui/PaginationControls.vue';
import AlertsAlertDetailsModal from '~/components/alerts/AlertDetailsModal.vue';
import AppSpinner from '~/components/ui/AppSpinner.vue';
import { XCircleIcon } from '@heroicons/vue/20/solid';
import { type AlertStatus } from '~/types/api';
import Swal from 'sweetalert2';

definePageMeta({
  layout: 'default',
  middleware: ['auth'],
});

const api = useApi();
const route = useRoute();
const router = useRouter();

const showDetailsModal = ref(false);
const selectedAlertId = ref<string | null>(null);
const isUpdatingStatus = ref(false);

const queryParams = computed(() => {
  const params: Record<string, any> = {
    page: parseInt(route.query.page as string || '1', 10),
    limit: parseInt(route.query.limit as string || '10', 10),
  };
  if (route.query.status) params.status = route.query.status;
  if (route.query.startDate) params.startDate = route.query.startDate;
  if (route.query.endDate) params.endDate = route.query.endDate;
  return params;
});

const { data: paginatedResponse, pending, error, refresh } = useAsyncData(
  'alerts-list',
  () => api.alerts.getAll(queryParams.value),
  { 
  watch: [queryParams],
  lazy: true,
  server: false,
  }
);

const alerts = computed(() => paginatedResponse.value?.data || []);
const totalAlerts = computed(() => paginatedResponse.value?.total || 0);

const applyFilters = (filters: Record<string, string>) => {
  const newQuery = { ...filters, page: '1' };
  router.push({ query: newQuery });
};

const handlePageChange = (newPage: number) => {
  router.push({ query: { ...route.query, page: newPage.toString() } });
};

const handleUpdateStatusRequest = async (payload: { id: string; status: AlertStatus }) => {
  if (isUpdatingStatus.value) return;
  isUpdatingStatus.value = true;
  try {
    await api.alerts.updateStatus(payload.id, payload.status);
    await refresh();
    Swal.fire({
      toast: true,
      position: 'top-end',
      icon: 'success',
      title: 'Status updated!',
      showConfirmButton: false,
      timer: 1500,
      background: '#1f2937',
      color: '#d1d5db',
    });
  } catch (err: any) {
    Swal.fire({
      icon: 'error',
      title: 'Update Failed',
      text: err.data?.message || 'Could not update alert status.',
      background: '#1f2937',
      color: '#d1d5db',
      confirmButtonColor: '#f97316',
    });
  } finally {
    isUpdatingStatus.value = false;
  }
};

const handleViewDetails = (alertId: string) => {
  selectedAlertId.value = alertId;
  showDetailsModal.value = true;
};

const closeDetailsModal = () => {
  showDetailsModal.value = false;
  selectedAlertId.value = null;
};

const handleAlertUpdated = () => {
  refresh();
};
</script>

<style scoped>
.error-alert {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
  border-radius: 0.375rem;
  border-width: 1px;
  font-size: 0.875rem;
  line-height: 1.25rem;
  background-color: rgba(191, 27, 27, 0.1);
  border-color: rgba(220, 38, 38, 0.3);
  color: #fca5a5;
}
</style>
