import type { $Fetch } from 'ofetch';
import type { Camera, CameraWithDetails } from '~/types/api';

export default ($fetch: $Fetch) => ({
    getAll() {
        return $fetch<CameraWithDetails[]>('/cameras');
    },
    getById(id: string) {
        return $fetch<Camera>(`/cameras/${id}`);
    },
    create(data: Partial<Camera>) {
        return $fetch<Camera>('/cameras', { method: 'POST', body: data });
    },
    update(id: string, data: Partial<Camera>) {
        return $fetch<Camera>(`/cameras/${id}`, { method: 'PATCH', body: data });
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
