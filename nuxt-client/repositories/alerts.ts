import type { $Fetch } from 'ofetch';
import type { AlertWithRelations, PaginatedResponse, AlertWithDetails } from '~/types/api';
import { AlertStatus } from '~/types/api';

const mapStatusToNumber = (status: AlertStatus): number => {
  switch (status) {
    case AlertStatus.PENDING:
      return 0;
    case AlertStatus.RESOLVED:
      return 1;
    case AlertStatus.IGNORED:
      return 2;
    default:
      return 0; 
  }
};
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
        const statusAsNumber = mapStatusToNumber(status);
        return $fetch<AlertWithRelations>(`/alerts/${id}/status`, {
            method: 'PATCH',
            body: { status: statusAsNumber },
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
