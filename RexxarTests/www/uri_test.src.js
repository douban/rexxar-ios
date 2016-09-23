url_parser = require("url-parse");
window.get_uri = function() {
    return url_parser.parse(window.location.href, true).query.uri;
}
