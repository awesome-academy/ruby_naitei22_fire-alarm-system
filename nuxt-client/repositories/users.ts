import type { $Fetch } from 'ofetch';
import type { User } from '~/types/api';

export default ($fetch: $Fetch) => ({
    getAll() {
        return $fetch<User[]>('/users', {
            method: 'GET',
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
            body: data,
        });
    },
});
