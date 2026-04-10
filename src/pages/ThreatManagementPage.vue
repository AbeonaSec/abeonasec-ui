<template>
  <q-page class="q-pa-lg">
    <div class="page-container">
      <div class="row items-center justify-between q-mb-md">
        <div class="text-h5 text-weight-medium">Threat Management</div>
        <div class="text-caption text-grey">{{ total.toLocaleString() }} records</div>
      </div>

      <!-- Stats cards -->
      <div class="row q-col-gutter-md q-mb-lg">
        <div class="col-6 col-md-3" v-for="stat in displayStats" :key="stat.label">
          <q-card class="page-card">
            <q-card-section class="row items-center q-gutter-sm">
              <q-icon :name="stat.icon" size="28px" :color="stat.color" />
              <div>
                <div class="text-caption text-grey">{{ stat.label }}</div>
                <div class="text-h6 text-weight-medium">{{ stat.value }}</div>
              </div>
            </q-card-section>
          </q-card>
        </div>
      </div>

      <!-- Filter bar -->
      <q-card class="page-card q-mb-lg">
        <q-card-section class="row items-center q-gutter-md">
          <q-input
            dense outlined clearable
            placeholder="Search IPs or MACs…"
            v-model="searchQuery"
            class="col-grow"
            @update:model-value="onFilterChange"
          >
            <template v-slot:prepend><q-icon name="search" /></template>
          </q-input>
          <q-select
            v-model="protocolFilter"
            :options="['All', 'TCP', 'UDP', 'ICMP', 'IGMP', 'ICMPv6']"
            dense outlined label="Protocol"
            style="min-width: 130px;"
            @update:model-value="onFilterChange"
          />
          <q-btn-toggle
            v-model="severityFilter"
            no-caps rounded unelevated
            :toggle-color="severityFilter === 'all' ? 'blue' : severityFilter === 'warning' ? 'amber' : 'red'"
            :options="[
              { label: 'All', value: 'all' },
              { label: 'Warning', value: 'warning' },
              { label: 'Critical', value: 'critical' },
            ]"
            @update:model-value="onFilterChange"
          />
        </q-card-section>
      </q-card>

      <!-- Threats table -->
      <q-card class="page-card">
        <q-table
          :rows="threats"
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
          <template v-slot:body-cell-severity="props">
            <q-td :props="props">
              <q-badge v-if="props.row.probs" color="negative" label="Critical" />
              <q-badge v-else color="grey-6" label="Normal" />
            </q-td>
          </template>

          <template v-slot:body-cell-protocol="props">
            <q-td :props="props">
              <q-badge :color="protocolColor(props.value)" :label="props.value" />
            </q-td>
          </template>

          <template v-slot:body-cell-timestamp="props">
            <q-td :props="props">{{ fmtTime(props.value) }}</q-td>
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
              {{ error || 'No records found' }}
            </div>
          </template>
        </q-table>
      </q-card>
    </div>

    <!-- Detail dialog -->
    <q-dialog v-model="showDetail" maximized>
      <q-card style="max-width: 700px; width: 100%; margin: auto; height: fit-content; border-radius: 14px; align-self: center;">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6">Threat Detail</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup />
        </q-card-section>

        <q-card-section v-if="detailLoading" class="text-center q-pa-lg">
          <q-spinner size="32px" />
        </q-card-section>

        <q-card-section v-else-if="detailError" class="text-negative">
          Failed to load: {{ detailError }}
        </q-card-section>

        <q-card-section v-else-if="detail">
          <div class="row items-center q-gutter-sm q-mb-md">
            <q-badge v-if="detail.probs" color="negative" label="Critical" />
            <q-badge v-else color="grey-6" label="Normal" />
            <q-badge :color="protocolColor(detail.protocol)" :label="detail.protocol" />
          </div>

          <div class="q-gutter-sm q-mb-md">
            <div class="row q-gutter-sm">
              <div class="col">
                <div class="text-caption text-grey">Time</div>
                <div>{{ fmtTime(detail.timestamp) }}</div>
              </div>
              <div class="col">
                <div class="text-caption text-grey">Flags</div>
                <div class="text-caption">{{ fmtFlags(detail.flags, detail.protocol_num) }}</div>
              </div>
              <div class="col">
                <div class="text-caption text-grey">Bytes</div>
                <div>{{ detail.data_len }}</div>
              </div>
            </div>
            <div class="row q-gutter-sm q-mt-sm">
              <div class="col">
                <div class="text-caption text-grey">Source</div>
                <div class="text-mono">{{ detail.src_ip }}:{{ detail.src_port }}</div>
                <div class="text-caption text-grey">{{ detail.src_mac }}</div>
              </div>
              <div class="col">
                <div class="text-caption text-grey">Destination</div>
                <div class="text-mono">{{ detail.dest_ip }}:{{ detail.dest_port }}</div>
                <div class="text-caption text-grey">{{ detail.dest_mac }}</div>
              </div>
              <div class="col">
                <div class="text-caption text-grey">Host IP</div>
                <div class="text-mono">{{ detail.host_ip }}</div>
              </div>
            </div>
          </div>

          <q-separator class="q-mb-md" />

          <div class="text-subtitle2 q-mb-sm">Data</div>

          <div v-if="detail.parsed_dns">
            <q-list dense bordered separator class="rounded-borders">
              <q-item>
                <q-item-section>
                  <span class="text-caption text-grey">Type</span>
                  <span class="text-body2">{{ detail.parsed_dns.type }} (txid {{ detail.parsed_dns.transaction_id }})</span>
                </q-item-section>
              </q-item>
              <q-item v-for="(q, i) in detail.parsed_dns.questions" :key="i">
                <q-item-section>
                  <span class="text-caption text-grey">Query {{ i + 1 }}</span>
                  <span class="text-mono text-body2">{{ q.name }}</span>
                  <span class="text-caption text-grey">{{ q.type }} {{ q.class }}</span>
                </q-item-section>
              </q-item>
              <q-item v-if="detail.parsed_dns.answer_count > 0">
                <q-item-section>
                  <span class="text-caption text-grey">Answers</span>
                  <span class="text-body2">{{ detail.parsed_dns.answer_count }} record(s) in response</span>
                </q-item-section>
              </q-item>
            </q-list>
          </div>

          <div v-else-if="detail.data">
            <pre class="text-mono text-caption bg-grey-1 q-pa-sm rounded-borders" style="white-space: pre-wrap; word-break: break-all">{{ detail.data }}</pre>
          </div>

          <div v-else class="text-grey text-caption">No data</div>
        </q-card-section>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const threats = ref([])
const total = ref(0)
const loading = ref(false)
const error = ref('')
const searchQuery = ref('')
const protocolFilter = ref('All')
const severityFilter = ref('critical')

const stats = ref({ total: 0, today: 0, by_protocol: [], top_src_ips: [] })

const showDetail = ref(false)
const detail = ref(null)
const detailLoading = ref(false)
const detailError = ref('')

const displayStats = computed(() => {
  const topProto = stats.value.by_protocol[0]
  const topIp = stats.value.top_src_ips[0]
  return [
    { label: 'Total Threats', icon: 'shield', color: 'negative', value: stats.value.total.toLocaleString() },
    { label: 'Today', icon: 'today', color: 'warning', value: stats.value.today.toLocaleString() },
    { label: 'Top Protocol', icon: 'lan', color: 'info', value: topProto ? `${topProto.protocol} (${topProto.count})` : '—' },
    { label: 'Top Source IP', icon: 'location_on', color: 'primary', value: topIp ? topIp.ip : '—' },
  ]
})

async function onRowClick (_, row) {
  showDetail.value = true
  detail.value = null
  detailError.value = ''
  detailLoading.value = true
  try {
    const res = await fetch(`/api/logs/${row._id}`)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    detail.value = { ...data, probs: row.probs }
  } catch (e) {
    detailError.value = e.message
  } finally {
    detailLoading.value = false
  }
}

const pagination = ref({
  page: 1,
  rowsPerPage: 50,
  rowsNumber: 0,
  sortBy: null,
  descending: true,
})

const columns = [
  { name: 'severity', label: 'Severity', field: 'probs', align: 'center', sortable: false, style: 'width: 100px' },
  { name: 'timestamp', label: 'Time', field: 'timestamp', align: 'left', sortable: false, style: 'width: 160px' },
  { name: 'protocol', label: 'Proto', field: 'protocol', align: 'center', sortable: false, style: 'width: 80px' },
  { name: 'source', label: 'Source', field: 'src_ip', align: 'left' },
  { name: 'dest', label: 'Destination', field: 'dest_ip', align: 'left' },
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

let debounceTimer = null
function onFilterChange () {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    pagination.value.page = 1
    fetchThreats()
  }, 300)
}

function onTableRequest (props) {
  pagination.value.page = props.pagination.page
  pagination.value.rowsPerPage = props.pagination.rowsPerPage
  fetchThreats()
}

async function fetchStats () {
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
  error.value = ''
  threats.value = []
  total.value = 0
  const { page, rowsPerPage } = pagination.value
  const offset = (page - 1) * rowsPerPage
  const params = new URLSearchParams({
    search: searchQuery.value,
    protocol: protocolFilter.value,
    severity: severityFilter.value,
    size: rowsPerPage,
    offset,
  })
  try {
    const res = await fetch(`/api/threats?${params}`)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    threats.value = data.threats.map((r, i) => ({ ...r, idx: offset + i }))
    total.value = data.total
    pagination.value.rowsNumber = data.total
  } catch (e) {
    error.value = `Failed to load: ${e.message}`
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchStats()
  fetchThreats()
})
</script>

<style scoped>
.page-container { max-width: 1400px; margin: 0 auto; }
.page-card { border-radius: 14px; }
.text-mono { font-family: monospace; }
</style>
