import { computed } from 'vue';
import { useState } from '#app';
import { useApi } from './useApi';
import type { User } from '~/types/api';

interface LoginCredentials {
    identifier: string;
    password: string;
}

interface SignupData {
    name: string;
    email: string;
    password: string;
    phone?: string;
    invitation_code: string;
}

const useAuthInitialized = () => useState<boolean>('auth-initialized', () => false);

export const useAuth = () => {
    const user = useState<User | null>('authStateUser', () => null);
    const isInitialized = useAuthInitialized();
    const api = useApi();

    const isAuthenticated = computed(() => !!user.value);
    const isAdmin = computed(() => user.value?.role === 'ADMIN');

    const fetchUser = async () => {
        if (user.value) return;
        try {
            const fetchedUser = await api.auth.fetchProfile();
            user.value = fetchedUser;
        } catch (error) {
            console.error("Failed to fetch user profile:", error);
            user.value = null;
        }
    };

    const initAuth = async () => {
        if (process.server || isInitialized.value) {
            return;
        }
        await fetchUser();
        isInitialized.value = true;
    };

    const login = async (credentials: LoginCredentials) => {
        try {
            await api.auth.login({
                email: credentials.identifier,
                password: credentials.password,
            });
            await fetchUser();
            isInitialized.value = true;
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
            console.error("Logout failed:", error);
        } finally {
            user.value = null;
            isInitialized.value = true;
        }
    };

    return {
        user,
        isAuthenticated,
        isAdmin,
        isInitialized,
        login,
        signup,
        logout,
        fetchUser,
        initAuth,
    };
};
