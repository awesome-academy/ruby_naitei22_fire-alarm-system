import type { $Fetch } from 'ofetch';

export default ($fetch: $Fetch) => ({
    create(email: string) {
        return $fetch<any>('/invitations', {
            method: 'POST',
            body: { invitation: { email } },
        });
    },
});
