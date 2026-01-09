# Documentation Cleanup Plan

**Goal:** Remove redundant markdowns, focus on core documentation, reduce context overflow.

---

## 🎯 Core Documentation (Keep These)

### Essential (5 Core Docs)
1. `docs/core/PROJECT_MASTER.md` - Complete project context
2. `docs/core/ARCHITECTURE_PRINCIPLES.md` - Non-negotiables vs flexible
3. `docs/core/BUILD_PLAN.md` - Execution plan (Weeks 1-12)
4. `docs/core/WORKFLOWS.md` - Business processes
5. `docs/core/WhatsApp_Commerce_Technical_KB.md` - Technical specs

### Supporting (Keep These)
- `docs/core/ARCHITECTURE.md` - System design details
- `docs/core/STRATEGIC_SETUP.md` - Setup strategy (NEW)
- `docs/architecture/WAAS_ARCHITECTURE.md` - Three-layer architecture
- `docs/guides/WEEK1_ACTION_PLAN.md` - Current week guide
- `docs/reference/QUICK_REFERENCE.md` - Quick lookup

---

## 🗑️ Files to Remove (Redundant)

### Root Level (Temporary Status Files)
- `COMPLETE_SETUP_GUIDE.md` → Merge into `docs/core/STRATEGIC_SETUP.md`
- `SETUP_STATUS.md` → Merge into `docs/core/STRATEGIC_SETUP.md`
- `PASSKEY_INFO.md` → Merge into `docs/core/WhatsApp_Commerce_Technical_KB.md`
- `MCP_QUICK_SETUP.md` → Merge into `docs/MCP_SETUP.md`
- `MCP_STATUS.md` → Remove (temporary)

### docshome/ (All Redundant)
- `docshome/` → **DELETE ENTIRE DIRECTORY**
  - All files are duplicates or outdated
  - Information exists in core docs

### Duplicates
- `docs/PROJECT_MASTER.md` → Remove (duplicate of `docs/core/PROJECT_MASTER.md`)
- `docs/BUILD_COMPLETE.md` → Remove (outdated status)
- `docs/HUMAN_HANDOFF_CHECKLIST.md` → Merge into `docs/core/WORKFLOWS.md`

### Archive (Keep for Reference)
- `docs/archive/` → Keep as-is (historical reference)

---

## 📋 Cleanup Actions

### Step 1: Merge Information
1. Merge setup guides into `docs/core/STRATEGIC_SETUP.md`
2. Merge passkey info into Technical KB
3. Merge MCP quick setup into `docs/MCP_SETUP.md`

### Step 2: Delete Redundant Files
1. Delete `docshome/` directory
2. Delete duplicate `docs/PROJECT_MASTER.md`
3. Delete temporary status files in root

### Step 3: Update References
1. Update `docs/00_START_HERE.md` with new structure
2. Update `docs/README.md` with cleaned structure
3. Update `.cursor-rules` if needed

---

## ✅ After Cleanup Structure

```
docs/
├── 00_START_HERE.md          # Master index
├── README.md                  # Documentation index
├── core/                      # ⭐ Single source of truth
│   ├── PROJECT_MASTER.md     # Complete context
│   ├── ARCHITECTURE_PRINCIPLES.md  # Non-negotiables
│   ├── BUILD_PLAN.md          # Execution plan
│   ├── WORKFLOWS.md           # Business processes
│   ├── WhatsApp_Commerce_Technical_KB.md  # Technical specs
│   ├── ARCHITECTURE.md        # System design
│   └── STRATEGIC_SETUP.md     # Setup strategy (NEW)
├── architecture/              # Architecture details
│   ├── WAAS_ARCHITECTURE.md
│   ├── TRADE_FACILITATOR_ARCHITECTURE.md
│   └── NATIVE_INTEGRATIONS.md
├── guides/                    # Implementation guides
│   ├── WEEK1_ACTION_PLAN.md
│   ├── MULTI_TENANT_GUIDE.md
│   └── MIGRATION_CHECKLIST.md
├── reference/                 # Reference materials
│   ├── QUICK_REFERENCE.md
│   ├── TEMPLATE_REGISTRY.md
│   ├── WEBHOOK_SCHEMAS.md
│   └── ...
├── MCP_SETUP.md               # MCP configuration
└── archive/                   # Historical reference
    └── ...
```

---

## 🎯 Benefits

1. **Reduced Context Overflow**: Focus on 5 core docs
2. **Single Source of Truth**: No conflicting information
3. **Easier Navigation**: Clear structure
4. **Faster Updates**: Update core docs, not duplicates

---

**Status:** Ready to execute cleanup
