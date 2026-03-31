<template>
  <q-page class="q-pa-lg">
    <div class="page-container">
      <div class="row items-center justify-between q-mb-md">
        <div class="text-h5 text-weight-medium">Logs</div>
        <div class="text-caption text-grey">{{ total.toLocaleString() }} records</div>
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
        </q-card-section>
      </q-card>

      <!-- Table -->
      <q-card class="page-card">
        <q-card-section class="row items-center justify-between q-pb-none">
          <div class="text-h6">Packets</div>
        </q-card-section>

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
              <span class="text-caption text-grey">{{ fmtFlags(props.row.flags, props.row.protocol_num) }}</span>
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
  </q-page>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const logs = ref([])
const total = ref(0)
const loading = ref(false)
const error = ref('')
const searchQuery = ref('')
const protocolFilter = ref('All')

const pagination = ref({
  page: 1,
  rowsPerPage: 50,
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
  if (protocolNum !== 6 || !flags) return '—'
  const active = TCP_FLAGS.filter(f => flags & f.bit).map(f => f.label)
  return active.length ? active.join(' ') : '—'
}

function fmtTime (ts) {
  if (!ts) return '—'
  return new Date(ts * 1000).toLocaleString()
}

function protocolColor (proto) {
  return { TCP: 'blue-7', UDP: 'teal-7', ICMP: 'orange-7', IGMP: 'purple-7', ICMPv6: 'cyan-7' }[proto] ?? 'grey-7'
}

let debounceTimer = null
function onFilterChange () {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    pagination.value.page = 1
    fetchLogs()
  }, 300)
}

function onTableRequest (props) {
  pagination.value.page = props.pagination.page
  pagination.value.rowsPerPage = props.pagination.rowsPerPage
  fetchLogs()
}

async function fetchLogs () {
  loading.value = true
  error.value = ''
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
    error.value = `Failed to load logs: ${e.message}`
  } finally {
    loading.value = false
  }
}

onMounted(fetchLogs)
</script>

<style scoped>
.page-container { max-width: 1400px; margin: 0 auto; }
.page-card { border-radius: 14px; }
</style>
