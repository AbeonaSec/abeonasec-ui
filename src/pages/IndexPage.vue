<template>
  <q-page class="q-pa-lg">
    <div class="dashboard-container">
      <div class="text-h5 text-weight-medium q-mb-md">Overview</div>

      <!-- ONE GRID ROW -->
      <div class="row q-col-gutter-lg">

        <!-- Health Overview -->
        <div class="col-12 col-md-6" clickable @click="$router.push('/health')">
          <div class="row items-center justify-between q-mb-sm">
            <div class="text-h6">System Health</div>
            <q-icon name="monitor_heart" size="24px" color="positive" />
          </div>

          <q-card class="dashboard-card">
            <div v-for="metric in gaugeMetrics" :key="metric.label">
              <q-card-section class="text-center">
                <q-circular-progress
                  :value="metric.percent"
                  size="70px"
                  :thickness="0.15"
                  :color="gaugeColor(metric.percent)"
                  track-color="grey-3"
                  class="q-mb-sm"
                >
                  <span class="text-subtitle2">
                    {{ loading ? '—' : metric.percent + '%' }}
                  </span>
                </q-circular-progress>
                <div class="text-subtitle2 q-mt-xs">{{ metric.label }}</div>
                <div class="text-caption text-grey">{{ metric.detail }}</div>
              </q-card-section>
            </div>
          </q-card>
        </div>

        <!-- Threat Management -->
        <div class="col-12 col-md-6" clickable @click="$router.push('/threats')">
          <div class="row items-center justify-between q-mb-sm">
            <div class="text-h6">Threat Management</div>
            <q-icon name="shield" size="24px" color="warning" />
          </div>
          <q-card>
          <q-table
            :rows="threats"
            :columns="columnsTM"
            row-key="idx"
            :loading="loadingTM"
            flat
            :rows-per-page-options="[25, 50, 100]"
            v-model:pagination="paginationTM"
            @request="onTableRequestTM"
            binary-state-sort
            @row-click="onRowClickTM"
            style="cursor: pointer"
          >
            <template v-slot:body-cell-severity="props">
              <q-td :props="props">
                <q-badge v-if="props.row.probs" color="negative" label="Critical" />
                <q-badge v-else color="grey-6" label="Normal" />
              </q-td>
            </template>

            <template v-slot:body-cell-protocol="props">
              <q-td :props="props">
                <q-badge :color="protocolColorTM(props.value)" :label="props.value" />
              </q-td>
            </template>

            <template v-slot:body-cell-timestamp="props">
              <q-td :props="props">{{ fmtTimeTM(props.value) }}</q-td>
            </template>

            <template v-slot:body-cell-source="props">
              <q-td :props="props">
                <span class="text-mono">{{ props.row.src_ip }}</span>
                <span class="text-caption text-grey q-ml-xs">:{{ props.row.src_port }}</span>
              </q-td>
            </template>

            <template v-slot:body-cell-dest="props">
              <q-td :props="props">
                <span class="text-mono">{{ props.row.dest_ip }}</span>
                <span class="text-caption text-grey q-ml-xs">:{{ props.row.dest_port }}</span>
              </q-td>
            </template>

            <template v-slot:no-data>
              <div class="full-width text-center text-grey q-pa-md">
                {{ errorTM || 'No records found' }}
              </div>
            </template>
          </q-table>
          </q-card>
        </div>

        <!-- Logs -->
        <div class="col-12 col-md-6" clickable @click="$router.push('/logs')">
          <div class="row items-center justify-between q-mb-sm">
            <div class="text-h6">Logs</div>
            <q-icon name="receipt_long" size="24px" color="info" />
          </div>
          <q-card>
          <q-table
            :rows="logs"
            :columns="columns"
            row-key="idx"
            :loading="loading"
            flat
            :rows-per-page-options="[25, 50, 100]"
            v-model:pagination="pagination"
            @request="onTableRequest"
            binary-state-sort
            @row-click="onRowClick"
            style="cursor: pointer"
          >
            <template v-slot:body-cell-protocol="props">
              <q-td :props="props">
                <q-badge :color="protocolColor(props.value)" :label="props.value" />
              </q-td>
            </template>

            <template v-slot:body-cell-timestamp="props">
              <q-td :props="props">
                {{ fmtTime(props.value) }}
              </q-td>
            </template>

            <template v-slot:body-cell-flags="props">
              <q-td :props="props">
                <span class="text-caption text-grey">
                  {{ fmtFlags(props.row.flags, props.row.protocol_num) }}
                </span>
              </q-td>
            </template>

            <template v-slot:no-data>
              <div class="full-width text-center text-grey q-pa-md">
                {{ errorLogs || 'No records found' }}
              </div>
            </template>
          </q-table>
          </q-card>
        </div>

        <!-- Plugins -->
        <div class="col-12 col-md-6">
          <div class="row items-center justify-between q-mb-sm">
            <div class="text-h6">Plugins</div>
            <q-icon name="extension" size="24px" color="accent" />
          </div>

          <q-card class="dashboard-card q-pa-md flex flex-center text-grey">
            Plugins (coming soon)
          </q-card>
        </div>

      </div>
    </div>
  </q-page>
</template>

<script setup>
// const cards = [
//   { title: 'System Health', icon: 'monitor_heart', color: 'positive', link: '/health' },
//   { title: 'Threat Management', icon: 'shield', color: 'warning', link: '/threats' },
//   { title: 'Logs', icon: 'receipt_long', color: 'info', link: '/logs' },
//   { title: 'Plugins', icon: 'extension', color: 'accent', link: '/plugins' }
// ]


// For importing the system health
import { ref, computed, onMounted, onUnmounted } from 'vue'

const data = ref(null)
const loading = ref(false)
const error = ref(null)
let interval = null

async function fetchHealth (showLoading = false) {
  if (showLoading) loading.value = true
  error.value = null
  try {
    const res = await fetch('/api/health')
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    data.value = await res.json()
  } catch (e) {
    error.value = `Failed to reach API: ${e.message}`
  } finally {
    if (showLoading) loading.value = false
  }
}

const gaugeMetrics = computed(() => {
  if (!data.value) return [
    { label: 'CPU', percent: 0, detail: '' },
    { label: 'Memory', percent: 0, detail: '' },
    { label: 'Disk', percent: 0, detail: '' },
  ]
  const d = data.value
  return [
    { label: 'CPU', percent: d.cpu.percent, detail: `${d.cpu.percent}%` },
    { label: 'Memory', percent: d.memory.percent, detail: `${d.memory.used_gb} / ${d.memory.total_gb} GB` },
    { label: 'Disk', percent: d.disk.percent, detail: `${d.disk.used_gb} / ${d.disk.total_gb} GB` },
  ]
})

function gaugeColor (pct) {
  if (pct >= 90) return 'negative'
  if (pct >= 70) return 'warning'
  return 'positive'
}

onMounted(() => {
  fetchHealth(true)
  interval = setInterval(fetchHealth, 3000)
})

onUnmounted(() => clearInterval(interval))

// For Logs
const logs = ref([])
const total = ref(0)
const loadingLogs = ref(false)
const errorLogs = ref('')
const searchQuery = ref('')
const protocolFilter = ref('All')

const showDetail = ref(false)
const detail = ref(null)
const detailLoading = ref(false)
const detailError = ref('')

async function onRowClick (_, row) {
  showDetail.value = true
  detail.value = null
  detailError.value = ''
  detailLoading.value = true
  try {
    const res = await fetch(`/api/logs/${row._id}`)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    detail.value = await res.json()
  } catch (e) {
    detailError.value = e.message
  } finally {
    detailLoading.value = false
  }
}

const pagination = ref({
  page: 1,
  rowsPerPage: 10,
  rowsNumber: 0,
  sortBy: null,
  descending: true,
})

const columns = [
  { name: 'timestamp', label: 'Time', field: 'timestamp', align: 'left', sortable: false, style: 'width: 160px' },
  { name: 'protocol', label: 'Proto', field: 'protocol', align: 'center', sortable: false, style: 'width: 80px' },
  { name: 'src_ip', label: 'Source IP', field: 'src_ip', align: 'left' },
  { name: 'src_port', label: 'Src Port', field: 'src_port', align: 'right', style: 'width: 90px' },
  { name: 'dest_ip', label: 'Dest IP', field: 'dest_ip', align: 'left' },
  { name: 'dest_port', label: 'Dst Port', field: 'dest_port', align: 'right', style: 'width: 90px' },
  { name: 'data_len', label: 'Bytes', field: 'data_len', align: 'right', style: 'width: 80px' },
  { name: 'flags', label: 'Flags', field: 'flags', align: 'left', style: 'width: 100px' },
]

const TCP_FLAGS = [
  { bit: 0x01, label: 'FIN' },
  { bit: 0x02, label: 'SYN' },
  { bit: 0x04, label: 'RST' },
  { bit: 0x08, label: 'PSH' },
  { bit: 0x10, label: 'ACK' },
  { bit: 0x20, label: 'URG' },
]

function fmtFlags (flags, protocolNum) {
  if (Number(protocolNum) !== 6 || flags == null) return '—'
  const flagsNum = typeof flags === 'string' ? parseInt(flags, 10) : flags
  if (isNaN(flagsNum)) return '—'
  const active = TCP_FLAGS.filter(f => flagsNum & f.bit).map(f => f.label)
  return active.length ? active.join(' ') : '—'
}

function fmtTime (ts) {
  if (!ts) return '—'
  const num = Number(ts)
  if (!isNaN(num)) return new Date(num / 1000).toLocaleString()
  const d = new Date(ts)
  return isNaN(d.getTime()) ? String(ts) : d.toLocaleString()
}

function protocolColor (proto) {
  return { TCP: 'blue-7', UDP: 'teal-7', ICMP: 'orange-7', IGMP: 'purple-7', ICMPv6: 'cyan-7' }[proto] ?? 'grey-7'
}

function onTableRequest (props) {
  pagination.value.page = props.pagination.page
  pagination.value.rowsPerPage = props.pagination.rowsPerPage
  fetchLogs()
}

async function fetchLogs () {
  loadingLogs.value = true
  errorLogs.value = ''
  const { page, rowsPerPage } = pagination.value
  const offset = (page - 1) * rowsPerPage
  const params = new URLSearchParams({
    search: searchQuery.value,
    protocol: protocolFilter.value,
    size: rowsPerPage,
    offset,
  })
  try {
    const res = await fetch(`/api/logs?${params}`)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    logs.value = data.logs.map((r, i) => ({ ...r, idx: offset + i }))
    total.value = data.total
    pagination.value.rowsNumber = data.total
  } catch (e) {
    errorLogs.value = `Failed to load logs: ${e.message}`
  } finally {
    loadingLogs.value = false
  }
}

onMounted(fetchLogs)


// For threat management
const threats = ref([])
const totalTM = ref(0)
const loadingTM = ref(false)
const errorTM = ref('')
const searchQueryTM = ref('')
const protocolFilterTM = ref('All')
const severityFilter = ref('critical')

const stats = ref({ total: 0, today: 0, by_protocol: [], top_src_ips: [] })

const showDetailTM = ref(false)
const detailTM = ref(null)
const detailLoadingTM = ref(false)
const detailErrorTM = ref('')

async function onRowClickTM (_, row) {
  showDetailTM.value = true
  detailTM.value = null
  detailErrorTM.value = ''
  detailLoadingTM.value = true
  try {
    const res = await fetch(`/api/logs/${row._id}`)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    detailTM.value = { ...data, probs: row.probs }
  } catch (e) {
    detailErrorTM.value = e.message
  } finally {
    detailLoadingTM.value = false
  }
}

const paginationTM = ref({
  page: 1,
  rowsPerPage: 10,
  rowsNumber: 0,
  sortBy: null,
  descending: true,
})

const columnsTM = [
  { name: 'severity', label: 'Severity', field: 'probs', align: 'center', sortable: false, style: 'width: 100px' },
  { name: 'timestamp', label: 'Time', field: 'timestamp', align: 'left', sortable: false, style: 'width: 160px' },
  { name: 'protocol', label: 'Proto', field: 'protocol', align: 'center', sortable: false, style: 'width: 80px' },
  { name: 'source', label: 'Source', field: 'src_ip', align: 'left' },
  { name: 'dest', label: 'Destination', field: 'dest_ip', align: 'left' },
]


function fmtTimeTM (ts) {
  if (!ts) return '—'
  const num = Number(ts)
  if (!isNaN(num)) return new Date(num / 1000).toLocaleString()
  const d = new Date(ts)
  return isNaN(d.getTime()) ? String(ts) : d.toLocaleString()
}

function protocolColorTM (proto) {
  return { TCP: 'blue-7', UDP: 'teal-7', ICMP: 'orange-7', IGMP: 'purple-7', ICMPv6: 'cyan-7' }[proto] ?? 'grey-7'
}

function onTableRequestTM (props) {
  pagination.value.page = props.pagination.page
  pagination.value.rowsPerPage = props.pagination.rowsPerPage
  fetchThreats()
}

async function fetchStatsTM () {
  try {
    const res = await fetch('/api/threats/stats')
    if (!res.ok) return
    stats.value = await res.json()
  } catch {
    // silently ignore
  }
}

async function fetchThreats () {
  loading.value = true
  errorTM.value = ''
  threats.value = []
  totalTM.value = 0
  const { page, rowsPerPage } = pagination.value
  const offset = (page - 1) * rowsPerPage
  const params = new URLSearchParams({
    search: searchQueryTM.value,
    protocol: protocolFilterTM.value,
    severity: severityFilter.value,
    size: rowsPerPage,
    offset,
  })
  try {
    const res = await fetch(`/api/threats?${params}`)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    threats.value = data.threats.map((r, i) => ({ ...r, idx: offset + i }))
    totalTM.value = data.total
    pagination.value.rowsNumber = data.total
  } catch (e) {
    errorTM.value = `Failed to load: ${e.message}`
  } finally {
    loadingTM.value = false
  }
}

onMounted(() => {
  fetchStatsTM()
  fetchThreats()
})

</script>

<style scoped>
.dashboard-container {
  max-width: 1200px;
  margin: 0 auto;
}

.dashboard-card {
  border-radius: 14px;
  transition: box-shadow 0.2s ease;
}

.dashboard-card:hover {
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.12);
}
</style>