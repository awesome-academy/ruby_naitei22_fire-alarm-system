import type { $Fetch } from 'ofetch';
import type { Zone, ZoneWithDetails } from '~/types/api';

export default ($fetch: $Fetch) => ({
    getAll(params: Record<string, any> = {}) {
        return $fetch<Zone[]>('/zones', { params });
    },
    getById(id: string) {
        return $fetch<ZoneWithDetails>(`/zones/${id}`);
    },
    create(data: Partial<Zone>) {
        return $fetch<Zone>('/zones', { method: 'POST', body: data });
    },
    update(id: string, data: Partial<Zone>) {
        return $fetch<Zone>(`/zones/${id}`, { method: 'PATCH', body: data });
    },
    delete(id: string) {
        return $fetch(`/zones/${id}`, { method: 'DELETE' });
    },
});
