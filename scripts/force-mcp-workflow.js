#!/usr/bin/env node

const fs = require("node:fs");
const path = require("node:path");

const baseUrl = (process.env.N8N_API_BASE_URL || "http://localhost:5678").replace(/\/$/, "");
const apiKey = process.env.N8N_API_KEY;
const workflowFile = process.argv[2];

if (!apiKey) {
  console.error("N8N_API_KEY is required.");
  process.exit(1);
}

if (!workflowFile) {
  console.error("Usage: node scripts/force-mcp-workflow.js <workflow.json>");
  process.exit(1);
}

const workflowPath = path.resolve(workflowFile);
const workflow = JSON.parse(fs.readFileSync(workflowPath, "utf8"));

async function n8n(apiPath, options = {}) {
  const response = await fetch(`${baseUrl}/api/v1${apiPath}`, {
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

async function main() {
  if (workflow.id) {
    const updated = await n8n(`/workflows/${encodeURIComponent(workflow.id)}`, {
      method: "PUT",
      body: JSON.stringify(workflow),
    });
    console.log(`Updated workflow ${updated.id || workflow.id}`);
    return;
  }

  const created = await n8n("/workflows", {
    method: "POST",
    body: JSON.stringify(workflow),
  });
  console.log(`Created workflow ${created.id}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
