<template>
    <div class="p-4 sm:p-6 lg:p-8">
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6 pb-3 border-b border-gray-700 gap-4">
            <h1 class="text-2xl font-semibold text-white">User Management</h1>
        </div>

        <div v-if="pending && !users" class="text-center py-20">
            <AppSpinner class="w-10 h-10 inline-block" />
            <p class="text-gray-400 mt-3">Loading user list...</p>
        </div>

        <div v-else-if="error" class="error-alert mb-6">
            <div class="flex items-center">
                <XCircleIcon class="h-5 w-5 mr-2 flex-shrink-0" />
                <span>Unable to load user list.</span>
            </div>
            <button @click="() => refresh()" class="text-sm font-medium text-orange-400 hover:underline">Retry</button>
        </div>

        <div v-else class="overflow-x-auto bg-gray-850 border border-gray-700 rounded-lg shadow">
            <table class="min-w-full divide-y divide-gray-700">
                <thead class="bg-gray-800">
                    <tr>
                        <th scope="col" class="px-4 py-3 text-left font-medium text-gray-400 uppercase tracking-wider">Name & Email</th>
                        <th scope="col" class="px-4 py-3 text-left font-medium text-gray-400 uppercase tracking-wider">Phone</th>
                        <th scope="col" class="px-4 py-3 text-center font-medium text-gray-400 uppercase tracking-wider">Status</th>
                        <th scope="col" class="px-4 py-3 text-center font-medium text-gray-400 uppercase tracking-wider">Role</th>
                        <th scope="col" class="px-4 py-3 text-right font-medium text-gray-400 uppercase tracking-wider">Actions</th>
                    </tr>
                </thead>
                <tbody class="bg-gray-850 divide-y divide-gray-700">
                    <tr v-if="!pending && (!users || users.length === 0)">
                        <td colspan="5" class="px-4 py-10 text-center text-sm text-gray-500 italic">No users found.</td>
                    </tr>
                    <tr v-for="usr in users ?? []" :key="usr.id" class="hover:bg-gray-800 transition-colors duration-150 ease-in-out">
                        <td class="px-4 py-3 whitespace-nowrap">
                            <div class="text-sm font-medium text-white">{{ usr.name }}</div>
                            <div class="text-xs text-gray-400">{{ usr.email }}</div>
                        </td>
                        <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-400">{{ usr.phone || '-' }}</td>
                        <td class="px-4 py-3 whitespace-nowrap text-center text-sm">
                            <span :class="usr.isActive ? 'bg-green-100/10 text-green-400 ...' : 'bg-red-100/10 text-red-400 ...'">
                                {{ usr.isActive ? 'Active' : 'Locked' }}
                            </span>
                        </td>
                        <td class="px-4 py-3 whitespace-nowrap text-center text-sm text-black">
                            <select
                                :id="'role-' + usr.id"
                                :value="usr.role"
                                @change="confirmRoleChange(usr, ($event.target as HTMLSelectElement)?.value as Role)"
                                :disabled="usr.id === currentUser?.id || isUpdating === usr.id"
                                class="py-1 px-2 border ... disabled:opacity-60 ..."
                                :class="{'opacity-50 animate-pulse': isUpdating === usr.id}"
                                title="Change role">
                                <option v-for="roleValue in roles" :key="roleValue" :value="roleValue">
                                    {{ roleValue }}
                                </option>
                            </select>
                        </td>
                        <td class="px-4 py-3 whitespace-nowrap text-right text-sm font-medium space-x-2">
                            <button @click="openDetailsModal(usr.id)" class="..." title="View details">
                                <EyeIcon class="h-5 w-5" />
                            </button>
                            <button v-if="usr.id !== currentUser?.id" @click="confirmToggleStatus(usr)" :disabled="isUpdating === usr.id" class="...">
                                <UserMinusIcon v-if="usr.isActive" class="h-5 w-5" />
                                <UserPlusIcon v-else class="h-5 w-5" />
                            </button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <UsersUserDetailsModal
            :is-open="showDetailsModal"
            :user-id="selectedUserId ?? undefined"
            @close="closeDetailsModal"
        />
    </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useApi } from '~/composables/useApi';
import { useAsyncData } from '#app';
import { useAuth } from '~/composables/useAuth';
import Swal from 'sweetalert2';
import 'sweetalert2/dist/sweetalert2.min.css';
import type { User, Role } from '~/types/api';
import { Role as RoleEnum } from '~/types/api';
import AppSpinner from '~/components/ui/AppSpinner.vue';
import UsersUserDetailsModal from '~/components/users/UserDetailsModal.vue';
import { EyeIcon, UserMinusIcon, UserPlusIcon, XCircleIcon } from '@heroicons/vue/24/outline';

definePageMeta({
    layout: 'default',
    middleware: ['auth']
});

const api = useApi();
const { user: currentUser } = useAuth();
const isUpdating = ref<string | null>(null);
const showDetailsModal = ref(false);
const selectedUserId = ref<string | null>(null);
const roles = Object.values(RoleEnum);

const { data: users, pending, error, refresh } = useAsyncData(
    'users-list',
    () => api.users.getAll(),
    { lazy: true, server: false }
);

const confirmRoleChange = (user: User, newRole: Role) => {
    const selectElement = document.getElementById(`role-${user.id}`) as HTMLSelectElement | null;
    if (newRole === user.role) return;
    Swal.fire({
        title: `Change role for "${user.name}"?`,
        text: `Are you sure you want to change the role from ${user.role} to ${newRole}?`,
        icon: 'warning',
        iconColor: '#f97316',
        showCancelButton: true,
        confirmButtonText: 'Confirm',
        cancelButtonText: 'Cancel',
        background: '#1f2937',
        color: '#d1d5db',
        confirmButtonColor: '#f97316',
        cancelButtonColor: '#4b5563',
        customClass: { popup: 'swal2-dark' }
    }).then((result) => {
        if (result.isConfirmed) {
            executeRoleChange(user.id, newRole);
        } else {
            if (selectElement) selectElement.value = user.role;
        }
    });
};

const executeRoleChange = async (userId: string, newRole: Role) => {
    isUpdating.value = userId;
    try {
        await api.auth.updateUserRole(userId, newRole);
        await refresh();
        Swal.fire({
            title: 'Success!',
            text: `Role updated to ${newRole}.`,
            icon: 'success',
            toast: true,
            position: 'top-end'
        });
    } catch (err: any) {
        Swal.fire({
            title: 'Failed!',
            text: err.data?.message || "Error updating role.",
            icon: 'error'
        });
        await refresh();
    } finally {
        isUpdating.value = null;
    }
};

const confirmToggleStatus = (user: User) => {
    const actionText = user.isActive ? 'lock' : 'activate';
    Swal.fire({
        title: `Are you sure?`,
        text: `Do you want to ${actionText} the account "${user.name}"?`
    }).then((result) => {
        if (result.isConfirmed) {
            executeToggleStatus(user);
        }
    });
};

const executeToggleStatus = async (userToToggle: User) => {
    if (isUpdating.value) return;
    isUpdating.value = userToToggle.id;
    try {
        await api.users.update(userToToggle.id, { isActive: !userToToggle.isActive });
        await refresh();
        const statusText = !userToToggle.isActive ? 'activated' : 'locked';
        Swal.fire({
            title: 'Success!',
            text: `Account "${userToToggle.name}" has been ${statusText}.`,
            icon: 'success',
            toast: true,
            position: 'top-end'
        });
    } catch (err: any) {
        Swal.fire({
            title: 'Failed!',
            text: err.data?.message || "Error changing user status.",
            icon: 'error'
        });
        await refresh();
    } finally {
        isUpdating.value = null;
    }
};

const openDetailsModal = (userId: string) => {
    selectedUserId.value = userId;
    showDetailsModal.value = true;
};

const closeDetailsModal = () => {
    showDetailsModal.value = false;
    selectedUserId.value = null;
};
</script>

<style scoped>
.error-alert {
    padding: 0.75rem;
    border-radius: 0.375rem;
    border-width: 1px;
    margin-bottom: 1.5rem;
    font-size: 0.875rem;
    display: flex;
    align-items: center;
    background-color: rgba(191, 27, 27, 0.1);
    border-color: rgba(220, 38, 38, 0.3);
    color: #fca5a5;
}

select:disabled {
    cursor: not-allowed;
}
</style>
