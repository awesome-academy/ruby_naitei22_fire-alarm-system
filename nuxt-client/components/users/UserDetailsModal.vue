<template>
    <AppModal :is-open="isOpen" @close="$emit('close')">
        <template #title>
            User Details {{ userId ? `#${userId.substring(0, 8)}...` : '' }}
        </template>

        <template #content>
            <div v-if="pending" class="text-center py-10">
                <AppSpinner />
                <p class="text-gray-400 mt-2">Loading user details...</p>
            </div>
            <div v-else-if="error" class="error-alert">
                <span>{{ error.data?.message || 'Unable to load user details.' }}</span>
                <button @click="fetchUserDetails" class="ml-2 underline text-sm">Retry</button>
            </div>
            <div v-else-if="userDetail" class="space-y-4 text-sm">
                <dl class="space-y-1.5">
                    <div class="flex">
                        <dt class="text-gray-400 w-28 flex-shrink-0">ID:</dt>
                        <dd class="text-gray-200 font-mono text-xs break-all">{{ userDetail.id }}</dd>
                    </div>
                    <div class="flex">
                        <dt class="text-gray-400 w-28 flex-shrink-0">Name:</dt>
                        <dd class="text-gray-200">{{ userDetail.name }}</dd>
                    </div>
                    <div class="flex">
                        <dt class="text-gray-400 w-28 flex-shrink-0">Email:</dt>
                        <dd class="text-gray-200">{{ userDetail.email }}</dd>
                    </div>
                    <div class="flex">
                        <dt class="text-gray-400 w-28 flex-shrink-0">Phone:</dt>
                        <dd class="text-gray-200">{{ userDetail.phone || '-' }}</dd>
                    </div>
                    <div class="flex">
                        <dt class="text-gray-400 w-28 flex-shrink-0">Address:</dt>
                        <dd class="text-gray-200">{{ userDetail.address || '-' }}</dd>
                    </div>
                    <div class="flex items-center">
                        <dt class="text-gray-400 w-28 flex-shrink-0">Status:</dt>
                        <dd>
                            <span
                                class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                                :class="userDetail.isActive ? 'bg-green-100/10 text-green-400 ring-1 ring-inset ring-green-500/20' : 'bg-red-100/10 text-red-400 ring-1 ring-inset ring-red-500/20'"
                            >
                                {{ userDetail.isActive ? 'Active' : 'Locked' }}
                            </span>
                        </dd>
                    </div>
                    <div class="flex">
                        <dt class="text-gray-400 w-28 flex-shrink-0">Role:</dt>
                        <dd class="text-gray-200 font-semibold">{{ userDetail.role }}</dd>
                    </div>
                    <div class="flex">
                        <dt class="text-gray-400 w-28 flex-shrink-0">Created At:</dt>
                        <dd class="text-gray-200">{{ formatDateTime(userDetail.createdAt) }}</dd>
                    </div>
                    <div class="flex">
                        <dt class="text-gray-400 w-28 flex-shrink-0">Last Updated:</dt>
                        <dd class="text-gray-200">{{ formatDateTime(userDetail.updatedAt) }}</dd>
                    </div>
                </dl>
            </div>
            <div v-else class="text-center py-10 text-gray-500">User information not found.</div>
        </template>

        <template #footer>
            <button
                type="button"
                class="inline-flex justify-center rounded-md border border-gray-600 bg-gray-700 px-4 py-2 text-sm font-medium text-gray-300 hover:bg-gray-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-gray-500 focus-visible:ring-offset-2 focus-visible:ring-offset-gray-800"
                @click="$emit('close')"
            >
                Close
            </button>
        </template>
    </AppModal>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';
import { useApi } from '~/composables/useApi';
import AppModal from '~/components/ui/AppModal.vue';
import AppSpinner from '~/components/ui/AppSpinner.vue';
import type { User } from '~/types/api';

const props = defineProps({
    isOpen: { type: Boolean, required: true },
    userId: { type: String, default: null },
});
defineEmits(['close']);

const api = useApi();

const userDetail = ref<User | null>(null);
const pending = ref(false);
const error = ref<any | null>(null);

const fetchUserDetails = async () => {
    if (!props.userId || pending.value) return;
    pending.value = true;
    error.value = null;
    try {
        userDetail.value = await api.users.getById(props.userId);
    } catch (err: any) {
        error.value = err;
    } finally {
        pending.value = false;
    }
};

const resetState = () => {
    userDetail.value = null;
    error.value = null;
    pending.value = false;
};

watch(
    () => props.isOpen,
    (newIsOpen) => {
        if (newIsOpen && props.userId) {
            fetchUserDetails();
        } else if (!newIsOpen) {
            resetState();
        }
    }
);

const formatDateTime = (dateTimeString: string | Date | undefined | null): string => {
    if (!dateTimeString) return 'N/A';
    try {
        return new Date(dateTimeString).toLocaleString('en-US', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
        });
    } catch {
        return 'Error';
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
    background-color: rgba(191, 27, 27, 0.1);
    border-color: rgba(220, 38, 38, 0.3);
    color: #fca5a5;
}
dl dt {
    flex-shrink: 0;
}
dl dd {
    word-break: break-word;
}
</style>
