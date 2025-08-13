import type { $Fetch } from 'ofetch';
import type { AlertWithRelations, PaginatedResponse, AlertStatus, AlertWithDetails } from '~/types/api';

export default ($fetch: $Fetch) => ({
    getAll(params: Record<string, any>) {
        return $fetch<PaginatedResponse<AlertWithRelations>>('/alerts', {
            method: 'GET',
            params,
        });
    },

    getById(id: string) {
        return $fetch<AlertWithDetails>(`/alerts/${id}`);
    },

    updateStatus(id: string, status: AlertStatus) {
        return $fetch<AlertWithRelations>(`/alerts/${id}/status`, {
            method: 'PATCH',
            body: { status },
        });
    },

    getStats() {
        return $fetch<{ pending: number }>('/alerts/stats');
    },

    getRecentPending(limit: number = 5) {
        return $fetch<PaginatedResponse<AlertWithRelations>>('/alerts', {
            params: { limit, status: 'PENDING', sortBy: 'createdAt', sortOrder: 'desc' },
        });
    },
});
