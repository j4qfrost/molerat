pub run aqueduct db generate
pub run aqueduct db upgrade --connect postgres://postgres:${PGPASSWORD}@localhost:5432/${DATABASE}
pub run aqueduct auth add-client --id com.tunneler.app --connect postgres://postgres:${PGPASSWORD}@localhost:5432/${DATABASE}