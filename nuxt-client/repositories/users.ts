import type { $Fetch } from 'ofetch';
import type { User, PaginatedResponse } from '~/types/api';
import qs from 'qs';

export default ($fetch: $Fetch) => ({
    getAll(params: Record<string, any> = {}) {
        return $fetch<PaginatedResponse<User>>('/users', {
            method: 'GET',
            params,
            paramsSerializer: (p) => qs.stringify(p, { encode: false }),
        });
    },

    getById(id: string) {
        return $fetch<User>(`/users/${id}`, {
            method: 'GET',
        });
    },

    update(id: string, data: Partial<User>) {
        return $fetch<User>(`/users/${id}`, {
            method: 'PATCH',
            body: { user: data },
        });
    },
});
