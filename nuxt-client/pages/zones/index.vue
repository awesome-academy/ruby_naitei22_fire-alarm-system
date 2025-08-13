<template>
    <div class="p-4 sm:p-6 lg:p-8">
        <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-semibold text-white">Zone Management</h1>
            <button
                @click="openCreateModal"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-orange-600 hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-orange-500"
            >
                <PlusIcon class="h-5 w-5 mr-2" />
                Add New Zone
            </button>
        </div>

        <div v-if="pending && !zones" class="text-center py-20">
            <AppSpinner /> Loading zones...
        </div>
        <div v-else-if="error" class="error-alert">
            <span>{{ 'Failed to load zones.' }}</span>
            <button @click="refresh()" class="ml-auto text-sm">Retry</button>
        </div>
        <div v-else>
            <ZonesZoneTable :zones="zones ?? []" :loading="pending" @edit="openEditModal" @delete="openDeleteModal" />
        </div>
        
        <div v-if="actionError" class="error-alert mt-4">
            <XCircleIcon class="h-5 w-5 text-red-400 mr-2" />
            <span>{{ actionError }}</span>
        </div>

        <AppModal :is-open="showFormModal" @close="closeFormModal">
            <template #title>{{ isEditMode ? 'Edit Zone' : 'Add New Zone' }}</template>
            <template #content>
                <ZonesZoneForm
                    :initial-data="zoneToEdit"
                    :is-submitting="isSubmitting"
                    @submit="handleSubmitZone"
                    @cancel="closeFormModal"
                />
            </template>
            <template #footer><div></div></template>
        </AppModal>

        <AppModal :is-open="showDeleteConfirm" @close="cancelDelete">
            <template #title>Confirm Zone Deletion</template>
            <template #content>
                <p class="text-sm text-gray-400">
                    Are you sure you want to delete the zone <strong class="text-white">{{ zoneToDelete?.name }}</strong>? All related sensors and cameras will also be affected. This action cannot be undone.
                </p>
            </template>
            <template #footer>
                <button @click="confirmDelete" :disabled="deleting" class="btn-danger">
                    <AppSpinner v-if="deleting" class="w-4 h-4 mr-2" />
                    {{ deleting ? 'Deleting...' : 'Delete' }}
                </button>
                <button @click="cancelDelete" class="ml-3 btn-secondary">Cancel</button>
            </template>
        </AppModal>
    </div>
</template>

<script setup lang="ts">
import { ref, computed, nextTick } from 'vue';
import { useApi } from '~/composables/useApi';
import { useAsyncData } from '#app';
import ZonesZoneTable from '~/components/zones/ZoneTable.vue';
import ZonesZoneForm from '~/components/zones/ZoneForm.vue';
import AppModal from '~/components/ui/AppModal.vue';
import AppSpinner from '~/components/ui/AppSpinner.vue';
import { XCircleIcon, PlusIcon } from '@heroicons/vue/20/solid';
import type { Zone } from '~/types/api';
import Swal from 'sweetalert2';

definePageMeta({
    layout: 'default',
    middleware: ['auth'],
});

const api = useApi();

const { data: zones, pending, error, refresh } = useAsyncData(
    'zones-list',
    () => api.zones.getAll(),
    { lazy: true, server: false }
);

const actionError = ref<string | null>(null);

const showFormModal = ref(false);
const zoneToEdit = ref<Zone | null>(null);
const isSubmitting = ref(false);

const showDeleteConfirm = ref(false);
const zoneToDelete = ref<Zone | null>(null);
const deleting = ref(false);

const isEditMode = computed(() => !!zoneToEdit.value);

const openCreateModal = () => {
    zoneToEdit.value = null;
    showFormModal.value = true;
};

const openEditModal = (zone: Zone) => {
    zoneToEdit.value = { ...zone };
    showFormModal.value = true;
};

const closeFormModal = () => {
    showFormModal.value = false;
    actionError.value = null;
    nextTick(() => {
        zoneToEdit.value = null;
    });
};

const handleSubmitZone = async (formData: Partial<Zone>) => {
    isSubmitting.value = true;
    actionError.value = null;
    try {
        if (isEditMode.value && zoneToEdit.value?.id) {
            await api.zones.update(zoneToEdit.value.id, formData);
        } else {
            await api.zones.create(formData);
        }
        await refresh();
        closeFormModal();
        Swal.fire({
            toast: true,
            icon: 'success',
            title: `Zone ${isEditMode.value ? 'updated' : 'created'}!`,
        });
    } catch (err: any) {
        actionError.value = err.data?.message || `Unable to ${isEditMode.value ? 'update' : 'add'} zone.`;
    } finally {
        isSubmitting.value = false;
    }
};

const openDeleteModal = (zone: Zone) => {
    zoneToDelete.value = zone;
    showDeleteConfirm.value = true;
};

const cancelDelete = () => {
    showDeleteConfirm.value = false;
    actionError.value = null;
    nextTick(() => { zoneToDelete.value = null; });
};

const confirmDelete = async () => {
    if (!zoneToDelete.value) return;
    deleting.value = true;
    actionError.value = null;
    try {
        await api.zones.delete(zoneToDelete.value.id);
        await refresh();
        cancelDelete();
        Swal.fire({
            toast: true,
            icon: 'success',
            title: 'Zone deleted!',
        });
    } catch (err: any) {
        actionError.value = err.data?.message || `Unable to delete zone. It may have linked items.`;
    } finally {
        deleting.value = false;
    }
};
</script>

<style scoped>
.error-alert { 
    @apply bg-red-800 text-red-200 p-4 rounded-md mb-4 flex items-center;
}
.btn-danger {
    @apply bg-red-600 text-white hover:bg-red-700 focus:ring-red-500;
}
.btn-secondary {
    @apply bg-gray-600 text-white hover:bg-gray-700 focus:ring-gray-500;
}
</style>
