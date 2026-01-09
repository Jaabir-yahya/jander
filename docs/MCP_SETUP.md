# MCP (Model Context Protocol) Setup Guide

**Purpose:** Configure MCP servers to automate building and integration tasks for the Nairobi WhatsApp Commerce Platform.

**Status:** Supabase MCP already configured ✅

---

## 🎯 Recommended MCP Servers for This Project

### 1. ✅ Supabase MCP (Already Configured)
**Purpose:** Database operations, migrations, queries

**What it enables:**
- Run migrations automatically
- Query tenant_config, trades, payments tables
- Create/update records
- Check database health

**Status:** ✅ Already set up

---

### 2. 🌐 Playwright MCP (Required) ✅ Configured via Docker
**Purpose:** Browser automation, fetch instructions, documentation, API references from web

**Why needed:**
- Fetch Meta WhatsApp API documentation
- Get M-Pesa Daraja API examples
- Look up n8n workflow examples
- Find ERPNext integration guides
- Check service status pages
- Automate web interactions (form filling, clicking, etc.)

**Setup (Docker - Already Configured):**
```json
{
  "mcpServers": {
    "playwright": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "mcp/playwright"
      ]
    }
  }
}
```

**Status:** ✅ Already added to Docker MCP servers

**Available Tools (22 tools):**
- `browser_navigate` - Navigate to URLs
- `browser_snapshot` - Capture page accessibility snapshot
- `browser_take_screenshot` - Take screenshots
- `browser_click` - Click elements
- `browser_type` - Type text
- `browser_fill_form` - Fill forms
- `browser_evaluate` - Run JavaScript
- And 15 more tools for full browser automation

**Reference:** https://github.com/microsoft/playwright-mcp

---

### 3. 🔄 n8n MCP Integration (Two Ways)

**Purpose:** Connect n8n workflows with MCP servers and expose workflows as MCP tools

**Why needed:**
- Connect n8n to Supabase MCP server
- Connect n8n to ERPNext MCP server
- Expose n8n workflows as callable tools for AI agents
- Automate workflow execution

**Setup Options:**

**Option A: n8n as MCP Client (Connect to Supabase/ERPNext MCP)**
- Use n8n's **MCP Client Tool** node
- Connect to Supabase MCP server (SSE endpoint)
- Connect to ERPNext MCP server (SSE endpoint)
- This allows n8n workflows to use MCP tools

**Option B: n8n as MCP Server (Expose workflows as tools)**
- Use n8n's **MCP Server Trigger** node
- Expose n8n workflows as callable MCP tools
- AI agents can discover and execute your workflows
- Reference: https://www.leanware.co/insights/n8n-mcp-integration

**n8n MCP Setup in Workflows:**
1. Add **MCP Client Tool** node to connect to Supabase MCP
2. Add **MCP Client Tool** node to connect to ERPNext MCP
3. Configure with SSE endpoints and authentication tokens
4. Use MCP tools in your workflows

**For direct n8n API access (if needed):**
- Use n8n REST API: https://docs.n8n.io/api/
- Endpoints: `/api/v1/workflows`, `/api/v1/workflows/:id/activate`

---

### 4. 📊 ERPNext MCP (Optional - Week 5-8)
**Purpose:** Automate ERPNext integration tasks

**Why needed:**
- Create Sales Orders automatically
- Generate Invoices
- Update Payment Entries
- Query Customers, Products

**Setup Options:**

**Option A: ERPNext MCP Server (via Peliqan or custom)**
- Use platforms like Peliqan to publish ERPNext MCP server
- Or create custom MCP server wrapper
- Connect via n8n's MCP Client Tool node

**Option B: n8n ERPNext Node (Built-in)**
- n8n has built-in ERPNext node
- Configure with API Key + Secret from ERPNext
- No MCP needed - direct integration
- Reference: https://docs.n8n.io/integrations/builtin/credentials/erpnext/

**ERPNext API Setup:**
1. ERPNext Dashboard → Settings → My Settings → API Access
2. Generate API Key and Secret
3. Use in n8n ERPNext node or MCP server

**Note:** For MCP integration, use n8n's MCP Client Tool to connect to ERPNext MCP server

---

### 5. 📁 Filesystem MCP (Built-in)
**Purpose:** Read/write project files, update configurations

**What it enables:**
- Read migration files
- Update .env files
- Read workflow JSON files
- Update documentation

**Status:** Usually built into Cursor/Claude Desktop

---

### 6. 🔍 GitHub MCP (Optional)
**Purpose:** Version control, commit management

**Why useful:**
- Commit changes automatically
- Create branches
- Review diffs
- Manage releases

**Setup:**
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github",
        "--token",
        "YOUR_GITHUB_TOKEN"
      ]
    }
  }
}
```

---

## 🚀 Quick Setup Guide

### Step 1: Playwright MCP ✅ Already Configured

**Status:** ✅ Already added via Docker MCP servers

**Configuration (Already Done):**
```json
{
  "mcpServers": {
    "playwright": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "mcp/playwright"
      ]
    }
  }
}
```

**Test Playwright MCP:**
- Ask AI: "Navigate to developers.facebook.com/docs/whatsapp and take a snapshot"
- Ask AI: "Fetch the M-Pesa Daraja API documentation"
- Ask AI: "Take a screenshot of the n8n documentation page"

**Available Capabilities:**
- Navigate to any URL
- Take screenshots
- Fill forms automatically
- Click buttons and links
- Extract page content
- Run JavaScript on pages
- Monitor network requests

---

### Step 2: n8n MCP Integration (15 min)

**n8n supports MCP in two ways:**

**A. n8n as MCP Client (Connect to Supabase/ERPNext MCP):**
1. In n8n workflow, add **MCP Client Tool** node
2. Configure Supabase MCP:
   - SSE Endpoint: Your Supabase MCP server URL
   - Authentication: Supabase PAT (Personal Access Token)
3. Configure ERPNext MCP (if using):
   - SSE Endpoint: ERPNext MCP server URL
   - Authentication: ERPNext API token
4. Select tools from MCP servers to use in workflow

**B. n8n as MCP Server (Expose workflows as tools):**
1. In n8n workflow, add **MCP Server Trigger** node
2. Connect tool nodes to expose as callable tools
3. AI agents can discover and execute your workflows

**For direct API access (if needed):**
1. Start n8n: `n8n start`
2. Go to http://localhost:5678
3. Settings → API → Generate API key
4. Use REST API: `http://localhost:5678/api/v1/workflows`

---

### Step 3: ERPNext MCP (Optional - Week 5-8)

**Get ERPNext API credentials:**
1. ERPNext Dashboard → User Settings
2. API Access → Generate Keys
3. Copy API Key + API Secret

**Check for official MCP:**
```bash
npm search @erpnext/mcp
npm search mcp-server-erpnext
```

**If no official MCP:**
- Use ERPNext REST API directly
- Create custom MCP wrapper

---

## 🔧 Custom MCP Server Examples

### n8n Custom MCP Server (if needed)

**Create:** `mcp-servers/n8n-server/index.js`

```javascript
#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import axios from 'axios';

const N8N_API_URL = process.env.N8N_API_URL || 'http://localhost:5678/api/v1';
const N8N_API_KEY = process.env.N8N_API_KEY;

const server = new Server({
  name: 'n8n-mcp-server',
  version: '1.0.0',
}, {
  capabilities: {
    tools: {},
  },
});

// List workflows
server.setRequestHandler('tools/list', async () => ({
  tools: [
    {
      name: 'list_workflows',
      description: 'List all n8n workflows',
    },
    {
      name: 'create_workflow',
      description: 'Create a new n8n workflow',
      inputSchema: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          nodes: { type: 'array' },
        },
      },
    },
    {
      name: 'activate_workflow',
      description: 'Activate a workflow',
      inputSchema: {
        type: 'object',
        properties: {
          workflowId: { type: 'string' },
        },
      },
    },
  ],
}));

// Handle tool calls
server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;

  try {
    const headers = {
      'X-N8N-API-KEY': N8N_API_KEY,
      'Content-Type': 'application/json',
    };

    switch (name) {
      case 'list_workflows':
        const { data } = await axios.get(`${N8N_API_URL}/workflows`, { headers });
        return { content: [{ type: 'text', text: JSON.stringify(data, null, 2) }] };

      case 'create_workflow':
        const createRes = await axios.post(
          `${N8N_API_URL}/workflows`,
          { name: args.name, nodes: args.nodes, connections: {} },
          { headers }
        );
        return { content: [{ type: 'text', text: JSON.stringify(createRes.data, null, 2) }] };

      case 'activate_workflow':
        await axios.post(`${N8N_API_URL}/workflows/${args.workflowId}/activate`, {}, { headers });
        return { content: [{ type: 'text', text: 'Workflow activated' }] };

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [{ type: 'text', text: `Error: ${error.message}` }],
      isError: true,
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('n8n MCP server running on stdio');
}

main().catch(console.error);
```

**Add to MCP config:**
```json
{
  "mcpServers": {
    "n8n": {
      "command": "node",
      "args": ["mcp-servers/n8n-server/index.js"],
      "env": {
        "N8N_API_URL": "http://localhost:5678/api/v1",
        "N8N_API_KEY": "YOUR_API_KEY"
      }
    }
  }
}
```

---

## 📋 MCP Priority Setup Order

### Phase 1: Essential (Do Now)
1. ✅ **Supabase MCP** - Already configured
2. 🌐 **Browser MCP** - For fetching docs/instructions
3. 📁 **Filesystem MCP** - Usually built-in

### Phase 2: Automation (Week 1-2)
4. 🔄 **n8n MCP** - For workflow automation
   - Use REST API if no official MCP
   - Or create custom wrapper

### Phase 3: Integration (Week 5-8)
5. 📊 **ERPNext MCP** - For ERP integration
   - Use REST API if no official MCP
   - Or create custom wrapper

### Phase 4: Optional
6. 🔍 **GitHub MCP** - For version control automation

---

## 🧪 Testing MCPs

**Test Browser MCP:**
```
"Fetch the Meta WhatsApp Business API documentation from developers.facebook.com"
```

**Test Supabase MCP:**
```
"List all tables in the Supabase database"
```

**Test n8n MCP (if configured):**
```
"List all workflows in n8n"
```

---

## 📚 References

- **MCP Documentation:** https://modelcontextprotocol.io
- **n8n API Docs:** https://docs.n8n.io/api/
- **ERPNext API Docs:** https://frappeframework.com/docs/user/en/api/rest
- **Supabase MCP:** Already configured ✅

---

## 🎯 Recommended Configuration

**Current Setup (Week 1):**
```json
{
  "mcpServers": {
    "supabase": {
      // Already configured ✅
    },
    "playwright": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "mcp/playwright"
      ]
    }
  }
}
```

**Status:** ✅ Both Supabase and Playwright MCP configured

**n8n Integration (in n8n workflows, not MCP config):**
- Use **MCP Client Tool** node in n8n to connect to Supabase MCP
- Use **MCP Server Trigger** node to expose workflows as tools
- Configure in n8n UI, not in MCP config file

**ERPNext Integration (Week 5-8):**
- Option A: Use n8n's built-in **ERPNext** node (no MCP needed)
- Option B: Use n8n's **MCP Client Tool** to connect to ERPNext MCP server
- Configure in n8n UI, not in MCP config file

**Note:** n8n and ERPNext integration happens **inside n8n workflows**, not as separate MCP servers in your Cursor config. The MCP connection is:
- **AI → Supabase MCP** (direct, already configured)
- **AI → Browser MCP** (for fetching docs)
- **n8n → Supabase MCP** (via MCP Client Tool node in n8n)
- **n8n → ERPNext** (via ERPNext node or MCP Client Tool)

---

**Last Updated:** January 9, 2026  
**Status:** Supabase MCP configured ✅  
**Next:** Set up Browser MCP and n8n MCP
