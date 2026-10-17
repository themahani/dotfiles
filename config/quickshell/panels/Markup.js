.pragma library

// Keep application formatting and links, but let the shell own text colors.
// Images are dropped: a remote <img> would be fetched as soon as the
// notification shows.
function readableBody(body) {
    return body.replace(/<img\b[^>]*>/gi, "").replace(/<[^>]+>/g, function(tag) {
        return tag.replace(/\s(?:color|style)\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)/gi, "");
    });
}

// Links open only on the web or in the mail client, never as files or
// through other apps' URL handlers.
function isWebLink(link) {
    return /^(https?|mailto):/i.test(link);
}

// Notification images and icons load only from this machine: a path, a
// file: URL or an image provider such as Quickshell's image-data.
function isLocalImage(source) {
    return /^(\/|file:|image:)/i.test(source);
}
