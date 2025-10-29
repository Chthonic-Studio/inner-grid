# 🧠 The Inner Grid

A rapid, grid-based strategy game where the player races against the clock of their own mind, building a resilient resource network to survive the advance of a psychological blight.

---

## 💡 1. CORE CONCEPT & PITCH

**Game Title:** The Inner Grid
**Genre:** Real-Time Strategy (RTS), Grid-Based Survival, Roguelike Meta
**Engine:** Godot 4.5 (GDScript)
**Target Platform:** PC / WebGL
**Goal:** Successfully complete a 7-Level Run in the fastest total time possible.

### The Dual Clock
All gameplay revolves around the tension between two competing clocks:
1.  **The Blight Clock:** A **Fixed-Speed Blight** that constantly spreads and corrupts tiles. Each level aims for 3-5 minutes of gameplay.
2.  **The Network Clock:** The speed at which the player can establish and optimize their **Local Resource Collection** network to reach the level's goal resource target.

### The Narrative Hook
The game is a journey through the player character's unhandled trauma. Each of the 7 levels is a distinct psychological struggle. Narrative is delivered via **Voice Over (VO)** triggered by in-game **Crisis** (e.g., node destruction) and **Achievement** (e.g., goal reached) moments, ensuring the story aligns perfectly with the player's emotional stress.

---

## 🛠️ 2. ARCHITECTURE & DEVELOPMENT

We strictly adhere to a decoupled, component-based architecture for scalability and efficient development.

### Global Singletons (AutoLoad)
These systems manage application-wide state and persist across scene changes.

| AutoLoad | Purpose | Key Role |
| :--- | :--- | :--- |
| `GameManager` | Master State | Manages the game flow, holds **Run-Specific Adaptations**, and handles scene transitions via `LevelTransition`. |
| `AudioManager` | Audio Control | Handles all music, SFX, and **Narrative VO** playback. |
| `LevelManager` | Global Data | Stores the immutable configuration data for all 7 levels (Blight speeds, tile layouts, resource targets). |
| `SaveManager` | Persistence | Handles saving/loading high scores, unlocked **Mutators**, and run data. |
| `MainUI` | Persistent HUD | The permanent `CanvasLayer` for **Resource Counters**, **Narrative Display**, and Pause Menu. |
| `LevelTransition` | Visual Flow | Handles the screen fade/visual effects between the Main Menu and Level scenes. |

### Local Scene Structure
Level-specific logic is isolated to child nodes within the `Level.tscn` scene.

| Scene/Node | Type | Script | Key Responsibility |
| :--- | :--- | :--- | :--- |
| `Level` (Root) | `Control` | `Level.gd` | The **Controller**. Initializes the 16x10 grid, manages player input delegation (placement/sacrifice), and checks win/loss conditions. |
| `EconomyManager` | `Node` | `EconomyManager.gd` | Manages the local **Income** and **Goal Resource** totals for the *current level only*. Handles all purchasing and resource generation rates. |
| `BlightManager` | `Node` | `BlightManager.gd` | The **Simulation**. Manages Blight spread, corruption application, and reports the Base Node's health status. |
| `NarrativeManager` | `Node` | `NarrativeManager.gd` | Listens to local signals (e.g., `node_destroyed`) and sends cues to `AudioManager` for VO playback. |

### Component Structure
The grid is built from instanced scenes leveraging custom **Resource** scripts for data.

| Component | Scene/Resource | Logic Source | Detail |
| :--- | :--- | :--- | :--- |
| **Grid Cell** | `Tile.tscn` | `Tile.gd` | **Input & State.** A `Button` component handles clicks. `Tile.gd` manages the local `current_corruption` value and delegates placement requests to `Level.gd`. |
| **Placed Unit**| `Node.tscn` | `Node.gd` | **Universal Logic.** Receives a specific `NodeResource` (e.g., `Shield.tres`). `Node.gd` handles health, network connections, and reports status to local managers. |
| **Data** | `NodeResource` | Custom Resource | **Data Layer.** **8** separate `Resource` files store the static properties for each node (cost, health, output, etc.). |

---

## 3. GAMEPLAY MECHANICS

### The 8-Node System
The player uses 7 placeable nodes to manage the Blight on the $9\times9$ grid.

| Node Type | Strategic Verb | Key Mechanic |
| :--- | :--- | :--- |
| **Generator/Harvester**| **Economy/Goal** | Must maintain **Local Collection** connectivity to the **Base Node**. |
| **Shield Node** | **Active Defense** | Uses a **Charge/Discharge** system. Must recharge when not actively blocking corruption. |
| **Sensor Node** | **Zone Control** | Applies a passive AOE slow to the Blight spread rate. |
| **Synergy Node** | **Optimization** | Boosts the output/effectivity of adjacent nodes. |
| **Conduit Node** | **Reroute** | A zero-cost tile used solely to maintain network connectivity across long or corrupted distances. |
| **Purifier Node** | **Reclamation** | Actively reverses (rolls back) Blight corruption on adjacent tiles over time. |

### Tactical Sacrifice (Right-Click)
* Right-clicking any placed node triggers a **Tactical Sacrifice** (dismantle).
* **Effect:** Grants a small refund (minor refund logic managed by `EconomyManager`) and triggers an immediate **AOE Purge** (Blight rollback) on adjacent tiles. This is the player's high-risk, high-reward bailout move.

---

## 4. LEVEL & NARRATIVE PROGRESSION

The game features **7 distinct levels** on a fixed **16x10 grid**. Difficulty is created through **Blocked Tiles** and unique mechanical challenges, not map size.

| Level | Narrative Theme | Key Mechanical Challenge | Focus |
| :--- | :--- | :--- | :--- |
| **1** | **Impostor Syndrome** | Tutorial Pace, Focus on **Synergy**. | Cluster Build / Economic Optimization. |
| **2** | **Overwhelm/Anxiety** | Blight attacks from two opposite sides (Dual Threat). | Split-Defense Strategy (Shield/Sensor). |
| **3** | **Isolation/Disconnection**| Map split by a permanent barrier. Requires **Conduit** network across a high-pressure choke point. | Network Link & Tactical Sacrifice. |
| **4** | **Burnout/Chronic Stress** | Blight spawning is **Constant and Randomized** on all borders. High Goal Resource requirement. | Purifier Reclamation & Output Optimization. |
| **5** | **Loss/Sudden Shock** | Blight spawns once but moves **extremely fast** on a fixed trajectory. | Single-Line, Overwhelming Defense. |
| **6** | **Regret/Unchangeable Past**| **Permanent Scars:** Specific tiles are permanently corrupted and cannot be cleaned by the **Purifier**. | Bypass and Adaptation around fixed flaws. |
| **7** | **Letting Go/Adaptation** | **Base Teleport:** After 90 seconds, the **Base Node automatically teleports** to a new location, requiring an instant network reroute. | Dynamic Network Management & Conduit use. |

---

## 5. META-GAME & REPLAYABILITY

The post-level loop provides strategic depth without permanent power creep.

### Run-Specific Strategic Adaptations
* **Trigger:** End of Levels 1 through 6.
* **Mechanism:** Player is presented with **3 random Strategic Adaptations** (chosen from a pool of 18) and must select one. These are explicitly designed as **trade-offs** (e.g., higher generator output but slower shield recharge).
* **Persistence:** The chosen adaptation lasts **only for the current run**.

### Replay Incentives
* **Node Mutators:** Unlocked after the first Level 7 completion. Allows the player to select **one positive and one negative global rule change** at the start of a new run (e.g., Synergy buff increased + Blight ignores Shield 20% of the time).
* **Speedrunning:** The game tracks the sum of all 7 level clear times, encouraging players to master the **Adaptations** and compete for the fastest total run time.
* **Failsafe:** A **"Reset Run"** button is always available in the Main Menu to start fresh without penalty.

---

## 6. VISUAL & STYLE GUIDE

* **Aesthetics:** Minimalist, geometric forms with high-contrast color coding.
* **Visual Focus:** Heavy use of **Godot Shaders** to handle Blight corruption effects, node glows, and connection lines, reducing reliance on complex art assets.
* **Color Palette:** Black, White, Dark Blue, Dark Red.
