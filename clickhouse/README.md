# ClickHouse configs

These four files are copied verbatim from the Plausible CE **v3.2.1** tag by
`scripts/bootstrap-edge-stack.sh` and are mounted by `compose.yml`:

- `logs.xml`
- `ipv4-only.xml`
- `low-resources.xml`
- `default-profile-low-resources-overrides.xml`

They are intentionally not committed — they belong to upstream and must match the
pinned Plausible version. To fetch them manually:

```bash
git clone -b v3.2.1 --depth 1 https://github.com/plausible/community-edition /tmp/ce
cp /tmp/ce/clickhouse/*.xml .
```
