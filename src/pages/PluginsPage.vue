<template>
  <q-page class="q-pa-lg">
    <div class="page-container">
      <div class="row items-center justify-between q-mb-md">
        <div class="text-h5 text-weight-medium">Plugins</div>
        <q-btn flat dense icon="refresh" label="Refresh" @click="fetchPlugins(true)" :loading="refreshLoading" />
      </div>

      <!-- Error banner -->
      <q-banner v-if="error" class="bg-negative text-white q-mb-md" rounded>
        <template v-slot:avatar><q-icon name="error" /></template>
        {{ error }}
      </q-banner>

      <!-- Filter chips -->
      <div class="row q-gutter-sm q-mb-lg">
        <q-chip
          clickable
          :outline="pluginFilter !== 'all'"
          :color="pluginFilter === 'all' ? 'primary' : undefined"
          :text-color="pluginFilter === 'all' ? 'white' : undefined"
          @click="pluginFilter = 'all'"
        >All</q-chip>
        <q-chip
          clickable
          :outline="pluginFilter !== 'running'"
          @click="pluginFilter = 'running'"
        >Active</q-chip>
        <q-chip
          clickable
          :outline="pluginFilter !== 'stopped'"
          @click="pluginFilter = 'stopped'"
        >Stopped</q-chip>
        <q-chip
          clickable
          :outline="pluginFilter !== 'not_installed'"
          @click="pluginFilter = 'not_installed'"
        >Available</q-chip>
      </div>

      <!-- Plugin grid -->
      <div v-if="loading" class="row q-col-gutter-md">
        <div class="col-12 col-md-6" v-for="n in 2" :key="n">
          <q-card class="page-card">
            <q-card-section>
              <q-skeleton type="text" width="60%" />
              <q-skeleton type="text" width="90%" class="q-mt-sm" />
            </q-card-section>
          </q-card>
        </div>
      </div>

      <div v-else-if="filteredPlugins.length === 0" class="text-body2 text-grey q-mt-md">
        No plugins match this filter.
      </div>

      <div v-else class="row q-col-gutter-md">
        <div class="col-12 col-md-6" v-for="plugin in filteredPlugins" :key="plugin.id">
          <q-card class="page-card">
            <q-card-section class="row items-start justify-between no-wrap">
              <div>
                <div class="row items-center q-gutter-sm">
                  <span class="text-h6">{{ plugin.name }}</span>
                  <q-badge
                    :color="statusColor(plugin.status)"
                    :label="statusLabel(plugin.status)"
                  />
                </div>
                <div class="text-body2 text-grey q-mt-xs">{{ plugin.description }}</div>
              </div>
              <q-icon
                :name="statusIcon(plugin.status)"
                :color="statusColor(plugin.status)"
                size="28px"
                class="q-ml-md"
              />
            </q-card-section>

            <q-separator />

            <q-card-actions align="right">
              <!-- Not installed -->
              <q-btn
                v-if="plugin.status === 'not_installed'"
                color="primary"
                label="Install"
                icon="download"
                unelevated
                @click="openInstallDialog(plugin)"
              />

              <!-- Installed & stopped -->
              <template v-else-if="plugin.status === 'stopped'">
                <q-btn
                  color="positive"
                  label="Enable"
                  icon="play_arrow"
                  unelevated
                  :loading="actionLoading[plugin.id]"
                  @click="enablePlugin(plugin)"
                />
              </template>

              <!-- Running -->
              <template v-else-if="plugin.status === 'running'">
                <q-btn
                  color="warning"
                  label="Disable"
                  icon="stop"
                  unelevated
                  :loading="actionLoading[plugin.id]"
                  @click="disablePlugin(plugin)"
                />
              </template>
            </q-card-actions>
          </q-card>
        </div>
      </div>
    </div>

    <!-- Install dialog -->
    <q-dialog v-model="installDialog" persistent>
      <q-card style="min-width: 520px; max-width: 600px">
        <q-card-section class="row items-center q-pb-none">
          <div class="text-h6">Install {{ selectedPlugin?.name }}</div>
          <q-space />
          <q-btn icon="close" flat round dense v-close-popup :disable="installing" />
        </q-card-section>

        <q-card-section>
          <!-- Legal disclaimer -->
          <q-banner class="bg-warning text-dark q-mb-md" rounded>
            <template v-slot:avatar>
              <q-icon name="gavel" color="dark" />
            </template>
            <div class="text-subtitle2 q-mb-xs">Legal Disclaimer</div>
            <div class="text-caption" style="line-height: 1.5">
              This plugin sniffs packets from a network interface you specify.
              Do not run this on any interface connected to a network you do not
              own or have explicit legal permission to monitor.
              The developers of AbeonaSec take no responsibility for misuse.
            </div>
          </q-banner>

          <q-checkbox
            v-model="installForm.accepted"
            label="I understand and accept these terms"
            class="q-mb-md"
          />

          <!-- Interface selection (only shown once disclaimer is accepted) -->
          <transition name="fade">
            <div v-if="installForm.accepted">
              <div class="text-caption text-grey q-mb-xs">
                Select the network interface to monitor. Defaults to the system default.
              </div>
              <q-select
                v-model="installForm.interface"
                :options="interfaceOptions"
                option-value="name"
                option-label="label"
                emit-value
                map-options
                label="Network Interface"
                outlined
                dense
                :loading="interfacesLoading"
              />
            </div>
          </transition>

          <!-- Install output log -->
          <q-expansion-item
            v-if="installOutput"
            icon="terminal"
            label="Install log"
            class="q-mt-md"
            dense
          >
            <q-card flat>
              <q-card-section>
                <pre class="install-log">{{ installOutput }}</pre>
              </q-card-section>
            </q-card>
          </q-expansion-item>

          <q-banner v-if="installError" class="bg-negative text-white q-mt-md" rounded>
            {{ installError }}
          </q-banner>
        </q-card-section>

        <q-card-actions align="right" class="q-pt-none">
          <q-btn flat label="Cancel" v-close-popup :disable="installing" />
          <q-btn
            color="primary"
            label="Install"
            icon="download"
            unelevated
            :disable="!installForm.accepted"
            :loading="installing"
            @click="confirmInstall"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const plugins = ref([])
const loading = ref(false)
const refreshLoading = ref(false)
const error = ref(null)
const pluginFilter = ref('all')
const actionLoading = ref({})

// Install dialog state
const installDialog = ref(false)
const selectedPlugin = ref(null)
const installForm = ref({ accepted: false, interface: '' })
const interfaces = ref([])
const interfacesLoading = ref(false)
const installing = ref(false)
const installOutput = ref('')
const installError = ref(null)

const filteredPlugins = computed(() => {
  if (pluginFilter.value === 'all') return plugins.value
  return plugins.value.filter(p => p.status === pluginFilter.value)
})

const interfaceOptions = computed(() =>
  interfaces.value.map(iface => ({
    name: iface.name,
    label: iface.is_default
      ? `${iface.name} (default)${iface.address ? ' — ' + iface.address : ''}`
      : `${iface.name}${iface.address ? ' — ' + iface.address : ''}`,
  }))
)

async function fetchPlugins (manual = false) {
  if (manual) refreshLoading.value = true
  else loading.value = true
  error.value = null
  try {
    const res = await fetch('/api/plugins')
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    plugins.value = data.plugins
  } catch (e) {
    error.value = `Failed to load plugins: ${e.message}`
  } finally {
    loading.value = false
    refreshLoading.value = false
  }
}

async function fetchInterfaces () {
  interfacesLoading.value = true
  try {
    const res = await fetch('/api/plugins/interfaces')
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    interfaces.value = data.interfaces
    // Pre-select the default interface
    const def = data.interfaces.find(i => i.is_default)
    if (def) installForm.value.interface = def.name
  } catch {
    // non-critical
  } finally {
    interfacesLoading.value = false
  }
}

function openInstallDialog (plugin) {
  selectedPlugin.value = plugin
  installForm.value = { accepted: false, interface: '' }
  installOutput.value = ''
  installError.value = null
  installDialog.value = true
  fetchInterfaces()
}

async function confirmInstall () {
  installing.value = true
  installOutput.value = ''
  installError.value = null
  try {
    const res = await fetch(`/api/plugins/${selectedPlugin.value.id}/install`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accepted: installForm.value.accepted,
        interface: installForm.value.interface,
      }),
    })
    const data = await res.json()
    if (!res.ok) {
      installError.value = data.detail || `HTTP ${res.status}`
    } else {
      installOutput.value = data.output || ''
      installDialog.value = false
      await fetchPlugins()
    }
  } catch (e) {
    installError.value = `Request failed: ${e.message}`
  } finally {
    installing.value = false
  }
}

async function enablePlugin (plugin) {
  actionLoading.value[plugin.id] = true
  try {
    const res = await fetch(`/api/plugins/${plugin.id}/enable`, { method: 'POST' })
    if (!res.ok) {
      const d = await res.json()
      error.value = d.detail || `Failed to enable plugin`
    } else {
      await fetchPlugins()
    }
  } catch (e) {
    error.value = e.message
  } finally {
    actionLoading.value[plugin.id] = false
  }
}

async function disablePlugin (plugin) {
  actionLoading.value[plugin.id] = true
  try {
    const res = await fetch(`/api/plugins/${plugin.id}/disable`, { method: 'POST' })
    if (!res.ok) {
      const d = await res.json()
      error.value = d.detail || `Failed to disable plugin`
    } else {
      await fetchPlugins()
    }
  } catch (e) {
    error.value = e.message
  } finally {
    actionLoading.value[plugin.id] = false
  }
}

function statusColor (status) {
  if (status === 'running') return 'positive'
  if (status === 'stopped') return 'warning'
  return 'grey'
}

function statusLabel (status) {
  if (status === 'running') return 'Running'
  if (status === 'stopped') return 'Stopped'
  return 'Not Installed'
}

function statusIcon (status) {
  if (status === 'running') return 'check_circle'
  if (status === 'stopped') return 'pause_circle'
  return 'extension_off'
}

onMounted(() => fetchPlugins())
</script>

<style scoped>
.page-container { max-width: 1400px; margin: 0 auto; }
.page-card { border-radius: 14px; }
.install-log {
  font-size: 11px;
  font-family: monospace;
  white-space: pre-wrap;
  word-break: break-all;
  background: #1e1e1e;
  color: #d4d4d4;
  padding: 12px;
  border-radius: 6px;
  max-height: 200px;
  overflow-y: auto;
}
.fade-enter-active, .fade-leave-active { transition: opacity 0.2s; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
