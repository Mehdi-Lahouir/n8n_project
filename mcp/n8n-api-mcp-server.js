#!/usr/bin/env node

const readline = require("node:readline");

const baseUrl = (process.env.N8N_API_BASE_URL || "http://localhost:5678").replace(/\/$/, "");
const apiKey = process.env.N8N_API_KEY;

const tools = [
  {
    name: "n8n_list_workflows",
    description: "List workflows in n8n.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "n8n_get_workflow",
    description: "Get one workflow by id.",
    inputSchema: {
      type: "object",
      required: ["id"],
      properties: { id: { type: "string" } },
      additionalProperties: false,
    },
  },
  {
    name: "n8n_create_workflow",
    description: "Create a workflow from a full n8n workflow JSON payload.",
    inputSchema: {
      type: "object",
      required: ["workflow"],
      properties: { workflow: { type: "object" } },
      additionalProperties: false,
    },
  },
  {
    name: "n8n_update_workflow",
    description: "Update a workflow by id using a full n8n workflow JSON payload.",
    inputSchema: {
      type: "object",
      required: ["id", "workflow"],
      properties: { id: { type: "string" }, workflow: { type: "object" } },
      additionalProperties: false,
    },
  },
  {
    name: "n8n_delete_workflow",
    description: "Delete a workflow by id.",
    inputSchema: {
      type: "object",
      required: ["id"],
      properties: { id: { type: "string" } },
      additionalProperties: false,
    },
  },
  {
    name: "n8n_list_credentials",
    description: "List credentials metadata. Secret values are not returned by n8n.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
  },
  {
    name: "n8n_get_credential",
    description: "Get credential metadata by id. Secret values are not returned by n8n.",
    inputSchema: {
      type: "object",
      required: ["id"],
      properties: { id: { type: "string" } },
      additionalProperties: false,
    },
  },
  {
    name: "n8n_create_credential",
    description: "Create an n8n credential. Requires a valid credential type and data payload.",
    inputSchema: {
      type: "object",
      required: ["credential"],
      properties: { credential: { type: "object" } },
      additionalProperties: false,
    },
  },
  {
    name: "n8n_update_credential",
    description: "Update an n8n credential by id. Requires a valid credential payload.",
    inputSchema: {
      type: "object",
      required: ["id", "credential"],
      properties: { id: { type: "string" }, credential: { type: "object" } },
      additionalProperties: false,
    },
  },
  {
    name: "n8n_delete_credential",
    description: "Delete a credential by id.",
    inputSchema: {
      type: "object",
      required: ["id"],
      properties: { id: { type: "string" } },
      additionalProperties: false,
    },
  },
];

function write(message) {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

async function n8n(path, options = {}) {
  if (!apiKey) {
    throw new Error("N8N_API_KEY is not configured");
  }

  const response = await fetch(`${baseUrl}/api/v1${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      "X-N8N-API-KEY": apiKey,
      ...(options.headers || {}),
    },
  });

  const text = await response.text();
  const body = text ? JSON.parse(text) : null;
  if (!response.ok) {
    throw new Error(`n8n API ${response.status}: ${text}`);
  }
  return body;
}

async function callTool(name, args) {
  switch (name) {
    case "n8n_list_workflows":
      return n8n("/workflows");
    case "n8n_get_workflow":
      return n8n(`/workflows/${encodeURIComponent(args.id)}`);
    case "n8n_create_workflow":
      return n8n("/workflows", { method: "POST", body: JSON.stringify(args.workflow) });
    case "n8n_update_workflow":
      return n8n(`/workflows/${encodeURIComponent(args.id)}`, {
        method: "PUT",
        body: JSON.stringify(args.workflow),
      });
    case "n8n_delete_workflow":
      return n8n(`/workflows/${encodeURIComponent(args.id)}`, { method: "DELETE" });
    case "n8n_list_credentials":
      return n8n("/credentials");
    case "n8n_get_credential":
      return n8n(`/credentials/${encodeURIComponent(args.id)}`);
    case "n8n_create_credential":
      return n8n("/credentials", { method: "POST", body: JSON.stringify(args.credential) });
    case "n8n_update_credential":
      return n8n(`/credentials/${encodeURIComponent(args.id)}`, {
        method: "PUT",
        body: JSON.stringify(args.credential),
      });
    case "n8n_delete_credential":
      return n8n(`/credentials/${encodeURIComponent(args.id)}`, { method: "DELETE" });
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

async function handle(message) {
  const { id, method, params = {} } = message;

  if (method === "initialize") {
    return {
      jsonrpc: "2.0",
      id,
      result: {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {} },
        serverInfo: { name: "n8n-api-mcp", version: "1.0.0" },
      },
    };
  }

  if (method === "tools/list") {
    return { jsonrpc: "2.0", id, result: { tools } };
  }

  if (method === "tools/call") {
    const result = await callTool(params.name, params.arguments || {});
    return {
      jsonrpc: "2.0",
      id,
      result: {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
      },
    };
  }

  if (method === "notifications/initialized") {
    return null;
  }

  return {
    jsonrpc: "2.0",
    id,
    error: { code: -32601, message: `Method not found: ${method}` },
  };
}

const rl = readline.createInterface({ input: process.stdin });
rl.on("line", async (line) => {
  if (!line.trim()) return;

  try {
    const response = await handle(JSON.parse(line));
    if (response) write(response);
  } catch (error) {
    let id = null;
    try {
      id = JSON.parse(line).id;
    } catch {
      // Keep JSON-RPC error id null for invalid input.
    }
    write({
      jsonrpc: "2.0",
      id,
      error: { code: -32000, message: error.message },
    });
  }
});
