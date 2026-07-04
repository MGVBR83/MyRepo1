# Server Infrastructure Inventory

## Overview

This page documents the server inventory across the **Dev**, **Test**, and **Prod** environments, organized by data classification layer and server category (Web/App vs. Database). This infrastructure supports the following applications:

- **App-Dev Apps** (bulk of the workload)
- **Globalscape** (Test and Prod only)
- **Azure AI Foundry** (Legislative AI)
- **Print Server**
- **EDMS**

> **Note:** In every environment, the SQL Listener is hosted on its own dedicated server within the Database category, separate from the two SQL servers in the Active/Passive pair.

---

## Environment Summary

| Environment | # of Data Classification Layers | Web/App Servers (Total) | Database Servers (Total) |
|---|---|---|---|
| Dev | 1 (no formal classification split) | 3 | 1 |
| Test | 3 | 12 | 9 (3 Listeners + 6 SQL) |
| Prod | 4 | 14 | 12 (4 Listeners + 8 SQL) + 1 SUDO Prod |

---

## Dev Environment

Dev does not use separate data classification layers — it has a single, flat structure with two categories.

### Web/App Category
| Server |
|---|
| Intranet |
| Internet |
| SSRS |

### Database Category
| Server |
|---|
| SQL Server (single instance) |

---

## Test Environment

Test is split into **three data classification layers**, each with its own Web/App and Database category.

### Layer 1: Intranet — Low/Medium Classification

**Web/App Category**
| Server |
|---|
| Intranet |
| SSRS |

**Database Category**
| Server | Role |
|---|---|
| SQL Listener | Listener (dedicated server) |
| SQL Server 1 | Active |
| SQL Server 2 | Passive |

### Layer 2: Internet — Low/Medium Classification

**Web/App Category**
| Server |
|---|
| Internet |
| Learning Center |
| Status Board |

**Database Category**
| Server | Role |
|---|---|
| SQL Listener | Listener (dedicated server) |
| SQL Server 1 | Active |
| SQL Server 2 | Passive |

### Layer 3: High Classification

**Web/App Category**
| Server |
|---|
| Claims Assistant |
| VSP |
| HR-ADLMV |
| MBFTE |
| Globalscape Gateway |
| Globalscape EFT |
| Globalscape File |

**Database Category**
| Server | Role |
|---|---|
| SQL Listener | Listener (dedicated server) |
| SQL Server 1 | Active |
| SQL Server 2 | Passive |

---

## Prod Environment

Prod is split into **four data classification layers** (Intranet/Internet × Low-Medium/High), each with its own Web/App and Database category.

### Layer 1: Intranet — Low/Medium Classification

**Web/App Category**
| Server |
|---|
| Intranet |

**Database Category**
| Server | Role |
|---|---|
| SQL Listener | Listener (dedicated server) |
| SQL Server 1 | Active |
| SQL Server 2 | Passive |

### Layer 2: Internet — Low/Medium Classification

**Web/App Category**
| Server |
|---|
| Intranet* |
| Learning Center |
| Status Board-1 |
| Status Board-2 |
| SSRS |

*\*Listed as "Intranet" under the Internet — Low/Medium layer per source data; recommend confirming whether this is intentional (e.g., a shared/mirrored instance) or a naming correction is needed.*

**Database Category**
| Server | Role |
|---|---|
| SQL Listener | Listener (dedicated server) |
| SQL Server 1 | Active |
| SQL Server 2 | Passive |

### Layer 3: Intranet — High Classification

**Web/App Category**
| Server |
|---|
| HR-ADLMV |

**Database Category**
| Server | Role |
|---|---|
| SQL Listener | Listener (dedicated server) |
| SQL Server 1 | Active |
| SQL Server 2 | Passive |

**Additional Server**
| Server | Notes |
|---|---|
| SUDO Prod Server | Associated with this layer |

### Layer 4: Internet — High Classification

**Web/App Category**
| Server |
|---|
| Claims Assistant |
| VSP |
| MBFTE |
| Globalscape Gateway |
| Globalscape EFT |
| Globalscape File |
| Globalscape File 2 |

**Database Category**
| Server | Role |
|---|---|
| SQL Listener | Listener (dedicated server) |
| SQL Server 1 | Active |
| SQL Server 2 | Passive |

---

## Data Classification Model at a Glance

| Environment | Intranet - Low/Med | Internet - Low/Med | Intranet - High | Internet - High |
|---|:---:|:---:|:---:|:---:|
| Dev | — (flat structure) | — | — | — |
| Test | ✅ | ✅ | ✅ (unified "High") | — |
| Prod | ✅ | ✅ | ✅ | ✅ |

*Note: Test's "High" classification layer is not explicitly split into Intranet/Internet the way Prod's is — it functions as a single combined High layer.*

---

## Related Applications Mapping

| Application | Dev | Test | Prod |
|---|:---:|:---:|:---:|
| App-Dev Apps | ✅ | ✅ | ✅ |
| Globalscape | — | ✅ (High layer) | ✅ (Internet - High layer) |
| Azure AI Foundry (Legislative AI) | ✅ | ✅ | ✅ |
| Print Server | ✅ | ✅ | ✅ |
| EDMS | ✅ | ✅ | ✅ |

---

## Open Items / Suggested Follow-ups

1. Confirm the "Intranet" server listing under Prod's **Internet — Low/Medium** layer — verify naming or duplication.
2. Confirm whether Test's "High" layer should eventually be split into Intranet-High / Internet-High to mirror Prod's model.
3. Document IP ranges, subnets, or network zones per layer if available, for a future network diagram.
4. Add server OS versions, sizing (vCPU/RAM), and ownership/support contacts per server for operational completeness.
