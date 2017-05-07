/**
 * A utility program to concatenate javascript or css files
 * accounting for their source maps.
 */
const path = require('path');
const fs = require('fs');
const SourceMap = require('source-map');
const SourceMapConsumer = SourceMap.SourceMapConsumer;
const SourceMapGenerator = SourceMap.SourceMapGenerator;

const CSS_START = '\n/*# sourceMappingURL=';
const END_CSS = ' */';
const JS_START = '\n//# sourceMappingURL=';
const MIME_TYPE_PREFIX = 'data:application/json;';
const MIME_TYPE = MIME_TYPE_PREFIX + 'charset=utf-8;base64,';


if (process.argv.length <= 6) {
    console.log("Usage: " + __filename + "  -d dest [-r resolve] [-m maps] [-i inline] [-s strip]... src...");
    process.exit(-1);
}

const srcs = [],
    strip = [];
var dest,
    resolve,
    maps,
    inline;

for (var n = 0, nlen = process.argv.length; n < nlen; ++n) {
    var arg = process.argv[n];
    switch (arg) {
        case '-r':
            resolve = process.argv[++n] === 'true';
            break;
        case '-m':
            maps = process.argv[++n] === 'true';
            break;
        case '-i':
            inline = process.argv[++n] === 'true';
            break;
        case '-d':
            dest = process.argv[++n];
            break;
        case '-s':
            strip.push(process.argv[++n]);
            break;
        case '--':
            for (n = n + 1; n < nlen; ++n) {
                srcs.push(process.argv[n]);
            }
            break;
    }
}

const isCss = dest.endsWith('.css');
resolve = resolve && !isCss;
const filter = dest.slice(dest.lastIndexOf('.'));
const START = isCss ? CSS_START : JS_START;
const START_OFFSET = START.length;
const INLINE_START = START + MIME_TYPE_PREFIX;
const END = isCss ? END_CSS : '';

const destDir = path.dirname(dest);
const destFd = fs.openSync(dest, 'w');
const file = path.relative(destDir, dest).replace(/\\/g, '/');
const generator = new SourceMapGenerator({
    file: file
});

const srcFiles = [];
const srcIndex = {};

var destCol = 0, destLine = 1;

var stripFile = (source) => {
    do {
        var changed = false;
        for (var s = 0, slen = strip.length; s < slen; ++s) {
            var old = source;
            source = source.replace(strip[s], '');
            if (old !== source) {
                changed = true;
            }
        }
    } while (changed);
    return source;
};

var handleNoExisting = (rel, data) => {
    // No existing source map, map it ourselves
    if (!maps) {
        fs.writeSync(destFd, data);
        return data;
    }
    rel = stripFile(rel);
    var tokens = data.split(/(\n|[^\S\n]+|\b)/g);
    var srcCol = 0, srcLine = 1;

    for (var j = 0, jlen = tokens.length; j < jlen; ++j) {
        var token = tokens[j];
        var len = token.length;
        if (len === 0) {
            continue;
        }
        generator.addMapping({
            generated: {line: destLine, column: destCol},
            original: {line: srcLine, column: srcCol},
            source: rel
        });
        if (token === '\n') {
            ++srcLine;
            ++destLine;
            srcCol = 0;
            destCol = 0;
        } else {
            srcCol += len;
            destCol += len;
        }
    }
    generator.setSourceContent(rel, data);
    fs.writeSync(destFd, data);
};

var handleExisting = async (rel, data, mapIdx) => {
    // Found an existing source map, append it to the generated map
    var content = data.slice(0, mapIdx);
    if (!maps) {
        fs.writeSync(destFd, content);
        return;
    }
    var json, rest;
    var chunk = data.slice(mapIdx);
    if (chunk.startsWith(INLINE_START)) {
        rest = chunk.slice(chunk.indexOf(',') + 1).trim();
        json = Buffer.from(rest, 'base64').toString();
    } else {
        rest = chunk.slice(START_OFFSET).trim();
        if (srcIndex[rest]) {
            rest = srcFiles[srcIndex[rest]];
        }
        if (!fs.existsSync(rest)) {
            console.error("Can't find map file: " + rest + " for input file " + rel);
            handleNoExisting(rel, content);
            return;
        }
        json = fs.readFileSync(rest, 'UTF8');
    }
    var map = JSON.parse(json);
    var consumer = await new SourceMapConsumer(map);
    var initLine = destLine;
    var initCol = destCol;
    var sourceToResolved = {};
    consumer.eachMapping((args) => {
        var source = args.source ? args.source.replace(/\\/g, '/') : null;
        if (source) {
            source = stripFile(source);
        }
        sourceToResolved[args.source] = source;
        destLine = initLine + args.generatedLine - 1;
        if (destLine === initLine) {
            destCol = initCol + args.generatedColumn;
        } else {
            destCol = args.generatedColumn;
        }
        var original = typeof args.originalLine === 'number' && typeof args.originalColumn === 'number'
            ? {line: args.originalLine, column: args.originalColumn}
            : null;
        generator.addMapping({
            generated: {line: destLine, column: destCol},
            original: original,
            source: source,
            name: args.name
        });
    });
    if (map.sources && map.sourcesContent) {
        for (var k = 0, klen = map.sources.length; k < klen; ++k) {
            generator.setSourceContent(
                sourceToResolved[map.sources[k]],
                consumer.sourceContentFor(map.sources[k])
            );
        }
    }
    fs.writeSync(destFd, content);
    return content;
};

var handleData = async (src, data) => {
    var rel = path.relative(destDir, src).replace(/\\/g, '/');
    var mapIdx = data.lastIndexOf(START);
    if (mapIdx === -1) {
        handleNoExisting(rel, data);
    } else {
        await handleExisting(rel, data, mapIdx);
    }
};

var fileContent = [];
var fileIndex = {};

var order = [];
var references = {};
var exports = {};
var imports = {};

const forSourceFile = async src => {
    var data = fs.readFileSync(src, 'UTF8');
    if (!resolve) {
        await handleData(src, data);
        return;
    }
    var rrefs = new RegExp('\\/\\/\\/\\s*<reference\\s+path="(?:..\\/)*(.+?)(?:\\.ts)?"\\s*\\/>', 'g');
    var rmodule = new RegExp('\\s*(?:export)?\\s*module\\s+(?:[a-zA-Z0-9_]+\\.)*([a-zA-Z0-9_]+)\\s*{', 'g');
    var rimports = new RegExp('\\s*import\\s+([a-zA-Z0-9_]+)\\s+=\\s+(?:[a-zA-Z0-9_]+\\.)*([a-zA-Z0-9_]+)\\s*;', 'g');
    var rexports = new RegExp('\\s*export\\s+(?:class|abstract\\s+class|interface|function|var|const|let|type|enum)\\s+([a-zA-Z0-9_]+)(?:<.+)?\\s*(?:extends|implements)?', 'g');
    var match;
    fileIndex[src] = fileContent.length;
    fileContent.push(data);
    order.push(src);
    while ((match = rrefs.exec(data))) {
        var name = '/' + match[1] + '.ts';
        var refs = references[src] || [];
        refs.push(name);
        references[src] = refs;
    }
    while ((match = rmodule.exec(data))) {
        var name = match[1];
        var deps = exports[name] || [];
        deps.push(src);
        exports[name] = deps;
    }
    while ((match = rexports.exec(data))) {
        var name = match[1];
        var deps = exports[name] || [];
        deps.push(src);
        exports[name] = deps;
    }
    while ((match = rimports.exec(data))) {
        if (match[1] !== match[2]) {
            continue;
        }
        var name = match[1];
        var deps = imports[src] || [];
        deps.push(name);
        imports[src] = deps;
    }
};

const getDeps = (deps) => {
    var ret = [];
    if (!deps) {
        return ret;
    }
    for (var l = 0; l < deps.length; ++l) {
        for (var m = 0; m < order.length; ++m) {
            if (order[m].endsWith(deps[l])) {
                ret.push(order[m]);
            }
        }
    }
    return ret;
};

const writeOutput = () => {
    if (!maps) {
        return;
    }
    var json = JSON.stringify(generator.toJSON(), null, '');
    var url;
    if (inline) {
        var buf = Buffer.from(json).toString('base64');
        url = START + MIME_TYPE + buf + END;
    } else {
        var destMap = dest + '.map';
        const destMapFd = fs.openSync(destMap, 'w');
        fs.writeSync(destMapFd, json);
        url = START + destMap + END;
    }
    fs.writeSync(destFd, url);
};

const handleDataAndWriteOutput = async (outs, fileIndex, fileContent) => {
    for (var i = 0, ilen = outs.length; i < ilen; ++i) {
        var src = outs[i];
        var idx = fileIndex[src];
        var data = fileContent[idx];
        await handleData(src, data);
    }
    writeOutput();
};

const runMain = async () => {
    for (var i = 0, ilen = srcs.length; i < ilen; ++i) {
        var src = srcs[i];
        if (src.startsWith('@')) {
            var data = fs.readFileSync(src.slice(1), 'UTF8');
            var files = data.split(/\s+/g);
            for (var m = 0, mlen = files.length; m < mlen; ++m) {
                var fileSrc = files[m];
                srcIndex[fileSrc.slice(fileSrc.lastIndexOf('/') + 1)] = srcFiles.length;
                srcFiles.push(fileSrc);
            }
        } else {
            srcIndex[src.slice(src.lastIndexOf('/') + 1)] = srcFiles.length;
            srcFiles.push(src);
        }
    }

    for (i = 0, ilen = srcFiles.length; i < ilen; ++i) {
        src = srcFiles[i];
        if (!src.endsWith(filter)) {
            continue;
        }
        await forSourceFile(src);
    }

    if (resolve) {
        const nodes = {};
        const edges = {};

        const addEdge = (from, to) => {
            var edge = edges[from] || [];
            edge.push(to);
            edges[from] = edge;
        };

        /**
         * Create all the nodes
         */
        for (i = 0, ilen = order.length; i < ilen; ++i) {
            src = order[i];
            nodes[src] = true;
        }

        /**
         * Using the map of imports to file names link the edges
         * of the graph.
         */
        for (i = 0, ilen = order.length; i < ilen; ++i) {
            src = order[i];
            var deps = references[src];
            getDeps(deps).forEach(it => addEdge(src, it));
            var imps = imports[src];
            if (!imps) {
                continue;
            }
            for (var j = 0, jlen = imps.length; j < jlen; ++j) {
                var imp = imps[j];
                var exs = exports[imp];
                if (!exs) {
                    continue;
                }
                for (var e = 0, elen = exs.length; e < elen; ++e) {
                    var ex = exs[e];
                    addEdge(src, ex);
                }
            }
        }
        var keys = Object.keys(nodes);
        var outs = [];
        var unseen = {};
        keys.forEach(it => unseen[it] = "n");
        const visit = (n) => {
            switch (unseen[n]) {
                case "t":
                    /**
                     * This is a circular dependency. Unfortunately our codebase is a hot mess
                     * full of them and TS can deal with it if its only interfaces that are circular
                     * as they compile away.
                     */
                    return;
                case "n":
                    unseen[n] = "t";
                    var ms = edges[n];
                    if (ms) {
                        ms.forEach(m => visit(m));
                    }
                    delete unseen[n];
                    outs.push(n);
            }
        };
        for (;;) {
            var ukeys = Object.keys(unseen);
            if (!ukeys.length) {
                break;
            }
            visit(ukeys.pop());
        }
        const cur = {};
        outs.forEach(it => cur[it] = true);
        order.forEach(it => {
            if (cur[it] !== true) {
                throw new Error("Missing input file " + it);
            }
        });
        await handleDataAndWriteOutput(outs, fileIndex, fileContent);
    } else {
        writeOutput();
    }
};

runMain();