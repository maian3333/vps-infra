const http = require('http');
const url = require('url');

class MCPServer {
    constructor() {
        this.tools = [
            {
                name: 'list_projects',
                description: 'Get a list of all projects in the knowledge graph',
                inputSchema: {
                    type: 'object',
                    properties: {}
                }
            },
            {
                name: 'search_codebase_definitions',
                description: 'Efficiently searches the codebase for functions, classes, methods, constants, interfaces...',
                inputSchema: {
                    type: 'object',
                    properties: {
                        project_absolute_path: {
                            type: 'string',
                            description: 'Absolute path to the project to search'
                        },
                        search_terms: {
                            type: 'array',
                            items: { type: 'string' },
                            description: 'Array of search terms to look for'
                        },
                        page: {
                            type: 'number',
                            description: 'Page number for pagination (optional)'
                        }
                    },
                    required: ['project_absolute_path', 'search_terms']
                }
            },
            {
                name: 'index_project',
                description: 'Creates new or rebuilds the Knowledge Graph index for a project',
                inputSchema: {
                    type: 'object',
                    properties: {
                        project_absolute_path: {
                            type: 'string',
                            description: 'Absolute path to the project to index'
                        }
                    },
                    required: ['project_absolute_path']
                }
            },
            {
                name: 'get_references',
                description: 'Find all references to a code definition across the entire codebase',
                inputSchema: {
                    type: 'object',
                    properties: {
                        definition_name: {
                            type: 'string',
                            description: 'Name of the definition to find references for'
                        },
                        file_path: {
                            type: 'string',
                            description: 'Path to the file containing the definition'
                        },
                        page: {
                            type: 'number',
                            description: 'Page number for pagination (optional)'
                        }
                    },
                    required: ['definition_name', 'file_path']
                }
            },
            {
                name: 'read_definitions',
                description: 'Read the definition bodies for multiple definitions across the codebase',
                inputSchema: {
                    type: 'object',
                    properties: {
                        definitions: {
                            type: 'array',
                            items: {
                                type: 'object',
                                properties: {
                                    name: { type: 'string', description: 'Name of the definition' },
                                    file_path: { type: 'string', description: 'Path to the file containing the definition' }
                                },
                                required: ['name', 'file_path']
                            },
                            description: 'Array of definitions to read'
                        }
                    },
                    required: ['definitions']
                }
            },
            {
                name: 'get_definition',
                description: 'Navigates directly to the definition of a function or method call',
                inputSchema: {
                    type: 'object',
                    properties: {
                        file_path: {
                            type: 'string',
                            description: 'Path to the file containing the reference'
                        },
                        line: {
                            type: 'number',
                            description: 'Line number where the reference is located'
                        },
                        symbol_name: {
                            type: 'string',
                            description: 'Name of the symbol to find definition for'
                        }
                    },
                    required: ['file_path', 'line', 'symbol_name']
                }
            },
            {
                name: 'repo_map',
                description: 'Produces a compact, API-style map of a repository segment',
                inputSchema: {
                    type: 'object',
                    properties: {
                        project_absolute_path: {
                            type: 'string',
                            description: 'Absolute path to the project'
                        },
                        relative_paths: {
                            type: 'array',
                            items: { type: 'string' },
                            description: 'Array of relative paths to include in the map'
                        },
                        depth: {
                            type: 'number',
                            description: 'Maximum depth for directory traversal (optional)'
                        },
                        show_directories: {
                            type: 'boolean',
                            description: 'Whether to include directories in the output (optional)'
                        },
                        show_definitions: {
                            type: 'boolean',
                            description: 'Whether to include code definitions in the output (optional)'
                        },
                        page: {
                            type: 'number',
                            description: 'Page number for pagination (optional)'
                        },
                        page_size: {
                            type: 'number',
                            description: 'Number of items per page (optional)'
                        }
                    },
                    required: ['project_absolute_path', 'relative_paths']
                }
            }
        ];
    }

    handleMCPRequest(data) {
        try {
            const request = JSON.parse(data);

            switch (request.method) {
                case 'initialize':
                    return {
                        jsonrpc: "2.0",
                        id: request.id,
                        result: {
                            protocolVersion: "2024-11-05",
                            capabilities: {
                                tools: {}
                            },
                            serverInfo: {
                                name: "gitlab-knowledge-graph",
                                version: "0.1.0-mock"
                            }
                        }
                    };

                case 'tools/list':
                    return {
                        jsonrpc: "2.0",
                        id: request.id,
                        result: { tools: this.tools }
                    };

                case 'tools/call':
                    const toolName = request.params.name;
                    const args = request.params.arguments || {};

                    switch (toolName) {
                        case 'list_projects':
                            return {
                                jsonrpc: "2.0",
                                id: request.id,
                                result: {
                                    content: [{
                                        type: "text",
                                        text: `Indexed Projects:\\n\\nMock projects in knowledge graph:\\n- /data/projects/example-repo\\n- /data/projects/vps-infra\\n- /data/projects/sample-app\\n\\nTotal: 3 projects indexed\\n\\n⚠️ This is mock data. Real data will appear when official GKG is connected.`
                                    }]
                                }
                            };

                        case 'search_codebase_definitions':
                            const searchTerm = args.search_terms ? args.search_terms.join(', ') : 'N/A';
                            return {
                                jsonrpc: "2.0",
                                id: request.id,
                                result: {
                                    content: [{
                                        type: "text",
                                        text: `Search results for "${searchTerm}" in ${args.project_absolute_path}:\\n\\nMock definitions found:\\n\\n1. Function: ${args.search_terms?.[0] || 'example_function'}()\\n   Location: src/main.js:42\\n   Type: Function\\n   Signature: function(param1, param2)\\n\\n2. Class: ${args.search_terms?.[0] || 'ExampleClass'}\\n   Location: src/models/${args.search_terms?.[0]?.toLowerCase() || 'example'}.js:1\\n   Type: Class\\n   Methods: 3 methods\\n\\n3. Interface: I${args.search_terms?.[0] || 'ExampleInterface'}\\n   Location: src/interfaces/${args.search_terms?.[0]?.toLowerCase() || 'example'}.ts:1\\n   Type: Interface\\n\\nPage: ${args.page || 1}\\nNext page available: true\\n\\n⚠️ This is mock search data. Real search results will appear when official GKG is connected.`
                                    }]
                                }
                            };

                        case 'index_project':
                            return {
                                jsonrpc: "2.0",
                                id: request.id,
                                result: {
                                    content: [{
                                        type: "text",
                                        text: `Indexing project: ${args.project_absolute_path}\\n\\n✅ Indexing completed successfully!\\n\\nMock indexing statistics:\\n- Files scanned: 156\\n- Functions indexed: 1,247\\n- Classes indexed: 89\\n- Interfaces indexed: 34\\n- Relations found: 3,421\\n- Index size: 15.2 MB\\n- Processing time: 2.3 seconds\\n\\nProject is now ready for search and analysis.\\n\\n⚠️ This is mock indexing data. Real indexing will be performed by official GKG.`
                                    }]
                                }
                            };

                        case 'get_references':
                            return {
                                jsonrpc: "2.0",
                                id: request.id,
                                result: {
                                    content: [{
                                        type: "text",
                                        text: `References to "${args.definition_name}" in ${args.file_path}:\\n\\nMock references found:\\n\\n1. Function call\\n   File: src/main.js:45\\n   Type: Direct function call\\n   Context: const result = ${args.definition_name}();\\n\\n2. Import statement\\n   File: src/utils/helpers.js:123\\n   Type: ES6 import\\n   Context: import { ${args.definition_name} } from './${args.definition_name}';\\n\\n3. Test usage\\n   File: tests/test_${args.definition_name.toLowerCase()}.js:67\\n   Type: Unit test\\n   Context: test('${args.definition_name} works correctly', () => {...});\\n\\n4. Variable assignment\\n   File: src/config/index.js:15\\n   Type: Variable reference\\n   Context: const handler = ${args.definition_name};\\n\\nTotal: 4 references\\nPage: ${args.page || 1}\\n\\n⚠️ This is mock reference data. Real references will be found by official GKG.`
                                    }]
                                }
                            };

                        case 'read_definitions':
                            const defList = args.definitions?.map(def =>
                                `${def.name} (${def.file_path})`
                            ).join(', ') || 'No definitions provided';

                            return {
                                jsonrpc: "2.0",
                                id: request.id,
                                result: {
                                    content: [{
                                        type: "text",
                                        text: `Reading definitions: ${defList}\\n\\nMock definition bodies:\\n\\n${args.definitions?.map(def =>
                                            `=== ${def.name} (${def.file_path}) ===\\n\\nfunction ${def.name}(param1, param2) {\\n  // Mock implementation\\n  if (!param1 || !param2) {\\n    throw new Error('Missing required parameters');\\n  }\\n  return param1 + param2;\\n}\\n\\n// Dependencies: helper.js\\n// Used by: main.js, app.js\\n// Last modified: 2025-01-15\\n\\n`
                                        ).join('') || 'No definitions to read.'}\\n⚠️ This is mock definition data. Real definitions will be read by official GKG.`
                                    }]
                                }
                            };

                        case 'get_definition':
                            return {
                                jsonrpc: "2.0",
                                id: request.id,
                                result: {
                                    content: [{
                                        type: "text",
                                        text: `Definition for "${args.symbol_name}" at ${args.file_path}:${args.line}:\\n\\nMock definition found:\\n\\n=== Original Reference ===\\nFile: ${args.file_path}\\nLine: ${args.line}\\nCode: const result = ${args.symbol_name}();\\n\\n=== Definition Location ===\\nFile: src/core/${args.symbol_name.toLowerCase()}.js\\nLines: 15-28\\n\\nfunction ${args.symbol_name}(input) {\\n  // Main implementation\\n  const processed = processInput(input);\\n  const result = calculateResult(processed);\\n  return result;\\n}\\n\\n// Helper functions\\nfunction processInput(input) { /* ... */ }\\nfunction calculateResult(data) { /* ... */ }\\n\\n⚠️ This is mock navigation data. Real definition navigation will be provided by official GKG.`
                                    }]
                                }
                            };

                        case 'repo_map':
                            const pathList = args.relative_paths?.join(', ') || 'No paths specified';
                            return {
                                jsonrpc: "2.0",
                                id: request.id,
                                result: {
                                    content: [{
                                        type: "text",
                                        text: `Repository map for ${args.project_absolute_path}:\\n\\nAnalyzing paths: ${pathList}\\n\\nMock repository structure:\\n\\n📁 src/\\n  📄 main.js (15 functions, 3 classes)\\n  📁 components/\\n    📄 Header.jsx (1 component, 2 props)\\n    📄 Footer.jsx (1 component, 1 prop)\\n  📁 utils/\\n    📄 helpers.js (8 functions)\\n    📄 validators.js (5 functions)\\n  📁 models/\\n    📄 User.js (1 class, 4 methods)\\n    📄 Product.js (1 class, 6 methods)\\n\\n📁 tests/\\n  📄 unit/ (23 test files)\\n  📁 integration/ (12 test files)\\n\\n📁 docs/\\n  📄 README.md\\n  📄 API.md\\n\\n📁 config/\\n  📄 webpack.config.js\\n  📄 babel.config.js\\n\\nConfiguration:\\n- Max depth: ${args.depth || 3}\\n- Show directories: ${args.show_directories !== false}\\n- Show definitions: ${args.show_definitions !== false}\\n- Page: ${args.page || 1}\\n- Page size: ${args.page_size || 50}\\n\\nTotal items: 156 files, 89 definitions\\n\\n⚠️ This is mock repository map. Real structure will be analyzed by official GKG.`
                                    }]
                                }
                            };

                        default:
                            return {
                                jsonrpc: "2.0",
                                id: request.id,
                                error: {
                                    code: -32601,
                                    message: `Unknown tool: ${toolName}. Available tools: list_projects, search_codebase_definitions, index_project, get_references, read_definitions, get_definition, repo_map`
                                }
                            };
                    }

                default:
                    return {
                        jsonrpc: "2.0",
                        id: request.id,
                        error: {
                            code: -32601,
                            message: `Method not found: ${request.method}`
                        }
                    };
            }
        } catch (error) {
            return {
                jsonrpc: "2.0",
                error: {
                    code: -32700,
                    message: "Parse error"
                }
            };
        }
    }
}

const mcpServer = new MCPServer();

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url, true);

    // Enable CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    // Root endpoint
    if (parsedUrl.pathname === '/') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(`
<!DOCTYPE html>
<html>
<head>
    <title>GitLab Knowledge Graph - MCP Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f6f8fa; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #fc6d26; }
        .success { background: #e8f5e8; padding: 15px; border-radius: 6px; border-left: 4px solid #28a745; margin: 20px 0; }
        .tools { background: #f8f9fa; padding: 15px; border-radius: 6px; margin: 20px 0; }
        .endpoint { background: #f1f3f4; padding: 10px; border-radius: 4px; font-family: monospace; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 GitLab Knowledge Graph</h1>

        <div class="success">
            <strong>✅ MCP Server Running</strong><br>
            All official GitLab Knowledge Graph MCP tools are available
        </div>

        <div class="tools">
            <h3>Available MCP Tools:</h3>
            <ul>
                <li><strong>list_projects</strong> - Get all projects in knowledge graph</li>
                <li><strong>search_codebase_definitions</strong> - Search functions, classes, methods</li>
                <li><strong>index_project</strong> - Index/rebuild project knowledge graph</li>
                <li><strong>get_references</strong> - Find all references to a definition</li>
                <li><strong>read_definitions</strong> - Read multiple definition bodies</li>
                <li><strong>get_definition</strong> - Navigate to function/method definition</li>
                <li><strong>repo_map</strong> - Generate repository structure map</li>
            </ul>
        </div>

        <h3>API Endpoints:</h3>
        <div class="endpoint">MCP JSON-RPC: <strong>/mcp</strong></div>
        <div class="endpoint">Health Check: <strong>/status</strong></div>

        <p><em>Server is ready for MCP connections with all official GKG tools from https://gitlab-org.gitlab.io/rust/knowledge-graph/mcp/tools/</em></p>
    </div>
</body>
</html>
        `);
        return;
    }

    // Health check endpoint
    if (parsedUrl.pathname === '/status') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'healthy', service: 'gkg-mcp-server' }));
        return;
    }

    // MCP endpoint
    if (parsedUrl.pathname === '/mcp') {
        if (req.method !== 'POST') {
            res.writeHead(405, { 'Content-Type': 'text/plain' });
            res.end('Method Not Allowed');
            return;
        }

        let body = '';
        req.on('data', chunk => {
            body += chunk.toString();
        });

        req.on('end', () => {
            const response = mcpServer.handleMCPRequest(body);
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(response));
        });

        return;
    }

    // SSE endpoint (mock implementation)
    if (parsedUrl.pathname === '/mcp/sse') {
        res.writeHead(200, {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
            'Access-Control-Allow-Origin': '*'
        });

        // Send initial connection message
        res.write('event: connected\\n');
        res.write('data: {"type":"connected","message":"GKG MCP SSE connection established"}\\n\\n');

        // Send periodic heartbeat
        const heartbeat = setInterval(() => {
            res.write('event: heartbeat\\n');
            res.write(`data: {"timestamp":"${new Date().toISOString()}"}\\n\\n`);
        }, 30000);

        req.on('close', () => {
            clearInterval(heartbeat);
        });

        return;
    }

    // 404 for other paths
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
});

const PORT = process.env.PORT || 27495;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`GKG MCP Server listening on port ${PORT}`);
    console.log(`MCP endpoint: http://localhost:${PORT}/mcp`);
    console.log(`SSE endpoint: http://localhost:${PORT}/mcp/sse`);
});