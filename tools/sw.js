const CACHE_NAME = 'TEMPLATE_VERSION';
const urlsToCache = [TEMPLATE_FILES];

self.addEventListener('install', function(event) {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(function(cache) {
                const requests = urlsToCache.map(it => {
                    return {
                        url: it[0],
                        integrity: it[1]
                    }
                });
                return cache.addAll(requests);
            })
    );
});