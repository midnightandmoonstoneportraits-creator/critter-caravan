# Critter Caravan — Architecture Document

## Overview

Critter Caravan is a cozy multiplayer Roblox experience built on the **Knit framework** (v1.4+), synchronized to Roblox via **Rojo 7.x**. The project follows a three-tier architecture: **Server** (authoritative game logic), **Client** (local presentation and input), and **Shared** (data definitions used by both).

---

## 1. Project Structure

```
critter-caravan/
├── default.project.json          # Rojo project configuration
├── package.json                  # Node.js dev dependencies (Rojo)
├── .gitignore
├── .vscode/
│   └── settings.json             # Luau LSP configuration
│
├── src/
│   ├── server/                   # → ServerScriptService.Knit
│   │   ├── init.server.luau      #   Knit bootstrapper (registers services, starts Knit)
│   │   ├── Top/
│   │   │   └── main.server.luau  #   Roblox entry point (requires init)
│   │   └── Services/             #   Knit Service modules
│   │       ├── CreatureService.luau    # Creature spawning, mutations, discovery
│   │       ├── PlayerDataService.luau  # Player profiles, persistence, data stores
│   │       └── CaravanService.luau     # Caravan building, upgrades, biome travel
│   │
│   ├── client/                   # → StarterPlayer.StarterPlayerScripts.Knit
│   │   ├── init.client.luau      #   Knit bootstrapper (registers controllers)
│   │   └── Controllers/          #   Knit Controller modules
│   │       └── CreatureController.luau # Proximity detection, mutation VFX, discovery UI
│   │
│   └── shared/                   # → ReplicatedStorage.Knit
│       ├── Knit.init.luau        #   Knit re-export module
│       ├── Data/                 #   Static game data definitions
│       │   ├── CreatureData.luau #     Creature definitions (stats, biomes, mutations)
│       │   ├── MutationData.luau #     Mutation definitions (rarity, stat modifiers, VFX)
│       │   ├── BiomeData.luau    #     Biome definitions (creature pools, visuals)
│       │   └── CaravanData.luau  #     Caravan chassis, decorations, upgrades
│       ├── Modules/              #   Reusable shared logic (future: event definitions)
│       └── Util/                 #   Utility modules
│           └── WeightedRandom.luau #   Weighted probability selection
```

## 2. Rojo Data Model Mapping (`default.project.json`)

| Source Path | Target in Roblox Data Model |
|---|---|
| `src/server/` | `ServerScriptService.Knit` |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Knit` |
| `src/shared/` | `ReplicatedStorage.Knit` |

### How to build & serve

```bash
# Serve for live sync (development)
npx rojo serve default.project.json

# Build to a standalone RBXLX file (production)
npx rojo build default.project.json --output critter-caravan.rbxlx
```

## 3. Knit Framework Conventions

### Services (Server-side)

All services live in `src/server/Services/` and follow this pattern:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local MyService = Knit.CreateService {
    Name = "MyService",
    Client = {
        MyMethod = Knit.CreateMethod(),  -- RemoteFunction exposed to clients
    },
}

-- Implementation
function MyService:SomeMethod()
    -- ...
end

-- Client-facing methods
function MyService.Client:MyMethod(player, ...)
    return self.Server:SomeMethod(player, ...)
end

return MyService
```

### Controllers (Client-side)

All controllers live in `src/client/Controllers/` and follow this pattern:

```lua
local Knit = require(game:GetService("ReplicatedStorage").Knit)

local MyController = Knit.CreateController {
    Name = "MyController",
}

function MyController:KnitStart()
    -- Initialization after all controllers are loaded
end

return MyController
```

### Accessing Other Services

```lua
local otherService = Knit.GetService("OtherServiceName")
```

### Accessing Shared Data

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CreatureData = require(ReplicatedStorage.Knit.Data.CreatureData)
```

## 4. Key Systems

### 4.1 Creature System

- **Spawning**: `CreatureService:GenerateCreature()` picks a creature type based on biome, rolls for mutations from `MutationData`, applies stat modifiers.
- **Discovery**: Client `CreatureController` detects tagged creatures via `CollectionService`, shows prompts. On interaction, server validates and records in `PlayerDataService`.
- **Mutations**: Server applies attributes (e.g., `Mutation_Giant`) that the client reads for local visual effects (scale changes, particle effects, material overrides).

### 4.2 Caravan System

- **Chassis**: Base vehicle stats (speed, capacity). Upgradable via `CaravanData.Upgrades`.
- **Decorations**: Cosmetic items purchasable from the shop. Applied via `CaravanService.ApplyDecoration()`.
- **Biome Travel**: Players navigate between biomes via `CaravanService.MoveToBiome()`. Biomes have level requirements.

### 4.3 Player Data

- **DataStore Persistence**: `PlayerDataService` uses the standard Roblox DataStore pattern (load on join, auto-save on leave).
- **Profile Structure**: Collected creatures, inventory items, caravan state, player settings.

## 5. Development Workflow

### Prerequisites

- [Rojo](https://rojo.space/) 7.x (`npx rojo` via npm)
- [Roblox Studio](https://create.roblox.com/) (for testing)
- Optional: [Luau LSP](https://github.com/JohnnyMorganz/luau-lsp) (VS Code extension for type checking)

### Workflow

1. **Edit code** in `src/` using any editor
2. **Serve** with `npx rojo serve` → plugin syncs to Roblox Studio live
3. **Test** in Studio
4. **Commit** changes to git

### Type Checking

The `.vscode/settings.json` configures Luau LSP for the Roblox platform. Enable the "Luau Language Server" extension in VS Code for real-time type checking with `.luau` file extensions.

## 6. Coding Standards

- **Naming**: PascalCase for services, controllers, and data modules. camelCase for methods and local variables.
- **Types**: Use Luau type annotations for all function parameters and returns (`player: Player`, `creatureType: string`).
- **Error Handling**: Use `pcall()` for DataStore operations. Return `{ success: boolean, error?: string }` from client-facing methods.
- **Comments**: Block comments (`--[[ ... ]]`) for module headers. Line comments (`--`) for logic explanations.
- **Dependencies**: Services reference each other via `Knit.GetService()`. Shared data is required from `ReplicatedStorage.Knit.Data.*`.

## 7. Future Considerations

- **Seasonal Events**: New `CreatureData` entries can be added per season. Mutation weights can be temporarily boosted.
- **Analytics**: A dedicated `AnalyticsService` can track discovery rates, popular biomes, and caravan customization stats.
- **Global Goals**: Shared community milestones (e.g., "Discover 1M creatures") can be managed via a `GlobalEventService`.
- **Monetization**: Seasonal Pass logic and shop integrations should be added to a dedicated `ShopService` and `PassService`.
