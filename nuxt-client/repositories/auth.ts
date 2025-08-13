import type { $Fetch } from 'ofetch';

interface LoginCredentials {
    email: string;
    password: string;
}

interface SignupData {
    name: string;
    email: string;
    password: string;
    phone?: string;
}

interface AuthUser {
    id: string;
    name: string;
    email: string;
    role: string;
}

export default ($fetch: $Fetch) => ({
    login(credentials: LoginCredentials) {
        return $fetch<{ message: string }>('/auth/login', {
            method: 'POST',
            body: credentials,
        });
    },

    signup(data: SignupData) {
        return $fetch<{ message: string }>('/auth/signup', {
            method: 'POST',
            body: data,
        });
    },

    logout() {
        return $fetch<{ message: string }>('/auth/logout', {
            method: 'POST',
        });
    },

    fetchProfile() {
        return $fetch<AuthUser | null>('/auth/profile', {
            method: 'GET',
            ignoreResponseError: true,
        });
    },

    updateUserRole(userId: string, role: string) {
        return $fetch('/auth/rule', {
            method: 'PATCH',
            body: { userId, role },
        });
    },
});
