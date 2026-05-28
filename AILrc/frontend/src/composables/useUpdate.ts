import { ref, onMounted } from 'vue';
import packageJson from '../../package.json';

const REPO_URL = 'https://api.github.com/repos/Leovikii/AILrc-plugin/releases/latest';

export function useUpdate() {
    const hasUpdate = ref(false);
    const latestVersion = ref('');
    const releaseUrl = ref('');

    const checkUpdate = async () => {
        try {
            const response = await fetch(REPO_URL);
            if (!response.ok) return;
            
            const data = await response.json();
            if (!data.tag_name) return;

            const remoteVersion = data.tag_name.replace(/^v/, '');
            const localVersion = packageJson.version;

            if (isNewerVersion(localVersion, remoteVersion)) {
                hasUpdate.value = true;
                latestVersion.value = data.tag_name;
                releaseUrl.value = data.html_url;
            }
        } catch (error) {
            console.error('Failed to check for updates:', error);
        }
    };

    const isNewerVersion = (local: string, remote: string) => {
        const lParts = local.split('.').map(Number);
        const rParts = remote.split('.').map(Number);
        
        for (let i = 0; i < Math.max(lParts.length, rParts.length); i++) {
            const l = lParts[i] || 0;
            const r = rParts[i] || 0;
            if (r > l) return true;
            if (r < l) return false;
        }
        return false;
    };

    onMounted(() => {
        checkUpdate();
    });

    return {
        hasUpdate,
        latestVersion,
        releaseUrl,
        checkUpdate
    };
}
