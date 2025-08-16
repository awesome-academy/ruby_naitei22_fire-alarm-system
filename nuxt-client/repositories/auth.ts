import type { $Fetch } from 'ofetch';
import type { User, PaginatedResponse, Role } from '~/types/api';
interface LoginCredentials {
    email: string;
    password: string;
}

interface SignupData {
    name: string;
    email: string;
    password: string;
    phone?: string;
    invitation_code: string;
}

interface AuthUser {
    id: string;
    name: string;
    email: string;
    role: string;
}

interface ForgotPasswordPayload {
    email: string;
}

interface ResetPasswordPayload {
    token: string;
    password: string;
    password_confirmation: string;
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
            body: { auth: data },
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

    updateUserRole(userId: string, role: Role) {
        return $fetch<User>('/auth/role', { 
            method: 'PATCH',
            body: { user_id: userId, role: role.toLowerCase() }
        });
    },

    forgotPassword(payload: ForgotPasswordPayload) {
        return $fetch<{ message: string }>('/auth/forgot_password', {
            method: 'POST',
            body: payload,
        });
    },

    resetPassword(payload: ResetPasswordPayload) {
        return $fetch<{ message: string }>('/auth/reset_password', {
            method: 'POST',
            body: payload,
        });
    },
});
