// SwapComment for YouTube - Swap YouTube Comments and Recommended Videos
(function() {
    'use strict';

    let observer = null;
    let isSwapping = false;
    let scheduledTimer = null;
    let lastTriggeredUrl = '';

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

    function shouldUseSidebarLayout(flexy, secondary) {
        if (!secondary || window.innerWidth < 960) {
            return false;
        }
        if (flexy && !flexy.hasAttribute('is-two-columns_')) {
            return false;
        }
        return window.getComputedStyle(secondary).display !== 'none';
    }

    function scheduleCommentLoad(comments) {
        const currentUrl = window.location.href;
        if (lastTriggeredUrl === currentUrl) {
            return;
        }
        lastTriggeredUrl = currentUrl;
        setTimeout(() => triggerCommentLoading(comments), 300);
        setTimeout(() => triggerCommentLoading(comments), 1000);
    }

    function applySwap() {
        if (!document.body) return;

        if (!isWatchPage()) {
            document.body.removeAttribute('data-yt-sidebar-comments');
            lastTriggeredUrl = '';
            return;
        }

        if (isSwapping) return;

        const flexy = document.querySelector('ytd-watch-flexy');
        const root = flexy || document;
        const secondary = root.querySelector('#secondary');
        const secondaryInner = root.querySelector('#secondary #secondary-inner');
        const below = root.querySelector('#below');
        const comments = root.querySelector('#comments') || root.querySelector('ytd-comments');
        const relatedRenderer = root.querySelector('ytd-watch-next-secondary-results-renderer') || root.querySelector('#related');

        if (!below) {
            return;
        }

        const useSidebar = shouldUseSidebarLayout(flexy, secondary) && Boolean(secondaryInner);

        // Check if layout is already in desired state
        const needsRelatedMove = Boolean(relatedRenderer && !below.contains(relatedRenderer));
        let needsCommentsMove = false;
        if (comments) {
            if (useSidebar) {
                needsCommentsMove = !secondaryInner.contains(comments);
            } else {
                // In narrow/1-column mode, comments belong in #below above relatedRenderer
                const inBelow = below.contains(comments);
                const beforeRelated = !relatedRenderer || !below.contains(relatedRenderer) ||
                    Boolean(comments.compareDocumentPosition(relatedRenderer) & Node.DOCUMENT_POSITION_FOLLOWING);
                needsCommentsMove = !(inBelow && beforeRelated);
            }
        }

        const hasSidebarAttr = document.body.getAttribute('data-yt-sidebar-comments') === 'true';
        if (!needsRelatedMove && !needsCommentsMove && hasSidebarAttr === useSidebar) {
            if (useSidebar && comments) {
                scheduleCommentLoad(comments);
            }
            return;
        }

        isSwapping = true;

        try {
            if (useSidebar) {
                document.body.setAttribute('data-yt-sidebar-comments', 'true');
            } else {
                document.body.removeAttribute('data-yt-sidebar-comments');
            }

            // 1. Keep related videos in #below (after video metadata/comments)
            if (relatedRenderer && !below.contains(relatedRenderer)) {
                below.appendChild(relatedRenderer);
            }

            // 2. Place comments in #secondary-inner (2-col) or top of #below above relatedRenderer (1-col)
            if (comments) {
                if (useSidebar) {
                    if (!secondaryInner.contains(comments)) {
                        secondaryInner.prepend(comments);
                    }
                    scheduleCommentLoad(comments);
                } else {
                    if (relatedRenderer && below.contains(relatedRenderer)) {
                        const alreadyBefore = below.contains(comments) &&
                            Boolean(comments.compareDocumentPosition(relatedRenderer) & Node.DOCUMENT_POSITION_FOLLOWING);
                        if (!alreadyBefore) {
                            below.insertBefore(comments, relatedRenderer);
                        }
                    } else if (!below.contains(comments)) {
                        below.appendChild(comments);
                    }
                }
            }
        } catch (e) {
            console.error('[SwapComment for YouTube] Error swapping layout:', e);
        } finally {
            isSwapping = false;
        }
    }

    function scheduleApply() {
        if (scheduledTimer !== null) {
            return;
        }
        scheduledTimer = setTimeout(() => {
            scheduledTimer = null;
            applySwap();
        }, 100);
    }

    function setupObserver() {
        if (observer) {
            observer.disconnect();
        }

        observer = new MutationObserver(() => {
            if (!isWatchPage()) {
                if (document.body && document.body.hasAttribute('data-yt-sidebar-comments')) {
                    document.body.removeAttribute('data-yt-sidebar-comments');
                }
                return;
            }
            scheduleApply();
        });

        observer.observe(document.documentElement, {
            childList: true,
            subtree: true
        });
    }

    // YouTube SPA navigation & viewport resize events
    window.addEventListener('yt-navigate-finish', () => {
        lastTriggeredUrl = '';
        scheduleApply();
    });

    window.addEventListener('resize', scheduleApply);

    window.addEventListener('load', () => {
        applySwap();
        setupObserver();
    });

    // Initial setup
    setupObserver();
    applySwap();
})();
