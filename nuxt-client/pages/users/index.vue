<template>
    <div class="p-4 sm:p-6 lg:p-8">
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6 pb-3 border-b border-gray-700 gap-4">
            <h1 class="text-2xl font-semibold text-white">User Management</h1>
            <button
                @click="openInvitationModal"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-gray-800 focus:ring-blue-500"
            >
                <PaperAirplaneIcon class="h-5 w-5 mr-2" />
                Create Invitation
            </button>
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
                    <tr
                        v-for="usr in users ?? []"
                        :key="usr.id"
                        class="hover:bg-gray-800 transition-colors duration-150 ease-in-out"
                    >
                        <td class="px-4 py-3 whitespace-nowrap">
                            <div class="text-sm font-medium text-white">{{ usr.name }}</div>
                            <div class="text-xs text-gray-400">{{ usr.email }}</div>
                        </td>
                        <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-400">{{ usr.phone || '-' }}</td>
                        <td class="px-4 py-3 whitespace-nowrap text-center text-sm">
                            <span :class="usr.isActive ? 'bg-green-100/10 text-green-400' : 'bg-red-100/10 text-red-400'">
                                {{ usr.isActive ? 'Active' : 'Locked' }}
                            </span>
                        </td>
                        <td class="px-4 py-3 whitespace-nowrap text-center text-sm text-black">
                            <select
                                :id="'role-' + usr.id"
                                :value="usr.role"
                                @change="confirmRoleChange(usr, ($event.target as HTMLSelectElement)?.value as Role)"
                                :disabled="usr.id === currentUser?.id || isUpdating === usr.id"
                                class="py-1 px-2 border disabled:opacity-60"
                                :class="{'opacity-50 animate-pulse': isUpdating === usr.id}"
                                title="Change role"
                            >
                                <option v-for="roleValue in roles" :key="roleValue" :value="roleValue">
                                    {{ roleValue }}
                                </option>
                            </select>
                        </td>
                        <td class="px-4 py-3 whitespace-nowrap text-right text-sm font-medium space-x-2">
                            <button
                                @click="openDetailsModal(usr.id)"
                                class="p-1.5 rounded-full text-gray-400 hover:bg-gray-700 hover:text-white transition-colors"
                                title="View details"
                            >
                                <EyeIcon class="h-5 w-5" />
                            </button>
                            <button
                                v-if="usr.id !== currentUser?.id"
                                @click="confirmToggleStatus(usr)"
                                :disabled="isUpdating === usr.id"
                                class="p-1.5 rounded-full text-gray-400 hover:bg-gray-700 hover:text-white transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                                :title="usr.isActive ? 'Lock Account' : 'Activate Account'"
                            >
                                <UserMinusIcon v-if="usr.isActive" class="h-5 w-5 text-red-400" />
                                <UserPlusIcon v-else class="h-5 w-5 text-green-400" />
                            </button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useApi } from '~/composables/useApi';
import { useAsyncData } from '#app';
import { useAuth } from '~/composables/useAuth';
import Swal from 'sweetalert2';
import 'sweetalert2/dist/sweetalert2.min.css';
import type { User, Role } from '~/types/api';
import { Role as RoleEnum } from '~/types/api';
import AppSpinner from '~/components/ui/AppSpinner.vue';
import { EyeIcon, UserMinusIcon, UserPlusIcon, XCircleIcon, PaperAirplaneIcon } from '@heroicons/vue/24/outline';

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

const { data: paginatedResponse, pending, error, refresh } = useAsyncData(
    'users-list',
    () => api.users.getAll(),
    { lazy: true, server: false }
);
const users = computed(() => paginatedResponse.value?.data || []);

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

const openInvitationModal = () => {
    Swal.fire({
        title: 'Create a New Invitation',
        text: 'Enter the email address of the person you want to invite.',
        input: 'email',
        inputLabel: 'Email address',
        inputPlaceholder: 'supervisor@example.com',
        showCancelButton: true,
        confirmButtonText: 'Send Invitation',
        showLoaderOnConfirm: true,
        background: '#1f2937',
        color: '#d1d5db',
        confirmButtonColor: '#2563eb',
        cancelButtonColor: '#4b5563',
        customClass: { popup: 'swal2-dark' },
        preConfirm: async (email) => {
            if (!email) {
                Swal.showValidationMessage(`Please enter an email address`);
                return;
            }
            try {
                const response = await api.invitations.create(email);
                return response;
            } catch (error: any) {
                const errorMessage = error.data?.errors?.join(', ') || 'Failed to send invitation.';
                Swal.showValidationMessage(`Request failed: ${errorMessage}`);
            }
        },
        allowOutsideClick: () => !Swal.isLoading()
    }).then((result) => {
        if (result.isConfirmed) {
            Swal.fire({
                icon: 'success',
                title: 'Invitation Sent!',
                text: `An invitation has been successfully sent to ${result.value.invitation.email}.`,
                background: '#1f2937',
                color: '#d1d5db',
                confirmButtonColor: '#f97316',
                customClass: { popup: 'swal2-dark' }
            });
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
    Swal.fire({
        title: 'Loading User Details...',
        html: '<div class="flex justify-center items-center p-4"><svg class="animate-spin h-8 w-8 text-orange-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg></div>',
        showConfirmButton: false,
        background: '#1f2937',
        color: '#d1d5db',
        customClass: { popup: 'swal2-dark' },
        allowOutsideClick: false,
        didOpen: async () => {
            try {
                const userDetail = await api.users.getById(userId);
                const formatDateTime = (dateString: string | Date) => new Date(dateString).toLocaleString('en-US');
                const statusClass = userDetail.isActive ? 'text-green-400' : 'text-red-400';
                const statusText = userDetail.isActive ? 'Active' : 'Locked';
                const contentHtml = `
                    <div class="text-left text-sm space-y-2 swal-content-container">
                        <div class="flex"><strong class="w-28 text-gray-400">Name:</strong> <span>${userDetail.name}</span></div>
                        <div class="flex"><strong class="w-28 text-gray-400">Email:</strong> <span>${userDetail.email}</span></div>
                        <div class="flex"><strong class="w-28 text-gray-400">Phone:</strong> <span>${userDetail.phone || '-'}</span></div>
                        <div class="flex"><strong class="w-28 text-gray-400">Address:</strong> <span>${userDetail.address || '-'}</span></div>
                        <div class="flex"><strong class="w-28 text-gray-400">Role:</strong> <span>${userDetail.role}</span></div>
                        <div class="flex"><strong class="w-28 text-gray-400">Status:</strong> <span class="${statusClass}">${statusText}</span></div>
                        <div class="flex"><strong class="w-28 text-gray-400">Created At:</strong> <span>${formatDateTime(userDetail.created_at)}</span></div>
                        <div class="flex"><strong class="w-28 text-gray-400">Updated At:</strong> <span>${formatDateTime(userDetail.updated_at)}</span></div>
                    </div>
                `;
                Swal.update({
                    title: `Details for ${userDetail.name}`,
                    html: contentHtml,
                    showConfirmButton: true,
                    confirmButtonText: 'Close',
                    confirmButtonColor: '#4b5563',
                });
            } catch (error: any) {
                Swal.update({
                    icon: 'error',
                    title: 'Error',
                    text: error.data?.message || 'Failed to load user details.',
                    showConfirmButton: true,
                    confirmButtonText: 'Close',
                });
            }
        },
    });
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
