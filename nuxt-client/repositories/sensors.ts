import type { $Fetch } from 'ofetch';
import type { Sensor, SensorWithDetails, PaginatedResponse } from '~/types/api';

export default ($fetch: $Fetch) => ({
    getAll(params: Record<string, any> = {}) {
        return $fetch<PaginatedResponse<SensorWithDetails>>('/sensors', { params });
    },

    getById(id: string) {
        return $fetch<SensorWithDetails>(`/sensors/${id}`);
    },
    create(data: Partial<Sensor>) {
        return $fetch<Sensor>('/sensors', { method: 'POST', body: data });
    },
    update(id: string, data: Partial<Sensor>) {
        return $fetch<Sensor>(`/sensors/${id}`, { method: 'PATCH', body: data });
    },
    delete(id: string) {
        return $fetch(`/sensors/${id}`, { method: 'DELETE' });
    },
    getStats() {
        return $fetch<{ total: number; active: number; inactive: number; error: number }>('/sensors/stats');
    },
});
