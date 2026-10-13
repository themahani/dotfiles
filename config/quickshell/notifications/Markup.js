.pragma library

// Keep application formatting and links, but let the shell own text colors.
function readableBody(body) {
    return body.replace(/<[^>]+>/g, function(tag) {
        return tag.replace(/\s(?:color|style)\s*=\s*(?:"[^"]*"|'[^']*'|[^\s>]+)/gi, "");
    });
}
