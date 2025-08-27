import type { $Fetch } from 'ofetch';
import type { Camera, CameraWithDetails, PaginatedResponse } from '~/types/api';
import qs from 'qs';

export default ($fetch: $Fetch) => ({
    getAll(params: Record<string, any> = {}) {
        return $fetch<PaginatedResponse<CameraWithDetails>>('/cameras', { 
            params,
            paramsSerializer: (p) => qs.stringify(p, { encode: false }),
        });
    },
    getById(id: string) {
        return $fetch<Camera>(`/cameras/${id}`);
    },
    create(data: Partial<Camera>) {
        return $fetch<Camera>('/cameras', { method: 'POST', body: { camera: data } });
    },
    update(id: string, data: Partial<Camera>) {
        return $fetch<Camera>(`/cameras/${id}`, { method: 'PATCH', body: { camera: data } });
    },
    delete(id: string) {
        return $fetch(`/cameras/${id}`, { method: 'DELETE' });
    },
    getStats() {
        return $fetch<{ total: number }>('/cameras/stats');
    },
    getSnapshot(id: string) {
        // @ts-ignore
        return $fetch<Blob>(`/cameras/${id}/snapshot`, { responseType: 'blob' });
    },
});
