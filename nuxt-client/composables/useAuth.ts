import { computed } from 'vue';
import { useState } from '#app';
import { useApi } from './useApi';

interface AuthUser {
    id: string;
    name: string;
    email: string;
    role: string;
}

interface LoginCredentials {
    identifier: string;
    password: string;
}

interface SignupData {
    name: string;
    email: string;
    password: string;
    phone?: string;
}

export const useAuth = () => {
    const user = useState<AuthUser | null>('authStateUser', () => null);
    const api = useApi();

    const isAuthenticated = computed(() => !!user.value);
    const isAdmin = computed(() => user.value?.role === 'ADMIN');

    const fetchUser = async () => {
        try {
            const fetchedUser = await api.auth.fetchProfile();
            user.value = fetchedUser;
        } catch (error) {
            user.value = null;
        }
    };

    const login = async (credentials: LoginCredentials) => {
        try {
            await api.auth.login({
                email: credentials.identifier,
                password: credentials.password,
            });
            await fetchUser();
            return { success: true, error: null };
        } catch (error: any) {
            user.value = null;
            return { success: false, error: error?.data?.message || 'Login failed.' };
        }
    };

    const signup = async (signupData: SignupData) => {
        try {
            await api.auth.signup(signupData);
            return { success: true, error: null };
        } catch (error: any) {
            return { success: false, error: error?.data?.message || 'Signup failed.' };
        }
    };

    const logout = async () => {
        try {
            await api.auth.logout();
        } catch (error) {
        } finally {
            user.value = null;
        }
    };

    return {
        user,
        isAuthenticated,
        isAdmin,
        login,
        signup,
        logout,
        fetchUser,
    };
};
