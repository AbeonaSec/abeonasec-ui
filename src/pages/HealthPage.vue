<template>
  <q-page class="q-pa-lg">
    <div class="page-container">
      <div class="row items-center justify-between q-mb-md">
        <div class="text-h5 text-weight-medium">System Health</div>
        <q-btn flat dense icon="refresh" label="Refresh" @click="manualRefresh" :loading="manualLoading" />
      </div>

      <!-- Error banner -->
      <q-banner v-if="error" class="bg-negative text-white q-mb-md" rounded>
        <template v-slot:avatar><q-icon name="error" /></template>
        {{ error }}
      </q-banner>

      <!-- Resource gauges -->
      <div class="row q-col-gutter-md q-mb-lg">
        <div class="col-6 col-md-3" v-for="metric in gaugeMetrics" :key="metric.label">
          <q-card class="page-card">
            <q-card-section class="text-center">
              <q-circular-progress
                :value="metric.percent"
                size="80px"
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
          </q-card>
        </div>
      </div>

      <!-- Network -->
      <q-card class="page-card q-mb-md">
        <q-card-section class="row items-center justify-between">
          <div class="text-h6">Network I/O</div>
        </q-card-section>
        <q-separator />
        <q-card-section v-if="data">
          <div class="row q-col-gutter-md">
            <div class="col-6">
              <div class="text-caption text-grey">Sent</div>
              <div class="text-body1">{{ data.network.sent }}</div>
            </div>
            <div class="col-6">
              <div class="text-caption text-grey">Received</div>
              <div class="text-body1">{{ data.network.recv }}</div>
            </div>
          </div>
        </q-card-section>
        <q-card-section v-else class="text-body2 text-grey">
          {{ loading ? 'Loading…' : 'No data' }}
        </q-card-section>
      </q-card>

      <!-- GPU -->
      <q-card class="page-card" v-if="data && data.gpu">
        <q-card-section class="row items-center justify-between">
          <div class="text-h6">GPU</div>
        </q-card-section>
        <q-separator />
        <q-card-section v-for="(gpu, i) in data.gpu" :key="i">
          <div class="text-subtitle2 q-mb-xs">{{ gpu.name }}</div>
          <div class="row q-col-gutter-md">
            <div class="col-6 col-md-3">
              <div class="text-caption text-grey">Utilization</div>
              <q-linear-progress
                :value="gpu.utilization_percent / 100"
                :color="gaugeColor(gpu.utilization_percent)"
                class="q-mt-xs"
                rounded
                size="8px"
              />
              <div class="text-caption q-mt-xs">{{ gpu.utilization_percent }}%</div>
            </div>
            <div class="col-6 col-md-3">
              <div class="text-caption text-grey">VRAM</div>
              <q-linear-progress
                :value="gpu.memory_percent / 100"
                :color="gaugeColor(gpu.memory_percent)"
                class="q-mt-xs"
                rounded
                size="8px"
              />
              <div class="text-caption q-mt-xs">{{ gpu.memory_used_mb }} / {{ gpu.memory_total_mb }} MB ({{ gpu.memory_percent }}%)</div>
            </div>
          </div>
        </q-card-section>
      </q-card>
    </div>
  </q-page>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const data = ref(null)
const loading = ref(false)
const manualLoading = ref(false)
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

async function manualRefresh () {
  manualLoading.value = true
  await fetchHealth()
  manualLoading.value = false
}

const gaugeMetrics = computed(() => {
  if (!data.value) return [
    { label: 'CPU', percent: 0, detail: '' },
    { label: 'Memory', percent: 0, detail: '' },
    { label: 'Swap', percent: 0, detail: '' },
    { label: 'Disk', percent: 0, detail: '' },
  ]
  const d = data.value
  return [
    { label: 'CPU', percent: d.cpu.percent, detail: `${d.cpu.percent}%` },
    { label: 'Memory', percent: d.memory.percent, detail: `${d.memory.used_gb} / ${d.memory.total_gb} GB` },
    { label: 'Swap', percent: d.swap.percent, detail: `${d.swap.used_gb} / ${d.swap.total_gb} GB` },
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
  interval = setInterval(fetchHealth, 5000)
})

onUnmounted(() => clearInterval(interval))
</script>

<style scoped>
.page-container { max-width: 1400px; margin: 0 auto; }
.page-card { border-radius: 14px; }
</style>
