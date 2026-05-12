# Cache FSM

## Locked Cache Policy

| Feature | Decision |
|---|---|
| Type | Unified direct-mapped cache |
| Lines | 16 |
| Line size | 1 word |
| Address width | 16-bit word address |
| Data width | 16-bit |
| Write policy | Write-through |
| Write miss policy | No-write-allocate |
| Read miss policy | Read-allocate |

## Address Split

Because each line stores exactly one word, there is no offset bit.

```text
address[15:4] = tag
address[3:0]  = index
```

Cache arrays:

```text
valid_array : 16 x 1
tag_array   : 16 x 12
data_array  : 16 x 16
```

## Read Behavior

Read hit:

```text
return data_array[index]
ready = 1
hit = 1
```

Read miss:

```text
request main memory
wait for memory ready
refill valid/tag/data arrays
return fetched data
ready = 1
miss = 1 during miss handling
```

## Write Behavior

Write hit:

```text
update data_array[index]
write same word to main memory
ready after memory write completes
```

Write miss:

```text
write directly to main memory
do not allocate cache line
ready after memory write completes
```

## FSM States

| State | Purpose |
|---|---|
| `IDLE` | Wait for CPU/arbiter request |
| `LOOKUP` | Read valid/tag/data arrays and compare tag |
| `HIT_READ` | Return cached read data |
| `HIT_WRITE` | Update cached word and start write-through |
| `MISS_READ_REQ` | Issue RAM read request |
| `MISS_READ_WAIT` | Wait for delayed RAM read response |
| `REFILL` | Fill cache line with RAM data |
| `MISS_WRITE_REQ` | Issue RAM write request without allocation |
| `MISS_WRITE_WAIT` | Wait for delayed RAM write completion |
| `DONE` | Pulse `ready`, then return to `IDLE` |

## Implementation Notes

- Only one outstanding request is allowed.
- Keep `addr`, `we`, and `wdata` latched while the FSM is not idle.
- `ready` should be a clean completion signal to the arbiter.
- Do not add dirty bits or write-back behavior.
