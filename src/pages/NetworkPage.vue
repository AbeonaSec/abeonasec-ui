<template>
  <q-page class="q-pa-lg">
    <div class="page-container">
      <div class="row items-center q-mb-md">
        <div class="text-h5 text-weight-medium col">Network</div>
        <q-btn flat round icon="refresh" :loading="loading" @click="fetchNetwork(true)" />
      </div>

      <div v-if="error" class="text-negative q-mb-md text-body2">{{ error }}</div>

      <!-- Summary cards -->
      <div class="row q-col-gutter-md q-mb-lg">
        <div class="col-6 col-md-3" v-for="stat in displayStats" :key="stat.label">
          <q-card class="page-card">
            <q-card-section class="text-center">
              <q-icon :name="stat.icon" size="28px" color="grey" class="q-mb-xs" />
              <div class="text-h5 text-weight-bold" :class="data ? 'text-primary' : 'text-grey'">
                {{ data ? stat.value : '—' }}
              </div>
              <div class="text-caption text-grey">{{ stat.label }}</div>
            </q-card-section>
          </q-card>
        </div>
      </div>

      <!-- Tabbed panels -->
      <q-card class="page-card">
        <q-tabs v-model="activeTab" dense align="left" class="text-grey" active-color="primary" indicator-color="primary">
          <q-tab name="connections" label="Active Connections" icon="cable" />
          <q-tab name="traffic" label="Traffic" icon="swap_vert" />
          <q-tab name="interfaces" label="Interfaces" icon="settings_ethernet" />
        </q-tabs>
        <q-separator />

        <q-tab-panels v-model="activeTab" animated>

          <!-- Connections tab -->
          <q-tab-panel name="connections" class="q-pa-none">
            <q-table
              :rows="data?.connections ?? []"
              :columns="connCols"
              row-key="local_addr"
              dense
              flat
              :loading="loading && !data"
              :pagination="{ rowsPerPage: 25 }"
            >
              <template #body-cell-status="props">
                <q-td :props="props">
                  <q-badge :color="statusColor(props.value)" :label="props.value" />
                </q-td>
              </template>
              <template #no-data>
                <div class="full-width text-center text-grey q-pa-md">No active connections</div>
              </template>
            </q-table>
          </q-tab-panel>

          <!-- Traffic tab -->
          <q-tab-panel name="traffic" class="q-pa-none">
            <q-table
              :rows="data?.traffic ?? []"
              :columns="trafficCols"
              row-key="interface"
              dense
              flat
              :loading="loading && !data"
              :pagination="{ rowsPerPage: 25 }"
            >
              <template #no-data>
                <div class="full-width text-center text-grey q-pa-md">No traffic data</div>
              </template>
            </q-table>
          </q-tab-panel>

          <!-- Interfaces tab -->
          <q-tab-panel name="interfaces" class="q-pa-none">
            <q-table
              :rows="data?.interfaces ?? []"
              :columns="ifaceCols"
              row-key="name"
              dense
              flat
              :loading="loading && !data"
              :pagination="{ rowsPerPage: 25 }"
            >
              <template #body-cell-isup="props">
                <q-td :props="props">
                  <q-badge :color="props.value ? 'positive' : 'negative'" :label="props.value ? 'UP' : 'DOWN'" />
                </q-td>
              </template>
              <template #body-cell-addresses="props">
                <q-td :props="props">
                  <div v-for="addr in props.value" :key="addr.address" class="text-caption">
                    <span class="text-grey-6">{{ addr.family }}:</span> {{ addr.address }}
                  </div>
                </q-td>
              </template>
              <template #no-data>
                <div class="full-width text-center text-grey q-pa-md">No interfaces found</div>
              </template>
            </q-table>
          </q-tab-panel>

        </q-tab-panels>
      </q-card>
    </div>
  </q-page>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const activeTab = ref('connections')
const data = ref(null)
const loading = ref(false)
const error = ref(null)
let interval = null

function fmtRate(bps) {
  if (bps >= 1e6) return `${(bps / 1e6).toFixed(1)} MB/s`
  if (bps >= 1e3) return `${(bps / 1e3).toFixed(1)} KB/s`
  return `${bps.toFixed(0)} B/s`
}

function fmtBytes(b) {
  if (b >= 1e9) return `${(b / 1e9).toFixed(2)} GB`
  if (b >= 1e6) return `${(b / 1e6).toFixed(1)} MB`
  if (b >= 1e3) return `${(b / 1e3).toFixed(1)} KB`
  return `${b} B`
}

const displayStats = computed(() => [
  { label: 'Active Connections', icon: 'cable',         value: data.value?.stats.connections_count ?? '—' },
  { label: 'Inbound Rate',       icon: 'arrow_downward', value: data.value ? fmtRate(data.value.stats.inbound_bps) : '—' },
  { label: 'Outbound Rate',      icon: 'arrow_upward',   value: data.value ? fmtRate(data.value.stats.outbound_bps) : '—' },
  { label: 'Blocked Today',      icon: 'block',          value: data.value?.stats.blocked_today ?? '—' },
])

function statusColor(status) {
  const map = { ESTABLISHED: 'positive', LISTEN: 'info', TIME_WAIT: 'warning', CLOSE_WAIT: 'warning', NONE: 'grey' }
  return map[status] ?? 'grey'
}

const connCols = [
  { name: 'type',        label: 'Type',         field: 'type',        align: 'left', sortable: true },
  { name: 'family',      label: 'Family',       field: 'family',      align: 'left', sortable: true },
  { name: 'local_addr',  label: 'Local',        field: 'local_addr',  align: 'left' },
  { name: 'remote_addr', label: 'Remote',       field: 'remote_addr', align: 'left' },
  { name: 'status',      label: 'Status',       field: 'status',      align: 'left', sortable: true },
  { name: 'pid',         label: 'PID',          field: 'pid',         align: 'right', sortable: true },
]

const trafficCols = [
  { name: 'interface',    label: 'Interface',   field: 'interface',    align: 'left', sortable: true },
  { name: 'bytes_recv',   label: 'Received',    field: 'bytes_recv',   align: 'right', sortable: true, format: fmtBytes },
  { name: 'bytes_sent',   label: 'Sent',        field: 'bytes_sent',   align: 'right', sortable: true, format: fmtBytes },
  { name: 'packets_recv', label: 'Pkts In',     field: 'packets_recv', align: 'right', sortable: true },
  { name: 'packets_sent', label: 'Pkts Out',    field: 'packets_sent', align: 'right', sortable: true },
  { name: 'errin',        label: 'Err In',      field: 'errin',        align: 'right', sortable: true },
  { name: 'errout',       label: 'Err Out',     field: 'errout',       align: 'right', sortable: true },
  { name: 'dropin',       label: 'Drop In',     field: 'dropin',       align: 'right', sortable: true },
  { name: 'dropout',      label: 'Drop Out',    field: 'dropout',      align: 'right', sortable: true },
]

const ifaceCols = [
  { name: 'name',       label: 'Name',      field: 'name',       align: 'left', sortable: true },
  { name: 'isup',       label: 'Status',    field: 'isup',       align: 'left', sortable: true },
  { name: 'speed_mbps', label: 'Speed',     field: 'speed_mbps', align: 'right', sortable: true, format: v => v ? `${v} Mbps` : '—' },
  { name: 'mtu',        label: 'MTU',       field: 'mtu',        align: 'right', sortable: true },
  { name: 'addresses',  label: 'Addresses', field: 'addresses',  align: 'left' },
]

async function fetchNetwork(showLoading = false) {
  if (showLoading) loading.value = true
  try {
    const res = await fetch('/api/network')
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    data.value = await res.json()
    error.value = null
  } catch (e) {
    error.value = `Failed to load network data: ${e.message}`
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchNetwork(true)
  interval = setInterval(fetchNetwork, 3000)
})

onUnmounted(() => {
  clearInterval(interval)
})
</script>

<style scoped>
.page-container { max-width: 1400px; margin: 0 auto; }
.page-card { border-radius: 14px; }
</style>
