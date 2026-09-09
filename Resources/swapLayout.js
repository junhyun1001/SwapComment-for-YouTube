// SwitchVideoToComment - Swap YouTube Comments and Recommended Videos
(function() {
    'use strict';

    let observer = null;
    let isSwapping = false;

    function isWatchPage() {
        return window.location.pathname.startsWith('/watch');
    }

    function triggerCommentLoading(commentsElem) {
        // YouTube uses IntersectionObserver / scroll listener to lazy-load comments
        window.dispatchEvent(new Event('scroll'));
        if (commentsElem) {
            commentsElem.dispatchEvent(new Event('scroll', { bubbles: true }));
        }
    }

    function applySwap() {
        if (!isWatchPage()) {
            document.body.removeAttribute('data-yt-sidebar-comments');
            return;
        }

        if (isSwapping) return;

        const secondaryInner = document.querySelector('#secondary #secondary-inner');
        const comments = document.querySelector('#comments') || document.querySelector('ytd-comments');
        const below = document.querySelector('#below');
        const relatedRenderer = document.querySelector('ytd-watch-next-secondary-results-renderer') || document.querySelector('#related');

        if (!secondaryInner || !comments || !below) {
            return;
        }

        // Check if already swapped
        const isCommentsInSecondary = secondaryInner.contains(comments);
        const isRelatedInBelow = relatedRenderer && below.contains(relatedRenderer);

        if (isCommentsInSecondary && isRelatedInBelow) {
            document.body.setAttribute('data-yt-sidebar-comments', 'true');
            return;
        }

        isSwapping = true;

        try {
            document.body.setAttribute('data-yt-sidebar-comments', 'true');

            // 1. Move related videos to #below (after video description)
            if (relatedRenderer && !below.contains(relatedRenderer)) {
                below.appendChild(relatedRenderer);
            }

            // 2. Move comments to #secondary-inner
            if (!secondaryInner.contains(comments)) {
                secondaryInner.prepend(comments);
            }

            // 3. Trigger lazy load for comments
            setTimeout(() => {
                triggerCommentLoading(comments);
            }, 300);
            setTimeout(() => {
                triggerCommentLoading(comments);
            }, 1000);

        } catch (e) {
            console.error('[SwitchVideoToComment] Error swapping layout:', e);
        } finally {
            isSwapping = false;
        }
    }

    function setupObserver() {
        if (observer) {
            observer.disconnect();
        }

        observer = new MutationObserver(() => {
            if (isWatchPage()) {
                applySwap();
            } else {
                document.body.removeAttribute('data-yt-sidebar-comments');
            }
        });

        observer.observe(document.documentElement, {
            childList: true,
            subtree: true
        });
    }

    // YouTube SPA navigation events
    window.addEventListener('yt-navigate-finish', () => {
        applySwap();
    });

    window.addEventListener('load', () => {
        applySwap();
        setupObserver();
    });

    // Initial setup
    setupObserver();
    applySwap();
})();
